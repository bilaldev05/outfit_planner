from fastapi import APIRouter, Form, File, UploadFile, HTTPException
from typing import List
import os, uuid, shutil
from app.database import db
from main import UPLOAD_DIR, WardrobeItem

router = APIRouter(prefix="/wardrobe", tags=["Wardrobe"])
wardrobe_collection = db.wardrobe


# Helper to serialize MongoDB document
def serialize_item(item) -> dict:
    """Convert MongoDB _id to string for JSON."""
    item["_id"] = str(item["_id"])
    return item


# ✅ Get all wardrobe items
@router.get("/", response_model=List[WardrobeItem])
async def get_wardrobe_items():
    """
    Return all wardrobe items as a list of JSON objects.
    """
    try:
        items = await wardrobe_collection.find().to_list(length=100)
        # Ensure a list of dictionaries, not string
        return [serialize_item(item) for item in items]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ Add a wardrobe item
@router.post("/add-item", response_model=WardrobeItem)
async def add_wardrobe_item(
    name: str = Form(...),
    category: str = Form(...),
    color: str = Form(...),
    season: str = Form(None),
    image: UploadFile = File(None),
):
    """
    Add a new wardrobe item.
    Returns the added item as JSON.
    """
    try:
        item_id = str(uuid.uuid4())
        image_path = None

        if image:
            ext = os.path.splitext(image.filename)[1]
            image_filename = f"{item_id}{ext}"
            saved_path = os.path.join(UPLOAD_DIR, image_filename)
            with open(saved_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            image_path = f"/uploads/{image_filename}"

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

        return new_item

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ Delete wardrobe item by ID
@router.delete("/delete/{item_id}")
async def delete_wardrobe_item(item_id: str):
    try:
        result = await wardrobe_collection.delete_one({"id": item_id})
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Item not found")
        return {"message": "Item deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ Clear all wardrobe items
@router.delete("/clear")
async def clear_wardrobe():
    try:
        await wardrobe_collection.delete_many({})
        return {"message": "All wardrobe items cleared"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
