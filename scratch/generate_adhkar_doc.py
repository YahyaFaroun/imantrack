import json

with open('scratch/adhkar_all_dump.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

md = []
md.append('# 🎙️ Offizielle Aufnahme-Checkliste für Adhkar (Morgen, Abend, Schlafen)\n')
md.append('> [!TIP] Wichtige Aufnahme-Hinweise für den Rezitator:')
md.append('> 1. **Nur 1x einsprechen:** Jedes Bittgebet / jeder Vers muss **NUR EIN EINZIGES MAL** eingesprochen werden. Die App ImanTrack wiederholt die Audioaufnahme automatisch so oft wie nötig (z. B. 3x oder 10x) und zählt jede Wiederholung live mit!')
md.append('> 2. **Identische Duas wiederverwenden:** Viele Adhkar zwischen Morgen und Abend sind zu 100% wortgleich (z. B. Ayat al-Kursi, die 3 Schutzsuren, Sayyidul Istighfar). Diese müssen **nur einmal aufgenommen** und können für beide Kategorien kopiert werden!')
md.append('> 3. **Format & Schnitt:** Idealerweise `.m4a` (AAC, 44.1 kHz, Mono, 96-128 kbps) oder `.mp3`. Am Anfang und Ende jedes Clips ca. 0.1s bis 0.2s Raumton/Stille lassen (keine langen Pausen, damit der Zähler flüssig läuft).\n')

def get_title(ar, de):
    if 'اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ' in ar: return 'Ayat al-Kursi'
    if 'قُلْ هُوَ اللَّهُ أَحَدٌ' in ar: return 'Sure Al-Ikhlas (112)'
    if 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ' in ar: return 'Sure Al-Falaq (113)'
    if 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ' in ar: return 'Sure An-Nas (114)'
    if 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ' in ar: return 'Asbahna wa asbahal-mulku lillah'
    if 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ' in ar: return 'Amsayna wa amsal-mulku lillah'
    if 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ' in ar: return 'Sayyidul Istighfar (Herr aller Vergebungsbitten)'
    if 'آمَنَ الرَّسُولُ' in ar: return 'Die letzten beiden Verse der Sure Al-Baqarah (285–286)'
    if 'سُورَةُ الْمُلْكِ' in ar: return 'Sure Al-Mulk (67)'
    if 'سُبْحَانَ اللَّهِ (ثلاثاً وثلاثين)' in ar: return 'Schlaf-Tasbih (33x SubhanAllah, 33x Alhamdulillah, 34x Allahu Akbar)'
    words = de.split()[:4]
    return ' '.join(words) + '...'

def add_section(title, prefix, items):
    md.append(f'## {title} ({len(items)} Bittgebete)\n')
    for it in items:
        num = it['num']
        fn = f'{prefix}_{num}.m4a'
        cnt = it['count']
        ar = it['arabic']
        trans = it['transliteration']
        de = it['german']
        name = get_title(ar, de)
        
        md.append(f'### #{num} — `{fn}` | **{name}** (App-Wiederholung: {cnt}x)\n')
        md.append(f'**Arabisch:**\n')
        md.append(f'> {ar}\n')
        if trans:
            md.append(f'**Lautschrift (Transliteration):**\n*{trans}*\n')
        if de:
            md.append(f'**Bedeutung (Deutsch):**\n{de}\n')
        md.append('---\n')

add_section('🌅 Morgen-Adhkar', 'morning', data['morgen'])
add_section('🌇 Abend-Adhkar', 'evening', data['abend'])
add_section('🌙 Schlaf-Adhkar', 'sleep', data['schlaf'])

with open('/Users/princepalestine/.gemini/antigravity/brain/c988de47-d5c3-46a8-a524-9c9d00f843e8/adhkar_aufnahmeliste.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(md))

print('Clean artifact generated successfully!')
