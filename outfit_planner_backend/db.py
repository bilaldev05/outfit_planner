from motor.motor_asyncio import AsyncIOMotorClient
import os

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
client = AsyncIOMotorClient(MONGO_URI)
db = client['outfit_planner']  # your DB name
cart_collection = db['cart_items']
outfit_collection = db['built_outfits']
