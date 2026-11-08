import os
import sys
import json
import time
import base64
import urllib.request
import urllib.error
import subprocess

API_KEY = "AQ.Ab8RN6LqaDSRmYw1Ln5qYYWo92pRDNR6XrrM1aiKWHUCxc7zdA"
MODELS = ["gemini-2.5-flash-preview-tts", "gemini-3.1-flash-tts-preview", "gemini-3.8-flash-tts"]
VOICE = "Iapetus"

PROJECT_ROOT = "/Users/princepalestine/Business/ImanTrack/ImanTrack"
DEST_DIR = os.path.join(PROJECT_ROOT, "ImanTrack/Audio/Adhkar")

tasks = [
    {
        "file": "sleep_7.m4a",
        "arabic": "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا"
    },
    {
        "file": "sleep_9.m4a",
        "arabic": "اللَّهُمَّ رَبَّ السَّمَوَاتِ السَّبْعِ وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالإِنْجِيلِ وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ. اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرْ"
    },
    {
        "file": "sleep_10.m4a",
        "arabic": "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لاَ كَافِيَ لَهُ وَلاَ مُؤْوِيْ"
    },
    {
        "file": "sleep_13.m4a",
        "arabic": "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لاَ مَلْجَأَ وَلاَ مَنْجَا مِنْكَ إِلاَّ إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتْ"
    }
]

def synthesize_one(task, model):
    f_id = task["file"]
    out_path = os.path.join(DEST_DIR, f_id)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": task["arabic"].strip()}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {
                        "voiceName": VOICE
                    }
                }
            }
        }
    }
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read().decode("utf-8"))
        b64 = data["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
        raw_bytes = base64.b64decode(b64)
        temp_raw = f"/tmp/final_{f_id}.raw"
        with open(temp_raw, "wb") as rf:
            rf.write(raw_bytes)
        cmd = [
            "ffmpeg", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1",
            "-i", temp_raw, "-c:a", "aac", "-b:a", "192k", out_path
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if os.path.exists(temp_raw):
            os.remove(temp_raw)
        return True

print("Pruefe verbleibende 4 Duas...")
for t in tasks:
    f_id = t["file"]
    out_path = os.path.join(DEST_DIR, f_id)
    if os.path.exists(out_path):
        print(f"  [BEREITS VORHANDEN] {f_id}")
        continue
    
    done = False
    for model in MODELS:
        try:
            print(f"Versuche {f_id} mit {model}...")
            if synthesize_one(t, model):
                print(f"  [ERFOLG] {f_id} ({os.path.getsize(out_path)} Bytes)")
                done = True
                time.sleep(5)
                break
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"  Modell {model} hat noch Quota-Limit (429).")
            else:
                print(f"  HTTP-Fehler {e.code}: {e.read().decode()[:100]}")
        except Exception as e:
            print(f"  Fehler: {e}")
            
    if not done:
        print(f"Konnte {f_id} noch nicht generieren (Kontingent noch ausgeschoepft).")
        sys.exit(2)

print("\nAlle 4 Duas erfolgreich generiert!")
sys.exit(0)
