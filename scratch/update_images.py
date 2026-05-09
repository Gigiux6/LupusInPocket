import re
import sys
import time
from duckduckgo_search import DDGS

file_path = r'c:\Progetti\Google Antigravity\lib\data\game_packs.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to find GameIdentity lines
# GameIdentity(name: 'Harry Potter', imageUrl: 'https://ui-avatars.com...')
pattern = re.compile(r"GameIdentity\(name:\s*'([^']+)',\s*imageUrl:\s*'([^']+)'\)")

ddgs = DDGS()

def get_image(name):
    # Try a few times in case of rate limits
    for attempt in range(3):
        try:
            results = ddgs.images(name, max_results=1)
            if results and len(results) > 0:
                return results[0]['image']
        except Exception as e:
            print(f"Error fetching {name}: {e}")
            time.sleep(1)
    return None

new_content = content
matches = pattern.findall(content)
total = len(matches)

print(f"Found {total} identities.")

for i, (name, url) in enumerate(matches):
    if 'ui-avatars.com' not in url:
        print(f"Skipping {name}, already has custom image: {url}")
        continue
    
    print(f"[{i+1}/{total}] Searching for {name}...")
    new_url = get_image(name)
    if new_url:
        print(f"Found: {new_url}")
        # replace just this occurrence
        old_str = f"GameIdentity(name: '{name}', imageUrl: '{url}')"
        new_str = f"GameIdentity(name: '{name}', imageUrl: '{new_url}')"
        new_content = new_content.replace(old_str, new_str)
    else:
        print(f"Failed to find image for {name}")
        
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done updating file.")
