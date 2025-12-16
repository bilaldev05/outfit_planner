import requests
from bs4 import BeautifulSoup
from tenacity import retry, stop_after_attempt, wait_fixed
from models import Product

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

@retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
def fetch(url):
    res = requests.get(url, headers=HEADERS, timeout=15)
    res.raise_for_status()
    return BeautifulSoup(res.text, "html.parser")

def normalize_image(url: str):
    if url.startswith("//"):
        return "https:" + url
    return url
