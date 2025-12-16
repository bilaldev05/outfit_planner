import asyncio
from .utils import fetch_url, make_soup, normalize_price, sleep_polite
from models import Product

async def scrape_royaltag(query: str, max_items: int = 6):
    try:
        base_url = "https://royaltag.com.pk"
        url = f"{base_url}/search?q={query.replace(' ', '+')}"
        html = await fetch_url(url)
        soup = make_soup(html)
        products = []

        items = soup.select(".product-item")[:max_items]
        for p in items:
            # Title
            title = p.select_one(".title").get_text(strip=True) if p.select_one(".title") else ""
            # Price
            price = normalize_price(p.select_one(".price").get_text(strip=True)) if p.select_one(".price") else ""

            # Image extraction
            image = ""
            img_tag = p.select_one("img")
            if img_tag:
                # Prefer lazy-loaded data-src
                image = img_tag.get("data-src") or img_tag.get("src") or ""

                # If inside <picture> tag
                if not image:
                    picture_tag = p.select_one("picture source")
                    if picture_tag:
                        image = picture_tag.get("data-srcset") or picture_tag.get("srcset") or ""

                # Clean up relative URLs
                if image.startswith("//"):
                    image = "https:" + image
                elif image.startswith("/"):
                    image = base_url + image
                elif not image.startswith("http"):
                    image = base_url + "/" + image

            # Link
            a_tag = p.select_one("a")
            link = base_url + a_tag.get("href") if a_tag else ""

            products.append(Product(
                title=title,
                price=price,
                image=image,
                link=link,
                brand="RoyalTag",
                source="RoyalTag"
            ))

        await sleep_polite()
        return products

    except Exception as e:
        print("RoyalTag scraper failed:", e)
        return []
