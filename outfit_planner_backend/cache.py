# backend/cache.py
from pymongo import MongoClient, ASCENDING
import datetime
import os

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
client = MongoClient(MONGO_URI)
db = client["scrape_cache"]
cache_col = db["product_cache"]

# Ensure TTL index on 'expires_at' for automatic eviction
cache_col.create_index([("query", ASCENDING), ("source", ASCENDING)])
if "expires_at_1h" not in cache_col.index_information():
    cache_col.create_index("expires_at", expireAfterSeconds=0)

def get_cached(query_key: str):
    doc = cache_col.find_one({"query": query_key})
    return doc["results"] if doc else None

def set_cache(query_key: str, results: list, ttl_seconds: int = 86400):
    expires_at = datetime.datetime.utcnow() + datetime.timedelta(seconds=ttl_seconds)
    cache_col.update_one(
        {"query": query_key},
        {"$set": {"results": results, "expires_at": expires_at}},
        upsert=True
    )
