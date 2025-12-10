from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
import hashlib

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
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI(title="Product Scraper Service")

origins = [
    "http://localhost",
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "*"  # allow all origins (for development only)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,      # or ["*"] for all
    allow_credentials=True,
    allow_methods=["*"],        # allow GET, POST, etc.
    allow_headers=["*"],        # allow custom headers
)
# ------------------------
# Pydantic v2 Models
# ------------------------
class SearchRequest(BaseModel):
    category: str = Field(...)
    color: Optional[str] = None
    location: Optional[str] = None
    max_results: Optional[int] = 36

    model_config = {
        "extra": "allow"
    }


# ------------------------
# Helpers
# ------------------------
def make_query_key(category: str, color: Optional[str], location: Optional[str]) -> str:
    s = f"{category}|{color or ''}|{location or ''}"
    return hashlib.sha1(s.encode()).hexdigest()


# ------------------------
# Routes
# ------------------------
@app.post("/search_products")
async def search_products(req: SearchRequest):
    try:
        # Compose query text
        qparts = [req.color, req.category]
        query_text = " ".join([p for p in qparts if p]).strip()

        # Check cache first
        cache_key = make_query_key(req.category, req.color, req.location)
        cached = get_cached(cache_key)
        if cached:
            return {
                "source": "cache",
                "products": cached  # cached should already be serialized
            }

        # Determine max per brand
        max_per_brand = max(6, (req.max_results // 8) + 1)

        # Run scrapers
        scrapers = [
            scrape_outfitters, scrape_breakout, scrape_edenrobe, scrape_nishat,
            scrape_levis, scrape_uno, scrape_royaltag, scrape_gulahmad
        ]
        results: List[Product] = []
        for scraper in scrapers:
            try:
                results.extend(scraper(query_text, max_items=max_per_brand))
            except Exception:
                continue  # skip failing scraper

        # Deduplicate by link + title
        seen = set()
        dedup: List[Product] = []
        for p in results:
            key = (p.link or "") + "|" + (p.title or "")
            if key in seen:
                continue
            seen.add(key)
            dedup.append(p)

        # Sort: prioritize image + price
        dedup.sort(key=lambda x: (1 if x.image else 0, 1 if x.price else 0), reverse=True)
        dedup = dedup[: req.max_results]

        # Cache results (store as list of dicts)
        set_cache(cache_key, [p.model_dump() for p in dedup], ttl_seconds=24*3600)

        # Return serialized products
        return {
            "source": "live",
            "products": [p.model_dump() for p in dedup]
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


    
# py -m uvicorn app:app --reload --host 0.0.0.0 --port 8000