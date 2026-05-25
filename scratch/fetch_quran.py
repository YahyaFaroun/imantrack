import urllib.request
import json

def fetch_surah(number):
    url = f"http://api.alquran.cloud/v1/surah/{number}"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read())['data']

swift_code = "let quranVerses: [(id: Int, surah: Int, ayah: Int, arabic: String)] = [\n"
id_counter = 0

for s in [1, 2]:
    surah = fetch_surah(s)
    for ayah in surah['ayahs']:
        arabic = ayah['text']
        if s != 1 and ayah['numberInSurah'] == 1:
            arabic = arabic.replace("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ", "")
        # Escape newlines, quotes, and backslashes
        arabic = arabic.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")
        swift_code += f'    ({id_counter}, {s}, {ayah["numberInSurah"]}, "{arabic}"),\n'
        id_counter += 1

swift_code += "]\n"

with open("scratch/verses.swift", "w") as f:
    f.write(swift_code)
print("Done")
