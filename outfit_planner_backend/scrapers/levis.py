from utils import fetch_url, make_soup, sleep_polite, normalize_price
from models import Product

BASE = "https://www.levi.com"

def scrape_levis(query: str, max_items: int = 12) -> list[Product]:
    url = f"{BASE}/IN/en/search?q={query}"
    try:
        html = fetch_url(url)
    except Exception:
        return []

    soup = make_soup(html)
    products = []
    cards = soup.select(".product-tile, .product-card")
    for c in cards[:max_items]:
        try:
            title_node = c.select_one(".product-name") or c.select_one(".product-title")
            price_node = c.select_one(".product-price") or c.select_one(".price")
            img_node = c.select_one("img")
            link_node = c.select_one("a")

            image = img_node.attrs.get("data-src") or img_node.attrs.get("src") if img_node else ""
            href = link_node.attrs.get("href") if link_node else ""
            if href.startswith("/"): href = BASE + href

            products.append(Product(
                title=title_node.get_text(strip=True) if title_node else "",
                price=normalize_price(price_node.get_text()) if price_node else "",
                image=image,
                link=href,
                brand="Levi's",
                source=url
            ))
        except Exception:
            continue
    sleep_polite()
    return products
