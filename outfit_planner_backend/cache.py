import time

_CACHE = {}

def get_cached(key: str):
    data = _CACHE.get(key)
    if not data:
        return None
    if data["expires"] < time.time():
        del _CACHE[key]
        return None
    return data["value"]

def set_cache(key: str, value, ttl_seconds: int = 86400):
    _CACHE[key] = {
        "value": value,
        "expires": time.time() + ttl_seconds
    }
