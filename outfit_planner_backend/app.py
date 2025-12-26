import asyncio
import hashlib
import traceback
from typing import Optional, List
from pydantic import BaseModel
from typing import List
from models import Product 

from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from itertools import product as iter_product

from motor.motor_asyncio import AsyncIOMotorClient
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


MONGO_URI = "mongodb://localhost:27017"  
client = AsyncIOMotorClient(MONGO_URI)
db = client["outfit_planner"]
cart_collection = db["cart_items"]
outfit_collection = db["built_outfits"]


app = FastAPI(title="Product Scraper Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------- Models -----------------
class OutfitRequest(BaseModel):
    userId: str  
    items: List[Product]
class SearchRequest(BaseModel):
    category: str
    color: Optional[str] = None
    max_results: int = 36

# ----------------- Utility Functions -----------------
def make_query_key(category: str, color: Optional[str]) -> str:
    s = f"{category}|{color or ''}"
    return hashlib.sha1(s.encode()).hexdigest()

def auto_assign_category(p: Product) -> Product:
    """Assign category if missing based on title"""
    cat = (p.category or "").strip().lower()
    title = (p.title or "").lower()

    if not cat:
        if any(x in title for x in ["shirt", "tshirt", "top"]):
            cat = "shirt"
        elif any(x in title for x in ["pant", "jeans", "trouser"]):
            cat = "pant"
        elif any(x in title for x in ["shoe", "sneaker", "boot"]):
            cat = "shoe"
        else:
            cat = "shirt"  # fallback

    p.category = cat
    return p

# ----------------- API Endpoints -----------------

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

# ----------------- Cart Endpoints -----------------

@app.post("/cart/add")
async def add_to_cart(user_id: str = Body(...), product: Product = Body(...)):
    doc = {"user_id": user_id, "product": product.model_dump()}
    await cart_collection.insert_one(doc)
    return {"success": True, "message": "Item added to cart"}

@app.get("/cart/{user_id}")
async def get_cart(user_id: str):
    items = await cart_collection.find({"user_id": user_id}).to_list(length=100)
    return {"items": items}

@app.delete("/cart/{user_id}/{product_link}")
async def remove_from_cart(user_id: str, product_link: str):
    result = await cart_collection.delete_one({"user_id": user_id, "product.link": product_link})
    return {"deleted_count": result.deleted_count}

# ----------------- Outfit Endpoints -----------------

@app.post("/build_outfit")
async def build_outfit(req: OutfitRequest):
    user_id = req.userId  # <-- matches the key in the Pydantic model
    items = [auto_assign_category(p) for p in req.items]

    tops = [p for p in items if p.category == "shirt"]
    bottoms = [p for p in items if p.category == "pant"]
    shoes = [p for p in items if p.category == "shoe"]

    if not tops or not bottoms:
        return {"success": False, "message": "Not enough items to build outfit"}

    outfit_combinations = []

    for t, b in iter_product(tops, bottoms):
        combo = {
            "top": t.model_dump(),
            "bottom": b.model_dump(),
            "shoes": shoes[0].model_dump() if shoes else None
        }
        outfit_combinations.append(combo)
        # Save to MongoDB
        await outfit_collection.insert_one({"user_id": user_id, "outfit": combo})

    return {
        "success": True,
        "outfits": outfit_combinations
    }

    

@app.get("/outfit/{user_id}")
async def get_outfits(user_id: str):
    outfits = await outfit_collection.find({"user_id": user_id}).to_list(length=100)
    return {"outfits": outfits}


    
# py -m uvicorn app:app --reload --host 0.0.0.0 --port 8000