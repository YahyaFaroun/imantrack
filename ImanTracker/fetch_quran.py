import urllib.request
import json
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

def fetch_page(page):
    url = f"https://api.quran.com/api/v4/verses/by_page/{page}?fields=text_uthmani"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    retries = 3
    while retries > 0:
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
                return page, data['verses']
        except Exception as e:
            retries -= 1
            time.sleep(1)
    print(f"Failed to fetch page {page}")
    return page, []

all_verses = []
print("Fetching pages from Quran API concurrently...")
results = {}

with ThreadPoolExecutor(max_workers=20) as executor:
    futures = {executor.submit(fetch_page, p): p for p in range(1, 605)}
    count = 0
    for future in as_completed(futures):
        page, verses = future.result()
        results[page] = verses
        count += 1
        if count % 100 == 0:
            print(f"Fetched {count} pages")

# Sort by page to ensure correct order
for page in sorted(results.keys()):
    all_verses.extend(results[page])
    
with open("quran_offline.json", "w", encoding="utf-8") as f:
    json.dump(all_verses, f, ensure_ascii=False)
print(f"Done. Saved {len(all_verses)} verses.")
