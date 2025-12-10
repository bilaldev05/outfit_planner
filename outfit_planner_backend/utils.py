# backend/utils.py
import time
import random
import requests
from bs4 import BeautifulSoup
from tenacity import retry, wait_exponential, stop_after_attempt

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; OutfitPlannerBot/1.0; +https://yourapp.example/)"
}

def sleep_polite(min_s=0.6, max_s=1.2):
    time.sleep(random.uniform(min_s, max_s))

@retry(wait=wait_exponential(multiplier=0.5, min=0.5, max=4), stop=stop_after_attempt(3))
def fetch_url(url, params=None, headers=None, timeout=10):
    h = HEADERS.copy()
    if headers:
        h.update(headers)
    r = requests.get(url, params=params, headers=h, timeout=timeout)
    r.raise_for_status()
    return r.text

def make_soup(html):
    return BeautifulSoup(html, "html.parser")

def normalize_price(price_text: str) -> str:
    if not price_text:
        return ""
    return price_text.strip().replace("\n", " ").replace("\xa0", " ").strip()
