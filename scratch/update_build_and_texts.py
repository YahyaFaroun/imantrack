import os
import re

project_dir = "/Users/princepalestine/Desktop/ImanTrack/ImanTrack"
pbxproj_path = os.path.join(project_dir, "ImanTrack.xcodeproj/project.pbxproj")
source_dir = os.path.join(project_dir, "ImanTrack")

# 1. Update project.pbxproj
with open(pbxproj_path, "r", encoding="utf-8") as f:
    content = f.read()

# Erhöhe CURRENT_PROJECT_VERSION auf 7
content, count_version = re.subn(r'CURRENT_PROJECT_VERSION = \d+;', 'CURRENT_PROJECT_VERSION = 7;', content)
print(f"Updated CURRENT_PROJECT_VERSION to 7 in {count_version} places")

# Ersetze INFOPLIST_KEY_NSLocationWhenInUseUsageDescription auf den freundlichen deutschen Text als Standard
friendly_de_text = "Wir benötigen deinen ungefähren Standort, um die genaue Zeit für den Sonnenuntergang (Maghrib) zu berechnen, damit sich deine täglichen Zähler traditionell zum Gebetswechsel zurücksetzen."
pattern = r'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "[^"]*";'
replacement = f'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "{friendly_de_text}";'
content, count_desc = re.subn(pattern, replacement, content)
print(f"Updated NSLocationWhenInUseUsageDescription in {count_desc} places in project.pbxproj")

with open(pbxproj_path, "w", encoding="utf-8") as f:
    f.write(content)

# 2. Update de.lproj und en.lproj strings files
# de
de_strings_path = os.path.join(source_dir, "de.lproj/InfoPlist.strings")
with open(de_strings_path, "w", encoding="utf-8") as f:
    f.write(f'NSLocationWhenInUseUsageDescription = "{friendly_de_text}";\n')
print(f"Updated {de_strings_path}")

# en
friendly_en_text = "We use your approximate location to calculate the exact sunset (Maghrib) time, allowing your daily counter to reset aligned with the Sunnah."
en_strings_path = os.path.join(source_dir, "en.lproj/InfoPlist.strings")
with open(en_strings_path, "w", encoding="utf-8") as f:
    f.write(f'NSLocationWhenInUseUsageDescription = "{friendly_en_text}";\n')
print(f"Updated {en_strings_path}")

print("Update complete!")
