import httpx
from bs4 import BeautifulSoup
import asyncio
import re
import random
from models import Product

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/117.0.0.0 Safari/537.36"
}

async def fetch_url(url: str, timeout: int = 10) -> str:
    async with httpx.AsyncClient(timeout=timeout, headers=HEADERS) as client:
        r = await client.get(url)
        r.raise_for_status()
        return r.text

def make_soup(html: str) -> BeautifulSoup:
    return BeautifulSoup(html, "html.parser")

def normalize_price(price: str) -> str:
    if not price:
        return ""
    return re.sub(r"[^\d.,]", "", price).strip()

async def sleep_polite(min_sec=1, max_sec=3):
    await asyncio.sleep(random.uniform(min_sec, max_sec))
