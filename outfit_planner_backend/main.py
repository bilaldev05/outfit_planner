from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pymongo import MongoClient
from typing import List, Optional
from pydantic import BaseModel
import uuid
import os
import shutil
from bson import ObjectId


client = MongoClient("mongodb://localhost:27017/")
db = client["fashion_ai"]
wardrobe_collection = db["wardrobe_items"]

# ========== FASTAPI SETUP ==========
app = FastAPI(title="Fashion Wardrobe API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow frontend requests
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ========== UPLOAD DIRECTORY ==========
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Serve static files
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
# ========== MODELS ==========
class WardrobeItem(BaseModel):
    id: Optional[str]
    name: str
    category: str
    color: str
    season: Optional[str] = None
    image: Optional[str] = None  # URL or local path


# ========== HELPERS ==========
def serialize_item(item):
    """Convert MongoDB ObjectId to string and remove _id."""
    if "_id" in item:
        item["_id"] = str(item["_id"])
    return item


# ========== ROUTES ==========

@app.get("/")
async def root():
    return {"message": "Fashion Wardrobe API running successfully!"}


# 1️⃣ Get all wardrobe items
@app.get("/wardrobe/", response_model=List[WardrobeItem])
async def get_wardrobe_items():
    try:
        items = list(wardrobe_collection.find())
        for item in items:
            item = serialize_item(item)
        return items
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# 2️⃣ Add a new item
@app.post("/wardrobe/add-item")
async def add_wardrobe_item(
    name: str = Form(...),
    category: str = Form(...),
    color: str = Form(...),
    season: str = Form(None),
    image: UploadFile = File(None),
):
    try:
        item_id = str(uuid.uuid4())
        image_path = None

        if image:
            ext = os.path.splitext(image.filename)[1]
            image_filename = f"{item_id}{ext}"
            saved_path = os.path.join(UPLOAD_DIR, image_filename)
            with open(saved_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            image_path = f"/uploads/{image_filename}"  # ✅ this is important

        new_item = {
            "id": item_id,
            "name": name,
            "category": category,
            "color": color,
            "season": season,
            "image": image_path,
        }

        result = await wardrobe_collection.insert_one(new_item)
        new_item["_id"] = str(result.inserted_id)

        return {"message": "Item added successfully", "item": new_item}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 3️⃣ Delete an item
@app.delete("/wardrobe/delete/{item_id}")
async def delete_wardrobe_item(item_id: str):
    result = wardrobe_collection.delete_one({"id": item_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Item not found")
    return {"message": "Item deleted successfully"}


# 4️⃣ Clear all wardrobe items
@app.delete("/wardrobe/clear")
async def clear_wardrobe():
    wardrobe_collection.delete_many({})
    return {"message": "All wardrobe items deleted successfully"}


# 5️⃣ Get items by category
@app.get("/wardrobe/category/{category}")
async def get_by_category(category: str):
    try:
        items = list(wardrobe_collection.find({"category": category}))
        for item in items:
            item = serialize_item(item)
        return items
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

#python -m uvicorn main:app --reload