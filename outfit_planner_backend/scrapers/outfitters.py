# scrapers/outfitters.py
from utils import fetch_url, make_soup, sleep_polite, normalize_price

from urllib.parse import quote_plus
from models import Product

BASE = "https://outfitters.com.pk"

def scrape_outfitters(query: str, max_items: int = 12) -> list[Product]:
    q = quote_plus(query)
    url = f"{BASE}/search?q={q}"
    try:
        html = fetch_url(url)
    except Exception:
        return []

    soup = make_soup(html)
    products = []
    cards = soup.select(".product-card, .product-item, .grid-product")
    if not cards:
        cards = soup.select("li.product, div.product")

    for c in cards[:max_items]:
        try:
            title_node = c.select_one(".product-card__title") or c.select_one(".title") or c.select_one(".product-title")
            price_node = c.select_one(".product-card__price") or c.select_one(".price") or c.select_one(".product-price")
            img_node = c.select_one("img")
            link_node = c.select_one("a")

            image = img_node.attrs.get("data-src") or img_node.attrs.get("src") or "" if img_node else ""
            if image.startswith("//"): image = "https:" + image

            href = link_node.attrs.get("href") if link_node else ""
            if href.startswith("/"): href = BASE + href

            products.append(Product(
                title=title_node.get_text(strip=True) if title_node else "",
                price=normalize_price(price_node.get_text()) if price_node else "",
                image=image,
                link=href,
                brand="Outfitters",
                source=url
            ))
        except Exception:
            continue
    sleep_polite()
    return products
