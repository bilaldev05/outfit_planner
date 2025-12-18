import asyncio
import hashlib
import traceback
from typing import Optional, List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from models import Product
from cache import get_cached, set_cache

from scrapers.outfitters import scrape_outfitters
from scrapers.breakout import scrape_breakout
from scrapers.edenrobe import scrape_edenrobe
from scrapers.nishat import scrape_nishat
from scrapers.levis import scrape_levis
from scrapers.uno import scrape_uno
from scrapers.royaltag import scrape_royaltag
from scrapers.gulahmad import scrape_gulahmad

app = FastAPI(title="Product Scraper Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SearchRequest(BaseModel):
    category: str
    color: Optional[str] = None
    max_results: int = 36

def make_query_key(category: str, color: Optional[str]) -> str:
    s = f"{category}|{color or ''}"
    return hashlib.sha1(s.encode()).hexdigest()


@app.post("/search_products")
async def search_products(req: SearchRequest):
    try:
        query = " ".join(filter(None, [req.color, req.category]))
        cache_key = make_query_key(req.category, req.color)

        
        cached = get_cached(cache_key)
        if cached:
            return {"source": "cache", "products": cached}

        scrapers = [
            scrape_outfitters,
            scrape_breakout,
            scrape_edenrobe,
            scrape_nishat,
            scrape_levis,
            scrape_uno,
            scrape_royaltag,
            scrape_gulahmad,
        ]

        max_per_brand = max(4, req.max_results // len(scrapers))

        
        tasks = [scraper(query, max_per_brand) for scraper in scrapers]
        results_list = await asyncio.gather(*tasks, return_exceptions=True)

        results: List[Product] = []
        for idx, res in enumerate(results_list):
            if isinstance(res, Exception):
                print(f"{scrapers[idx].__name__} scraper failed:", res)
                continue
            for item in res:
                if isinstance(item, dict):
                    results.append(Product(**item))
                else:
                    if not item.image:
                        item.image = ""
                    results.append(item)

        # Deduplicate
        seen = set()
        dedup = []
        for p in results:
            key = (p.link or "") + (p.title or "")
            if key not in seen:
                seen.add(key)
                dedup.append(p)

        dedup = dedup[:req.max_results]
        serialized = [p.model_dump() for p in dedup]

        set_cache(cache_key, serialized, ttl_seconds=6 * 3600)
        return {"source": "live", "products": serialized}

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))




    
# py -m uvicorn app:app --reload --host 0.0.0.0 --port 8000