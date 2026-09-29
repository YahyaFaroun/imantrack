# AGENTS.md — Entwickler & Agenten Leitfaden für ImanTrack

Dieses Dokument enthält die grundlegenden Regeln, Architektur-Leitlinien und technischen Beschränkungen für Entwickler und KI-Agenten, die am **ImanTrack**-Codebase arbeiten.

---

## 📌 Projekt-Übersicht

**ImanTrack** ist eine moderne iOS-App (SwiftUI, SwiftData), entwickelt als eleganter Begleiter für das tägliche spirituelle Tracking:
* **Koran-Reader:** Vollständiger Offline-Koran im Uthmanischen Rasm mit QPC-Hafs-Schriftart, OpenType `calt`-Rendering und automatischem Lesefortschritt.
* **Tasbih & Dhikr:** Interaktiver digitaler Zähler mit manueller und automatischer Freihand-Funktion, BPM-Tempoeinstellung und Tageszielen.
* **Adhkar-Tracker:** Morgen-, Abend- und Schlaf-Adhkar sowie wöchentliche Sunnah-Highlights (Sure Al-Kahf am Freitag, Al-Mulk, Al-Baqarah).
* **Fajr-Wecker & Sonnenzeiten:** Standortbasierte Maghrib-Tagesgrenzen-Berechnung und Fajr-Alarme.
* **Statistiken & Fortschritt:** Detaillierte Auswertungen über gelesene Seiten, Suren, Khatm-Abschlüsse und Tasbih-Serien.

---

## 🚨 KRITISCHE REGELN & CONSTRAINTS (STRIKT EINZUHALTEN)

### 1. Koran-Schriftart (CRITICAL RULE)
* Die Schriftart **`KFGQPCHAFSUthmanicScript-Regula`** (`UthmanicHafs1Ver18.ttf`) **DARF NIEMALS GEÄNDERT ODER ERSETZT WERDEN**.
* Jede Änderung an der Koran-Schriftart erfordert die explizite, schriftliche Zustimmung des Users.

### 2. Koran-Textquellen & OpenType `calt` Rendering
* **Visuelle Anzeige (`arabic`):** Verwendet `text_qpc_hafs` aus [quran_offline.json](file:///Users/princepalestine/Desktop/ImanTrack/ImanTrack/ImanTrack/Assets.xcassets/quran_offline.dataset/quran_offline.json), welches QPC Open-Tanwin Codepunkte (`U+0657`, `U+065E`, `U+08F0`–`U+08F2`) enthält.
* **Such- & Vergleichslogik (`textUthmani`):** Verwendet das saubere `text_uthmani` ohne Sonderzeichen für Matching, Suche und Lesefortschritt.
* **OpenType `calt`:** In [Theme.swift](file:///Users/princepalestine/Desktop/ImanTrack/ImanTrack/ImanTrack/Theme.swift#L58-L68) muss `kContextualAlternatesType` (`kContextualAlternatesOnSelector`) auf `UIFontDescriptor` immer aktiviert bleiben, damit iOS CoreText versetztes Tanwin bei Idgham & Ikhfa nativ darstellt.

### 3. Ausgrauen gelesener Verse im Koran (NEVER CHANGE THIS RULE)
* Ein Vers darf **erst dann als gelesen markiert / grau gefärbt werden**, wenn seine Unterkante (`maxY`) die obere Leselinie (`120pt`) beim Herunterscrollen nach oben hin vollständig überschritten hat (`maxY < 120`).
* Solange ein Teil des Verses im oberen Lesebereich noch zu sehen ist, bleibt er ungraviert/normal.
* Beim Hochscrollen dürfen Verse niemals nachträglich als gelesen markiert werden (`isScrollingDown` vorausgesetzt).
* **DIESES VERHALTEN DARF UNTER KEINEN UMSTÄNDEN VERÄNDERT WERDEN.**

### 4. Tab-Wechsel-Verhalten im Koran (NEVER CHANGE THIS RULE)
* Beim Wechseln von anderen Tabs (z. B. *Home* oder *Statistik*) zurück zum Koran-Tab **muss die Koran-Ansicht 100% starr und unverändert** an der exakten Stelle stehen bleiben, an der der Koran verlassen wurde.
* Ein automatisches Scrollen zur Zielstelle (`QuranTabRetapped`) darf **AUSSCHLIESSLICH** ausgelöst werden, wenn der Nutzer sich bereits im Koran-Tab befindet und **erneut** auf den Koran-Tab-Button tippt (`newValue == selectedTab && newValue == 3` in `ContentView.swift`).
* **DIESES VERHALTEN DARF UNTER KEINEN UMSTÄNDEN VERÄNDERT WERDEN.**

### 5. Tasbih & Zähler-Limits
* Einzelne manuelle Zähler-Hinzufügungen in [DhikrDetailView.swift](file:///Users/princepalestine/Desktop/ImanTrack/ImanTrack/ImanTrack/Views/DhikrDetailView.swift) sind auf **maximal 5.000** pro Schritt beschränkt.
* Das Eingabefeld kappt Zahlen bei max. `5000` (4-stellig) und filtert Punkte, Kommas und Sonderzeichen.
* Extremwerte $> 500.000$ werden beim Aufruf automatisch auf 0 zurückgesetzt (Auto-Sanitization).

### 6. Kommunikation & Links
* Antworten an den User erfolgen **immer auf Deutsch** (`user_global`).
* Alle Dateireferenzen in Markdown-Dokumenten verwenden das `file://`-Schema.

---

## 🏗️ Hauptkomponenten & Verzeichnisstruktur

```
ImanTrack/
├── App/
│   └── ImanTrackApp.swift
├── Models/
│   ├── QuranData.swift           # Verse, APIVerse & QPC-Textmodelle
│   ├── QuranAPIService.swift     # Synchroner & Asynchroner Offlinedaten-Zugriff
│   ├── DailyRecord.swift         # SwiftData-Modell für Tagesfortschritt
│   ├── UserSettings.swift        # Einstellungen & Tasbih-Ziele
│   └── LocationAndSolarManager.shared  # Sonnenuntergangs- (Maghrib) Tracking
├── Views/
│   ├── ContentView.swift         # Haupt-Tab-Leiste
│   ├── QuranView.swift           # Koran-Reader mit LazyVStack & ScrollReader
│   ├── DhikrDetailView.swift     # Tasbih-Zähler & BPM-Steuerung
│   ├── AdhkarOverviewView.swift  # Morgen-/Abend-Adhkar
│   ├── TodayView.swift           # Tagesübersicht & Fortschritt
│   └── StatsView.swift           # Statistik-Auswertung
├── Theme.swift                   # Farben, Typografie, Uthmani-Font & cleanQuranText()
└── Fonts/
    └── UthmanicHafs1Ver18.ttf    # Offizieller KFGQPC Uthmanic Hafs Font
```

---

## 🛠️ Build- & Entwickler-Kommandos

Projekt kompilieren:
```bash
xcodebuild -project ImanTrack.xcodeproj -scheme ImanTrack -destination 'generic/platform=iOS' clean build
```
