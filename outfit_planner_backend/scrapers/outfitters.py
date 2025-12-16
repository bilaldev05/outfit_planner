import asyncio
from .utils import fetch_url, make_soup, normalize_price, sleep_polite
from models import Product

async def scrape_outfitters(query: str, max_items: int = 6):
    try:
        base_url = "https://outfitters.com.pk"
        url = f"{base_url}/search?q={query.replace(' ', '+')}"
        html = await fetch_url(url)
        soup = make_soup(html)
        products = []

        items = soup.select(".product-card")[:max_items]
        for p in items:
            title = p.select_one(".product-title").get_text(strip=True) if p.select_one(".product-title") else ""
            price = normalize_price(p.select_one(".product-price").get_text(strip=True)) if p.select_one(".product-price") else ""
            image = p.select_one("img").get("src") if p.select_one("img") else ""
            if image and image.startswith("/"):
                image = base_url + image
            link = base_url + p.select_one("a").get("href") if p.select_one("a") else ""

            products.append(Product(title=title, price=price, image=image, link=link, brand="Outfitters", source="Outfitters"))

        await sleep_polite()
        return products
    except Exception as e:
        print("Outfitters scraper failed:", e)
        return []
