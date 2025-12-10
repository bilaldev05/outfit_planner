# backend/models.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional

class Product(BaseModel):
    title: str = Field(...)
    price: str = Field(default="")
    image: str = Field(default="")
    link: str = Field(default="")
    brand: str = Field(default="")
    source: str = Field(default="")

    model_config = {
        "extra": "allow"
    }

    @field_validator("title", "price", "image", "link", "brand", "source", mode="before")
    def default_str(cls, v):
        return v or ""
