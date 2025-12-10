# scrapers/outfitters.py
from utils import fetch_url, make_soup, sleep_polite, normalize_price

from models import Product

BASE = "https://uno.com.pk"

def scrape_uno(query: str, max_items: int = 12) -> list[Product]:
    url = f"{BASE}/search?q={query}"
    try:
        html = fetch_url(url)
    except Exception:
        return []

    soup = make_soup(html)
    products = []
    cards = soup.select(".product, .productCard")
    for c in cards[:max_items]:
        try:
            title_node = c.select_one(".product-title") or c.select_one("h3")
            price_node = c.select_one(".price")
            img_node = c.select_one("img")
            link_node = c.select_one("a")

            image = img_node.attrs.get("src") or "" if img_node else ""
            href = link_node.attrs.get("href") if link_node else ""
            if href.startswith("/"): href = BASE + href

            products.append(Product(
                title=title_node.get_text(strip=True) if title_node else "",
                price=normalize_price(price_node.get_text()) if price_node else "",
                image=image,
                link=href,
                brand="Uno",
                source=url
            ))
        except Exception:
            continue
    sleep_polite()
    return products
