from utils import fetch_url, make_soup, sleep_polite, normalize_price
from models import Product

BASE = "https://breakout.com.pk"

def scrape_breakout(query: str, max_items: int = 12) -> list[Product]:
    q = query.replace(" ", "+")
    url = f"{BASE}/search?q={q}"
    try:
        html = fetch_url(url)
    except Exception:
        return []

    soup = make_soup(html)
    products = []
    cards = soup.select(".product-grid-item, .product")
    for c in cards[:max_items]:
        try:
            title_node = c.select_one(".product-title") or c.select_one("h3")
            price_node = c.select_one(".price") or c.select_one(".product-price")
            img_node = c.select_one("img")
            link_node = c.select_one("a")

            image = img_node.attrs.get("data-src") or img_node.attrs.get("src") if img_node else ""
            if image.startswith("//"): image = "https:" + image

            href = link_node.attrs.get("href") if link_node else ""
            if href.startswith("/"): href = BASE + href

            products.append(Product(
                title=title_node.get_text(strip=True) if title_node else "",
                price=normalize_price(price_node.get_text()) if price_node else "",
                image=image,
                link=href,
                brand="Breakout",
                source=url
            ))
        except Exception:
            continue
    sleep_polite()
    return products
