# main.py
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from pymongo import MongoClient
from typing import List, Optional, Dict, Any
import uuid
import os, shutil
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# ---------- CONFIG ----------
MONGODB_URI = "mongodb://localhost:27017/"
DB_NAME = "fashion_ai"
WARDROBE_COLLECTION = "wardrobe_items"
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ---------- DB ----------
client = MongoClient(MONGODB_URI)
db = client[DB_NAME]
wardrobe_collection = db[WARDROBE_COLLECTION]

# ---------- MODEL ----------
# You must install: sentence-transformers, scikit-learn, pymongo, fastapi, uvicorn
# Model: all-MiniLM-L6-v2 (small & free)
EMBED_MODEL_NAME = "all-MiniLM-L6-v2"
model = SentenceTransformer(EMBED_MODEL_NAME)

def to_embedding(text: str) -> List[float]:
    vec = model.encode(text, convert_to_numpy=True)
    return vec.tolist()

def cos_sim(a: np.ndarray, b: np.ndarray) -> float:
    if a.ndim == 1:
        a = a.reshape(1, -1)
    if b.ndim == 1:
        b = b.reshape(1, -1)
    return float(cosine_similarity(a, b)[0][0])

# ---------- FASTAPI ----------
app = FastAPI(title="Fashion Wardrobe AI")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ---------- MODELS ----------
class WardrobeItemIn(BaseModel):
    name: str
    category: str
    color: Optional[str] = ""
    season: Optional[str] = ""
    tags: Optional[List[str]] = []

class WardrobeItemOut(WardrobeItemIn):
    id: str
    image: Optional[str] = None
    embedding: Optional[List[float]] = None

# ---------- HELPERS ----------
def serialize(item: Dict[str, Any]) -> Dict[str, Any]:
    item = item.copy()
    item["id"] = item.get("id") or str(item.get("_id"))
    if "_id" in item:
        item["_id"] = str(item["_id"])
    return item

def item_description_text(item: Dict[str, Any]) -> str:
    # Compose a short descriptive text for embedding
    pieces = [
        item.get("name", ""),
        item.get("category", ""),
        item.get("color", ""),
        item.get("season", ""),
    ]
    pieces += item.get("tags", []) if item.get("tags") else []
    return " ".join([p for p in pieces if p])

# basic color parser to normalized css-like name (very small heuristic)
COLOR_GROUPS = {
    "black": ["black", "charcoal"],
    "white": ["white", "ivory", "cream"],
    "red": ["red", "maroon", "burgundy"],
    "blue": ["blue", "navy", "denim", "teal"],
    "green": ["green", "olive"],
    "yellow": ["yellow", "mustard"],
    "pink": ["pink", "rose"],
    "brown": ["brown", "tan", "beige"],
    "gray": ["gray", "grey", "silver"],
    "orange": ["orange"],
    "purple": ["purple", "violet"],
}

def normalize_color(name: str) -> str:
    if not name:
        return ""
    n = name.lower()
    for key, tokens in COLOR_GROUPS.items():
        for t in tokens:
            if t in n:
                return key
    return n.split()[0]  # fallback

def color_compat_score(c1: str, c2: str) -> float:
    # Simple rules: same color -> +0.2, complementary-ish families -> +0.05, else 0
    if not c1 or not c2:
        return 0.0
    if c1 == c2:
        return 0.2
    # very simple complementary pairs
    complementary = [
        ("blue", "white"),
        ("black", "white"),
        ("brown", "beige"),
    ]
    for a, b in complementary:
        if (c1 == a and c2 == b) or (c1 == b and c2 == a):
            return 0.1
    return 0.0

# ---------- ROUTES ----------
@app.get("/")
async def root():
    return {"message": "Fashion Wardrobe AI running"}

@app.get("/wardrobe/", response_model=List[WardrobeItemOut])
async def get_wardrobe():
    items = list(wardrobe_collection.find({}))
    return [serialize(i) for i in items]

@app.post("/wardrobe/add-item")
async def add_item(
    name: str = Form(...),
    category: str = Form(...),
    color: str = Form(""),
    season: str = Form(""),
    tags: Optional[str] = Form(None),  # comma-separated tags optional
    image: UploadFile = File(None),
):
    try:
        item_id = str(uuid.uuid4())
        image_path = None
        if image:
            ext = os.path.splitext(image.filename)[1]
            filename = f"{item_id}{ext}"
            out_path = os.path.join(UPLOAD_DIR, filename)
            with open(out_path, "wb") as f:
                shutil.copyfileobj(image.file, f)
            image_path = f"/uploads/{filename}"

        tags_list = []
        if tags:
            tags_list = [t.strip() for t in tags.split(",") if t.strip()]

        item = {
            "id": item_id,
            "name": name,
            "category": category.lower(),
            "color": color,
            "season": season.lower(),
            "tags": tags_list,
            "image": image_path,
        }
        # create embedding
        desc = item_description_text(item)
        item["embedding"] = to_embedding(desc)

        res = wardrobe_collection.insert_one(item)
        item["_id"] = str(res.inserted_id)
        return {"message": "Item added", "item": serialize(item)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/wardrobe/regen-embeddings")
async def regen_embeddings(limit: int = 1000):
    """Recompute embeddings for existing items (useful after schema changes)."""
    items = list(wardrobe_collection.find({}))
    updated = 0
    for it in items[:limit]:
        desc = item_description_text(it)
        emb = to_embedding(desc)
        wardrobe_collection.update_one({"_id": it["_id"]}, {"$set": {"embedding": emb}})
        updated += 1
    return {"updated": updated}

@app.get("/recommend")
async def recommend_outfit(
    event: str = Query(..., description="Event description (e.g., wedding, office party)"),
    top_k: int = Query(5),
    prefer_color: Optional[str] = Query(None),
    season: Optional[str] = Query(None),
):
    """
    Returns recommended outfit given an event string.
    Strategy:
      1. Convert event -> embedding
      2. For each category (top, bottom, shoes, accessory), compute similarity to event
      3. Apply color + season boosting rules and combine score
      4. Pick best-scored item per category
    """
    try:
        event_emb = np.array(to_embedding(event))
        items = list(wardrobe_collection.find({}))
        # categorize
        categories = ["top", "bottom", "shoes", "accessory", "outerwear"]
        cat_items = {c: [] for c in categories}
        for it in items:
            cat = it.get("category", "other").lower()
            # normalize category mapping: common synonyms to our categories
            if any(k in cat for k in ["shirt", "blouse", "tee", "top"]):
                cat_items["top"].append(it)
            elif any(k in cat for k in ["pant", "jean", "trouser", "short"]):
                cat_items["bottom"].append(it)
            elif any(k in cat for k in ["shoe", "sneaker", "boot", "loafer"]):
                cat_items["shoes"].append(it)
            elif any(k in cat for k in ["coat", "jacket", "sweater", "hoodie"]):
                cat_items["outerwear"].append(it)
            elif any(k in cat for k in ["accessory","hat","scarf","belt"]):
                cat_items["accessory"].append(it)
            else:
                # fallback: if uncategorized, push to accessory or top as fallback
                cat_items["accessory"].append(it)

        # function to score one item
        def score_item(it):
            score = 0.0
            # embedding similarity
            emb = np.array(it.get("embedding") or to_embedding(item_description_text(it)))
            sim = cos_sim(event_emb, emb)
            score += sim  # base
            # season boost
            if season and season.lower() and it.get("season"):
                if season.lower() == it.get("season", "").lower():
                    score += 0.12
            # color preference
            if prefer_color:
                c_pref = normalize_color(prefer_color)
                c_item = normalize_color(it.get("color",""))
                if c_pref and c_item:
                    if c_pref == c_item:
                        score += 0.12
            # color compatibility with event keywords (very weak heuristic)
            # return final score
            return score

        # pick best for each category
        outfit = {}
        for cat, items_list in cat_items.items():
            if not items_list:
                outfit[cat] = None
                continue
            scored = [(score_item(it), it) for it in items_list]
            scored.sort(key=lambda x: x[0], reverse=True)
            top_choice = scored[0][1]
            outfit[cat] = serialize(top_choice)

        # a simple post-processing: if top or bottom missing, leave as None
        return {"event": event, "outfit": outfit}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# py -m uvicorn main:app --reload