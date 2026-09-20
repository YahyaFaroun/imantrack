import os
import re

# Pfade definieren
project_dir = "/Users/princepalestine/Desktop/ImanTrack/ImanTrack"
pbxproj_path = os.path.join(project_dir, "ImanTrack.xcodeproj/project.pbxproj")
source_dir = os.path.join(project_dir, "ImanTrack")

# Sprachen und ihre Übersetzungen
translations = {
    "de": "Dein Standort wird verwendet, um die exakte Sonnenuntergangszeit für das spirituelle Zähler-Reset zu berechnen.",
    "en": "Your location is used to calculate the exact sunset time for the spiritual counter reset.",
    "ar": "يُستخدم موقعك لحساب وقت غروب الشمس الدقيق لإعادة ضبط العداد الروحي.",
    "tr": "Manevi sayaç sıfırlaması için tam gün batımı saatini hesaplamak amacıyla konumunuz kullanılır.",
    "id": "Lokasi Anda digunakan untuk menghitung waktu matahari terbenam yang tepat untuk mengatur ulang penghitung spiritual.",
    "ms": "Lokasi anda digunakan untuk mengira waktu matahari terbenam yang tepat untuk menetapkan semula kaunter rohani.",
    "fr": "Votre position est utilisée pour calculer l'heure exacte du coucher du soleil pour la réinitialisation du compteur spirituel.",
    "es": "Su ubicación se utiliza para calcular la hora exacta del atardecer para el restablecimiento del contador espiritual.",
    "ur": "روحانی کاؤنٹر ری سیٹ کے لیے غروب آفتاب کا صحیح وقت معلوم کرنے کے لیے آپ کا مقام استعمال کیا جاتا ہے۔",
    "ru": "Ваше местоположение используется для расчета точного времени заката для сброса духовного счетчика.",
    "bn": "আধ্যাত্মিক কাউন্টার রিসেট করার জন্য সূর্যাস্তের সঠিক সময় গণনা করতে আপনার অবস্থান ব্যবহার করা হয়।",
    "fa": "موقعیت مکانی شما برای محاسبه زمان دقیق غروب آفتاب جهت بازنشانی شمارنده معنوی استفاده می‌شود.",
    "ha": "Ana amfani da wurinka don lissafin ainihin lokacin faɗuwar rana don sake saita ma'aunin ruhaniya.",
    "jv": "Lokasi sampeyan digunakake kanggo ngetung wektu surup sing tepat kanggo ngreset penghitung spiritual.",
    "ku": "Cihê te tê bikar anîn ji bo hesabkirina dema rojavabûnê ya rast ji bo vegerandina hejmarvanê manewî.",
    "pa": "ਰੂਹਾਨੀ ਕਾਊਂਟਰ ਰੀਸੈਟ ਲਈ ਸੂਰਜ ਡੁੱਬਣ ਦੇ ਸਹੀ ਸਮੇਂ ਦੀ ਗਣਨਾ ਕਰਨ ਲਈ ਤੁਹਾਡੇ ਸਥਾਨ ਦੀ ਵਰਤੋਂ ਕੀਤੀ ਜਾਂਦੀ ਹੈ।",
    "ps": "ستاسو موقعیت د روحاني کاونټر ری سیٹ لپاره د لمر لویدو دقیق وخت محاسبې لپاره کارول کیږي.",
    "so": "Goobtaada waxaa loo kullanayaa in lagu xisaabiyo waqtiga saxda ah ee qorax dhaca si dib loogu dejiyo miiska ruuxiga ah.",
    "sw": "Eneo lako linatumiwa kukokotoa wakati sahihi wa machweo kwa ajili ya kuweka upya kihesabu cha kiroho.",
    "uz": "Ma'naviy hisoblagichni qayta o'rnatish uchun quyosh botishining aniq vaqtini hisoblash maqsadida joylashuvingizdan foydalaniladi."
}

# 1. Update project.pbxproj
with open(pbxproj_path, "r", encoding="utf-8") as f:
    content = f.read()

# Ersetze knownRegions
known_regions_match = re.search(r"knownRegions = \(\s*en,\s*Base,\s*\);", content)
if known_regions_match:
    regions_str = "knownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n"
    for lang in sorted(translations.keys()):
        if lang not in ["en"]:
            regions_str += f"\t\t\t\t{lang},\n"
    regions_str += "\t\t\t);"
    content = content.replace(known_regions_match.group(0), regions_str)
    print("knownRegions updated in project.pbxproj")
else:
    # Versuche eine flexiblere regex
    known_regions_match_flex = re.search(r"knownRegions = \(\s*([^)]*)\s*\);", content)
    if known_regions_match_flex:
        # Extrahiere vorhandene und füge neue hinzu
        existing = [r.strip() for r in known_regions_match_flex.group(1).split(",") if r.strip()]
        for lang in translations.keys():
            if lang not in existing:
                existing.append(lang)
        if "Base" not in existing:
            existing.append("Base")
        
        regions_str = "knownRegions = (\n"
        for r in sorted(existing):
            regions_str += f"\t\t\t\t{r},\n"
        regions_str += "\t\t\t);"
        content = content.replace(known_regions_match_flex.group(0), regions_str)
        print("knownRegions updated (flex) in project.pbxproj")
    else:
        print("Warning: knownRegions match not found!")

# Ersetze INFOPLIST_KEY_NSLocationWhenInUseUsageDescription
# Such nach INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "..."; und ersetze durch die englische Version
pattern = r'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "[^"]*";'
replacement = 'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Your location is used to calculate the exact sunset time for the spiritual counter reset.";'
content, count = re.subn(pattern, replacement, content)
print(f"Replaced {count} occurrences of NSLocationWhenInUseUsageDescription in project.pbxproj")

# Datei speichern
with open(pbxproj_path, "w", encoding="utf-8") as f:
    f.write(content)

# 2. Erstelle lproj Ordner und InfoPlist.strings
for lang, text in translations.items():
    lproj_dir = os.path.join(source_dir, f"{lang}.lproj")
    os.makedirs(lproj_dir, exist_ok=True)
    
    strings_path = os.path.join(lproj_dir, "InfoPlist.strings")
    strings_content = f'NSLocationWhenInUseUsageDescription = "{text}";\n'
    
    with open(strings_path, "w", encoding="utf-8") as f:
        f.write(strings_content)
    print(f"Created {strings_path}")

print("Localization setup complete!")
