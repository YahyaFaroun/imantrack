import os
import sys
import json
import time
import base64
import urllib.request
import urllib.error
import subprocess

API_KEY = "AQ.Ab8RN6LqaDSRmYw1Ln5qYYWo92pRDNR6XrrM1aiKWHUCxc7zdA"
MODEL = "gemini-2.5-flash-preview-tts"
VOICE = "Iapetus"

AUDIO_DIR = "/Users/princepalestine/Business/ImanTrack/ImanTrack/ImanTrack/Audio/Adhkar"

tasks = [
    # 1. Dhikr: Allahumma inni asbahtu/amsaytu ushhiduk (Waqf mit Sukun auf ushhiduk und arshik)
    {
        "files": ["morning_8.m4a"],
        "arabic": "اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكْ، وَأُشْهِدُ حَمَلَةَ عَرْشِكْ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكْ",
        "desc": "morning_8 (Ushhiduk & Arshik mit Sukun-Waqf)"
    },
    {
        "files": ["evening_8.m4a"],
        "arabic": "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكْ، وَأُشْهِدُ حَمَلَةَ عَرْشِكْ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكْ",
        "desc": "evening_8 (Ushhiduk & Arshik mit Sukun-Waqf)"
    },
    # 2. Dhikr: Hasbiyallahu la ilaha illa Huw (Waqf auf 'Huw' statt 'Huwa')
    {
        "files": ["morning_11.m4a", "evening_11.m4a"],
        "arabic": "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوْ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمْ",
        "desc": "morning_11 & evening_11 (Pausieren bei Huw)"
    },
    # 3. Dhikr: Asbahna/Amsayna ala fitratil-Islam (Fatha bei Ibrahima deutlich ausgesprochen)
    {
        "files": ["morning_18.m4a"],
        "arabic": "أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمْ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينْ",
        "desc": "morning_18 (Ibrahima mit Fatha im Redefluss)"
    },
    {
        "files": ["evening_18.m4a"],
        "arabic": "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمْ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينْ",
        "desc": "evening_18 (Ibrahima mit Fatha im Redefluss)"
    },
    # 4. Schlaf-Dhikr: Tasbih mit Verbindungswort 'Wa'
    {
        "files": ["sleep_8_alhamdulillah.m4a"],
        "arabic": "وَالْحَمْدُ لِلّٰهْ",
        "desc": "sleep_8_alhamdulillah (mit gesprochenem 'Wa')"
    },
    {
        "files": ["sleep_8_allahuakbar.m4a"],
        "arabic": "وَاللّٰهُ أَكْبَرْ",
        "desc": "sleep_8_allahuakbar (mit gesprochenem 'Wa')"
    },
    {
        "files": ["sleep_8.m4a"],
        "arabic": "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَاللَّهُ أَكْبَرْ",
        "desc": "sleep_8 (Referenzclip mit Verbindungs-Wa)"
    }
]

def synthesize(arabic_text, target_files):
    print(f"Synthetisiere: {arabic_text[:50]}...")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": arabic_text.strip()}]}],
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
        raw = base64.b64decode(b64)
        
        tmp_raw = "/tmp/gemini_tts_temp.raw"
        with open(tmp_raw, "wb") as f:
            f.write(raw)
            
        for fname in target_files:
            out_path = os.path.join(AUDIO_DIR, fname)
            cmd = [
                "ffmpeg", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1",
                "-i", tmp_raw,
                "-af", "highpass=f=60,afftdn=nr=10:nf=-50:tn=1",
                "-c:a", "aac", "-b:a", "192k", out_path
            ]
            subprocess.run(cmd, check=True, stderr=subprocess.DEVNULL)
            print(f"  -> Gespeichert: {fname} ({os.path.getsize(out_path)} Bytes)")
            
        if os.path.exists(tmp_raw):
            os.remove(tmp_raw)

print("Starte gezielte Generierung der korrigierten Adhkar...")
for t in tasks:
    print(f"\n--- {t['desc']} ---")
    synthesize(t["arabic"], t["files"])
    time.sleep(4)

print("\nAlle 8 Korrektur-Aufnahmen erfolgreich generiert und entrauscht!")
