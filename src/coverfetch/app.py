import html as html_lib
import re
from urllib.parse import quote, unquote, urljoin

import requests
from fastapi import FastAPI, HTTPException, Query

app = FastAPI()

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36",
    "Accept": "text/html,*/*",
    "Accept-Language": "en-US,en;q=0.9",
}


def normalize(text: str) -> str:
    text = html_lib.unescape(text)
    text = text.replace("\\/", "/")
    text = text.replace("\\u002F", "/")
    return unquote(text)


def find_cover(query: str, country: str = "ro"):
    search_url = f"https://music.apple.com/{country}/search?term={quote(query)}"

    r = requests.get(search_url, headers=HEADERS, timeout=15)
    r.raise_for_status()

    text = normalize(r.text)

    patterns = [
        rf'https://music\.apple\.com/{country}/album/[^"\'>\s<\\]+',
        rf'/{country}/album/[^"\'>\s<\\]+',
        r'/album/[^"\'>\s<\\]+',
    ]

    album_url = None

    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            album_url = match.group(0)
            break

    if not album_url:
        raise HTTPException(status_code=404, detail="No album link found")

    if album_url.startswith("/"):
        album_url = urljoin("https://music.apple.com", album_url)

    album_html = requests.get(album_url, headers=HEADERS, timeout=15)
    album_html.raise_for_status()

    album_text = normalize(album_html.text)

    webp_matches = re.findall(
        r'https?://[^"\'>\s<\\]+?bb\.webp[^"\'>\s<\\]*',
        album_text,
    )

    if not webp_matches:
        raise HTTPException(status_code=404, detail="No webp found")

    art_url = webp_matches[-1]

    m3u8_matches = re.findall(
        r'https?://[^"\'>\s<\\]+?\.m3u8[^"\'>\s<\\]*',
        album_text,
    )

    dynamic_art_url = m3u8_matches[-1] if m3u8_matches else None

    return {
        "query": query,
        "country": country,
        "album_url": album_url,
        "art_url": art_url,
        "dynamic_art_url": dynamic_art_url,
    }


@app.get("/get_cover")
def get_cover(
    query: str = Query(..., description="Song or album search query"),
    country: str = Query("ro", description="Apple Music country code"),
):
    try:
        return find_cover(query, country)
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=str(e))
