import asyncio
from .utils import fetch_url, make_soup, normalize_price, sleep_polite
from models import Product

async def scrape_gulahmad(query: str, max_items: int = 6):
    try:
        url = f"https://gulahmad.com.pk/search?q={query.replace(' ', '+')}"
        html = await fetch_url(url)
        soup = make_soup(html)
        products = []

        items = soup.select(".product-card")[:max_items]
        for p in items:
            title = p.select_one(".product-name").get_text(strip=True) if p.select_one(".product-name") else ""
            price = normalize_price(p.select_one(".price").get_text(strip=True)) if p.select_one(".price") else ""
            image = p.select_one("img").get("src") if p.select_one("img") else ""
            link = "https://gulahmad.com.pk" + p.select_one("a").get("href") if p.select_one("a") else ""
            products.append(Product(title=title, price=price, image=image, link=link, brand="GulAhmed", source="GulAhmed"))

        await sleep_polite()
        return products
    except Exception as e:
        print("GulAhmed scraper failed:", e)
        return []
