# ImanTrack — Vollständige Portierungs-Spezifikation (`PORTING_SPEC.md`)

> **Ziel dieses Dokuments:** Diese Spezifikation beschreibt die iOS-App **ImanTrack (Version 2.1.0, Stand Git-Tag `swift-ios-stand-2026-11-08`)** vollständig, lückenlos und deterministisch, sodass ein Entwicklerteam die gesamte Anwendung **1:1 in React Native / Expo** (TypeScript) nachbauen kann – **ohne Zugriff auf den ursprünglichen Swift-Quellcode**.

---

## Inhaltsverzeichnis

1. [Architektur- & Projektübersicht](#1-architektur---projektübersicht)
2. [Design-System, Farben, Typografie & Icons](#2-design-system-farben-typografie--icons)
3. [Navigation, Onboarding & Alle Screens im Detail](#3-navigation-onboarding--alle-screens-im-detail)
4. [Datenmodelle & Persistenzschema](#4-datenmodelle--persistenzschema)
5. [Gesamte Geschäftslogik & Algorithmen im Detail](#5-gesamte-geschäftslogik--algorithmen-im-detail)
6. [Alle Einstellungen mit Standardwerten](#6-alle-einstellungen-mit-standardwerten)
7. [Herkunft & Format aller Inhalte, Medien & `Translations.json`](#7-herkunft--format-aller-inhalte-medien--translationsjson)
8. [Haptik, Animationen, Audio-Session & Berechtigungen](#8-haptik-animationen-audio-session--berechtigungen)
9. [Externe Bibliotheken & React-Native / Expo Portierungs-Mapping](#9-externe-bibliotheken--react-native--expo-portierungs-mapping)

---

## 1. Architektur- & Projektübersicht

### 1.1 Kernkonzept & Prinzipien
* **Zweck:** ImanTrack ist ein privater, ablenkungsfreier täglicher Ibadah-Tracker für Muslime mit Fokus auf fünf Säulen des Alltags:
  1. **Islamischer Tagesrhythmus ab Maghrib** inkl. astronomischer Offline-Gebetszeiten und Live-Countdown.
  2. **Fajr-Tracking** (pünktlich vor Sonnenaufgang vs. nachgebetet/Qada).
  3. **Kontinuierlicher Offline-Quran-Reader** (Uthmanischer Rasm / QPC Hafs, 604 Seiten, 6.236 Verse) mit zeichengenauer automatischer Vers-Erfassung beim Herunterscrollen ohne manuelles Abhaken.
  4. **Zeitfenster-gesteuerte Adhkar** (Schlaf-, Morgen-, Abend-Adhkar sowie Sure Al-Kahf am Freitag, Sure Al-Mulk und Sure Al-Baqarah) mit Manuell-, Auto-Count- und Sprach-/Rezitationsmodus.
  5. **Digitaler Tasbih-Zähler** mit Freihand-Auto-Counter in 3 Geschwindigkeitsstufen, Mehrfach-Varianten (Istighfar, Salawat), eigenen Dhikrs und prozentualer Minus-Korrektur.
* **100 % Offline-First & Privacy-by-Design:**
  * Kein Benutzerkonto, kein Cloud-Backend, kein Tracking/Analytics.
  * Sämtliche Texte (Quran, Adhkar, Übersetzungen, FAQ), Schriftarten und Audiodateien sind fest im App-Bundle enthalten.
  * Einzige ausgehende Netzwerkverbindung der gesamten App ist das optionale **Support-/Feedback-Formular** (`POST https://api.emailjs.com/api/v1.0/email/send`) sowie der Link zur App-Store-Bewertung.

### 1.2 App-Lifecycle & Globale Hintergrunddienste
Beim App-Start (`ImanTrackApp`) und bei jedem Wechsel des App-Zustands (`AppState` in React Native: `active` / `background` / `inactive`) laufen folgende globale Operationen ab:

1. **Datenbank-Initialisierung & Singleton-Prüfung:**
   * Lokale Datenbank öffnen (`UserSettings`, `DailyRecord`, `CustomTasbih`).
   * Existiert noch kein `UserSettings`-Datensatz, wird sofort einer mit Standardwerten angelegt, wobei `language` anhand der Gerätesprache initialisiert wird (`["de", "en", "ar", "tr", "id", "ms", "fr", "es", "ur", "ru", "bn"]`, Fallback `"en"`).
   * Einmalige Datenmigration `QuranMigrationV2`: Falls `quranMigrationV2_completed == false`, werden für alle historischen `DailyRecord`-Einträge `quranPagesRead = floor(quranVersesRead / 15)` neu berechnet (sofern `quranVersesRead > 0`), danach wird `quranMigrationV2_completed = true` gesetzt.
2. **Beim Wechsel in `active` (Vordergrund):**
   * `LocationAndSolarManager.shared.checkTrackingDay()` prüft sofort, ob Maghrib überschritten wurde und ein neuer islamischer Tag begonnen hat.
   * Falls Standortberechtigung bereits erteilt ist (`.authorizedWhenInUse` oder `.authorizedAlways`), wird einmalig ein frischer Standortfix angefordert (`requestLocationUpdate()`), der nach Empfang sofort wieder gestoppt wird (Akku-Schonung).
   * `AdhkarReminderManager.shared.scheduleReminders()` plant das rollierende 7-Tage-Fenster der Adhkar-Erinnerungen neu.
   * `PrayerNotificationManager.shared.rescheduleAll()` plant das rollierende 4-Tage-Fenster der Gebets-/Adhan-Benachrichtigungen neu.
3. **Beim Wechsel in `background` / `inactive`:**
   * `QuranProgressStore.flushIfNeeded()`: Schreibt alle im RAM gepufferten gelesenen Quran-Verse/Seiten und das aktuelle `QuranBookmark` sofort synchron in die Datenbank / `AsyncStorage`.
   * Laufende Tasbih-Auto-Counter in `DhikrDetailView` pausieren automatisch (`pauseTimer()`).

### 1.3 Globales Farbschema & RTL-Steuerung (Right-to-Left)
* **Farbschema:** Gesteuert über `UserSettings.isDarkMode` (Standard: `true` = Dark Mode!). Während des Onboardings ist Dark Mode immer erzwungen.
* **Sprach-Richtung (`layoutDirection`):**
  * Ist `settings.language` in `["ar", "ur", "fa", "ps", "ku", "he"]`, schaltet das gesamte UI-Layout auf **RTL (`rightToLeft`)** um.
  * Alle übrigen Sprachen (`de`, `en`, `tr`, `fr`, `es`, `id`, `ms`, `ru`, `bn` usw.) nutzen **LTR (`leftToRight`)**, wobei arabische Quran- und Dhikr-Textblöcke lokal immer explizit als RTL gerendert werden.

---

## 2. Design-System, Farben, Typografie & Icons

### 2.1 Farbpalette (Exakte Hex-Werte aus `Theme.swift` & Views)

#### Primär- & Hintergrundfarben (`Theme.swift`)
| Token-Name | Light Mode (Hex / RGB) | Dark Mode (Hex / RGB) | Verwendung |
| :--- | :--- | :--- | :--- |
| `Theme.islamicGreen` / `Theme.accent` | `#2E7D32` (`rgb(46, 125, 50)`) | `#2E7D32` (`rgb(46, 125, 50)`) | Primäre Markenfarbe, aktive Tabs, erledigte Ringe/Häkchen, Primär-Buttons, Toggles |
| `Theme.background` | `#F5F7F5` (`rgb(245, 247, 245)`) | `#000000` (`rgb(0, 0, 0)`) | Haupthintergrund aller Screens |
| `Theme.darkBackground` | `#000000` (`rgb(0, 0, 0)`) | `#000000` (`rgb(0, 0, 0)`) | Erzwungener Schwarzhintergrund (z. B. Onboarding) |
| `Theme.cardBackground` | `#FFFFFF` (`rgb(255, 255, 255)`) | `#1C1C1E` (`rgb(28, 28, 30)`) | Alle Karten, Kacheln, Modals und Listenboxen |

#### Quran-Reader-Farbschemata (`quranTheme`)
| Theme-ID | Hintergrundfarbe | Textfarbe (Ungelesene Verse) | Textfarbe (Gelesene Verse) | Versnummern-Deckkraft |
| :--- | :--- | :--- | :--- | :--- |
| `"system"` (Standard) | Light: `#F5F7F5` / Dark: `#000000` | Light: `#000000` / Dark: `#FFFFFF` | `#808080` (System Gray) | `opacity: 0.85` |
| `"light"` (Eisblau) | `#EBF3FA` (`rgb(235, 243, 250)`) | `#142030` (`rgb(20, 32, 48)`) | `#808080` | `opacity: 0.85` |
| `"sepia"` | `#F4ECD8` (`rgb(244, 236, 216)`) | `#2C2218` (`rgb(44, 34, 24)`) | `#808080` | `opacity: 0.85` |
| `"dark"` | `#000000` (`rgb(0, 0, 0)`) | `#FFFFFF` (`rgb(255, 255, 255)`) | `#808080` | `opacity: 0.85` |

#### Semantische Status- & Systemfarben (iOS-Standardwerte für RN-Portierung)
| Bedeutung | Light Mode Hex | Dark Mode Hex | Einsatzorte |
| :--- | :--- | :--- | :--- |
| **Primärtext (`primary`)** | `#000000` | `#FFFFFF` | Überschriften, Zählerstände, arabischer Haupttext |
| **Sekundärtext (`secondary` / `gray`)** | `#8E8E93` | `#8E8E93` | Subtitles, Transliteration, inaktive Icons, Zeitstempel |
| **Warnung / Aktiv-Fortschritt (`orange`)** | `#FF9500` | `#FF9F0A` | Fortschrittsringe `< 100 %`, Fajr „Nachgebetet“, Maghrib-Warnbanner, negativer Statistik-Trend, Abend-/Maghrib-Icons |
| **Destruktiv / Korrektur (`red`)** | `#FF3B30` | `#FF453A` | Tasbih Minus-Button, Prozent-Abzugsbuttons, Löschen-Aktionen |
| **Highlight / Sunnah (`yellow`)** | `#FFCC00` | `#FFD60A` | Morgen-Sonne, Onboarding-Sparkles, Al-Kahf Stern |
| **Nacht / Schlaf (`blue` / `indigo` / `purple`)** | `#007AFF` / `#5856D6` / `#AF52DE` | `#0A84FF` / `#5E5CE6` / `#BF5AF2` | Schlaf-Adhkar Mond-Icon, FAQ-Kategorie-Icons |
| **Karten-Trennlinie / Rahmen** | `rgba(0,0,0,0.08)` | `rgba(255,255,255,0.10)` | Dezente Kartenränder (`lineWidth: 1`), inaktive Fortschrittsbalken |
| **Sekundärer Gruppen-BG** | `#F2F2F7` | `#2C2C2E` | FAQ-Karten, Segmented Controls, Eingabefelder |

---

### 2.2 Typografie & Kritische Schriftart-Regeln

#### Gebundelte Schriftarten (`ImanTrack/Fonts/`)
| Dateiname | PostScript-Name | Größe | Verwendungszweck |
| :--- | :--- | :--- | :--- |
| `UthmanicHafs1Ver18.ttf` | `KFGQPCHAFSUthmanicScript-Regula` | 242 KB | **KRITISCH (PFLICHT):** Einzige Quran-Hauptschriftart & arabische Tasbih-Schriftart. **Darf niemals durch eine andere Schrift ersetzt werden!** |
| `surah-name-v2.ttf` | `surah-name-v2` | 580 KB | Kalligrafische Suren-Überschriften im Quran-Reader (`fontSize * 0.75`, Buchstabenabstand `tracking: 2`). |
| `uthmanic-shuba-v20.ttf` | `KFGQPCShubaUthmanicScript-Regul` | 247 KB | Im Bundle registriert (Reserve). |
| `KFGQPCUthmanTahaNaskh.ttf` | *(Naskh)* | 267 KB | Im Bundle registriert (Reserve). |
| `AmiriQuran-Regular.ttf` | *(Amiri Quran)* | 137 KB | Im Bundle registriert (Reserve). |
| `me_quran.ttf` / `me_quran_volt_newmet.ttf` | *(ME Quran)* | je 460 KB | Im Bundle registriert (Reserve). |

> **KRITISCHE RENDERING-REGEL FÜR REACT NATIVE / EXPO (OpenType `calt`):**
> `UthmanicHafs1Ver18.ttf` benötigt zwingend aktivierte **OpenType Contextual Alternates (`calt`)** sowie volle Ligaturen, damit versetztes Tanwin (`U+08F0`–`U+08F2`, `U+0657`, `U+065E`) bei Idgham und Ikhfa korrekt dargestellt wird.
> * **iOS (React Native):** `fontVariant` / Native Text-View mit `UIFontDescriptor` Feature `kContextualAlternatesType: kContextualAlternatesOnSelector` + `.ligature: 2`.
> * **Android (React Native):** `fontFeatureSettings: "'calt' 1, 'liga' 1, 'clig' 1"` (bzw. native `Paint.setFontFeatureSettings("'calt' 1")`).

#### System-Schriftgrößen-Mapping (iOS Dynamic Type Standard -> React Native `fontSize` / `fontWeight`)
| SwiftUI-Stil | Größe (`pt`/`px`) | Standard-Gewicht | Typische Verwendung |
| :--- | :--- | :--- | :--- |
| `.largeTitle` | `34` | `700` (Bold) | Große Hauptzahlen |
| `.title` | `28` | `700` (Bold) | Onboarding-Titel, Modal-Überschriften |
| `.title2` | `22` | `700` (Bold) | Screen-Abschnittsüberschriften, Statistik-Summen |
| `.title3` | `20` | `600` (Semibold) | Karten-Haupttitel |
| `.headline` | `17` | `600` (Semibold) | Primäre Button-Texte, Kartentitel, Navigationstitel |
| `.body` | `17` | `400` (Regular) | Fließtext, Transliteration, Formularzeilen |
| `.callout` | `16` | `400` / `500` | Sekundäre Beschreibungen, Info-Banner |
| `.subheadline` | `15` | `400` / `600` | Untertitel, Status-Texte, Datumszeilen |
| `.footnote` | `13` | `400` / `500` | Hilfstexte, Footer-Hinweise |
| `.caption` | `12` | `400` / `600` | Labels, Gebetsnamen in der 6er-Leiste |
| `.caption2` | `11` | `400` / `700` | Badges, Zeitstempel, Mini-Prozentwerte |
| **Tasbih-Hauptzähler** | `64` (`rounded`) | `700` (Bold) | Zentrale Zahl im großen Tasbih-Zählring (`monospacedDigit`) |
| **Quran-Fließtext** | `22` – `42` (Default `30`) | `400` (Regular) | Stufenlos per Pinch-to-Zoom in `1pt`-Schritten (Suren-Reader `2pt`-Schritte); Versnummern `fontSize * 0.85` |
| **Adhkar Arabisch** | `26` | `400` (Regular) | Arabischer Dhikr-Text in `AdhkarCard` (`lineSpacing: 10`, zentriert) |

---

### 2.3 Abstände, Radien & Schatten (Layout-Konstanten)
* **Außenabstand Screen (`paddingHorizontal`):** `16px` (`TodayView`, `TasbihView`, `StatsView`) bzw. `20px` (`QuranPageView`, `FAQView`, Suren-Reader).
* **Karten-Innenabstand (`padding`):** `16px` (Standard-Karten), `20px` (`AdhkarCard`, große Hero-Karten).
* **Vertikaler Kartenabstand (`gap` / `spacing`):** `12px` bis `16px` innerhalb einer Sektion, `20px` bis `24px` zwischen Sektionen.
* **Eckenradien (`borderRadius`):**
  * Große Karten & Container: `16px` (`TodayView`-Karten, `TasbihView`-Karten, `AdhkarCard`, `StatsView`-Karten, `SupportReportView`).
  * Mittlere Buttons & Sub-Banner: `12px` bis `14px` (Primär-Buttons, FAQ-Karten, Info-Banner).
  * Kompakte Pills & Badges: `8px` bis `10px` (Prozent-Badges, Trend-Pills), `20px` / `999px` (runde Kapsel-Buttons).
* **Schatten (Light Mode):** `shadowColor: '#000'`, `shadowOpacity: 0.04`–`0.06`, `shadowRadius: 8`, `shadowOffset: { width: 0, height: 2 }` (im Dark Mode keine sichtbaren Schlagschatten, stattdessen `#1C1C1E` auf `#000000`).

---

### 2.4 Vollständiges Icon-Verzeichnis (SF Symbols -> Expo `@expo/vector-icons` / Lucide / Ionicons)

#### Custom Bild-Assets (`Assets.xcassets`)
1. `sujud_icon.png` (`ImanTrack/Assets.xcassets/sujud_icon.imageset/sujud_icon.png`, Template-Rendering / einfarbig einfärbbar): Wird für die **Fajr-Gebets-Karte** verwendet (Größe `24×24` bzw. `28×28`, eingefärbt in `#2E7D32`, `#FF9500` oder `#8E8E93`).
2. `ImanTrack_logo.png` (`AppIcon.appiconset`, 1024×1024): App-Icon (Light, Dark, Tinted Varianten vorhanden).

#### Alle verwendeten SF-Symbol-Namen nach Funktionsbereich
| SF Symbol Name (Swift) | Einsatzort in ImanTrack | Empfohlenes Ionicons / MaterialCommunityIcons Äquivalent |
| :--- | :--- | :--- |
| `circle.hexagongrid.fill` | Tab 0 Icon (Tasbih), Settings-Zeile Tasbih, FAQ | `radio-button-on` / `dots-hexagon` |
| `book.closed.fill` | Tab 1 Icon (Adhkar), Settings-Zeile Adhkar | `book` / `book-variant` |
| `house.fill` | Tab 2 Icon (Heute) | `home` |
| `book.fill` | Tab 3 Icon (Quran), Quran-Karten, Suren-Buttons | `book-open` / `book-open-page-variant` |
| `chart.bar.fill` | Tab 4 Icon (Statistik), FAQ | `stats-chart` / `chart-bar` |
| `gearshape.fill` | Einstellungen-Button oben rechts in `TodayView` | `settings-sharp` |
| `location.fill` / `location.slash.fill` | Standort-Status / Berechtigungs-Button | `location` / `location-outline` |
| `sunrise.fill` | Shuruq (Sonnenaufgang) & Fajr-Zeitfenster | `sunny-outline` / `weather-sunset-up` |
| `sun.max.fill` | Dhuhr, Morgen-Adhkar (`#FFCC00` / `#FF9500`) | `sunny` / `white-balance-sunny` |
| `sun.haze.fill` | Asr-Gebet | `partly-sunny` / `weather-partly-cloudy` |
| `sunset.fill` | Maghrib, Abend-Adhkar, Tageswechsel-Warnung (`#FF9500`) | `weather-sunset-down` |
| `moon.stars.fill` | Isha, Onboarding Slide 0, Nacht-Anzeige, FAQ Adhkar | `moon` / `weather-night` |
| `moon.fill` / `moon.zzz.fill` | Fajr (Gebetsleiste), Schlaf-Adhkar (`#007AFF` / `#5E5CE6`) | `moon` / `power-sleep` |
| `sparkles` | Onboarding Slide 7, Sure Al-Kahf Freitags-Highlight, Khatm | `sparkles` |
| `checkmark` / `checkmark.circle.fill` | Erledigt-Häkchen in Ringen, Karten, Listen | `checkmark` / `checkmark-circle` |
| `clock` / `clock.fill` / `clock.arrow.circlepath` | Noch nicht aktive Adhkar, Fajr Nachgebetet (Qada), Gebets-Settings | `time-outline` / `time` / `history` |
| `exclamationmark.circle.fill` | Abgelaufene Adhkar-Zeit (`expired`) | `alert-circle` |
| `play.fill` / `pause.fill` / `stop.circle.fill` | Auto-Counter & Audio-Steuerung (Tasbih & Adhkar) | `play` / `pause` / `stop-circle` |
| `tortoise.fill` | Geschwindigkeitsstufe 0 (Langsam) | `turtle` (MaterialCommunityIcons) |
| `hare.fill` | Geschwindigkeitsstufe 2 (Schnell) | `rabbit` (MaterialCommunityIcons) |
| `plus` / `minus` | Tasbih Manuell Hinzufügen (`+`) & Minus-Korrektur (`-`) | `add` / `remove` |
| `globe` | Übersetzungs-Button in `DhikrDetailView` & `AdhkarCard` | `globe-outline` |
| `speaker.wave.2.fill` / `speaker.slash` | Sprachmodus-Toggle (Voice-Mode) in `AdhkarSessionView` & Preview | `volume-high` / `volume-mute` |
| `ellipsis.circle` | Menü-Button oben rechts in `AdhkarSessionView` (Reihenfolge bearbeiten) | `ellipsis-horizontal-circle` |
| `arrow.up.circle.fill` / `arrow.down.circle.fill` | Adhkar-Karte nach oben/unten schieben im Edit-Modus | `arrow-up-circle` / `arrow-down-circle` |
| `line.3.horizontal` | Drag-/Sortier-Hinweis im Adhkar-Edit-Modus | `reorder-three` |
| `chevron.left` / `chevron.right` | Zurück-Navigation, Wochen-/Jahres-Blättern in `StatsView`, Listenpfeile | `chevron-back` / `chevron-forward` |
| `arrow.up.right` / `arrow.down.right` | Positiver / negativer Trend-Pfeil in `StatsView` | `trending-up` / `trending-down` |
| `bell.fill` / `bell.badge.fill` / `bell.slash.fill` | Erinnerungen & `NotificationPermissionSheet` | `notifications` / `notifications-off` |
| `questionmark.circle.fill` | FAQ & Hilfe | `help-circle` |
| `envelope` / `envelope.fill` | Support kontaktieren & E-Mail-Feld | `mail-outline` / `mail` |
| `paperclip` / `trash` | Screenshot anhängen / löschen im Support-Formular | `attach` / `trash` |
| `star.fill` | „ImanTrack bewerten“ | `star` |
| `hand.tap.fill` | Onboarding Slide 5 (Digitale Tasbih) | `finger-print` / `gesture-tap` |

---

## 3. Navigation, Onboarding & Alle Screens im Detail

### 3.1 Erststart-Onboarding (`OnboardingView`)
* **Trigger:** Wird als Vollbild gerendert, solange `hasSeenOnboarding == false` (in `AsyncStorage`).
* **Erscheinungsbild:** Immer erzwungener Dark Mode (`#000000` Hintergrund, `#1C1C1E` Karten), kein Tab-Bar sichtbar.
* **Aufbau von oben nach unten:**
  1. **Top-Bar (`paddingHorizontal: 24, paddingTop: 16, height: 44`):**
     * Rechtsbündig: Text-Button `L10n.tr("onboarding_skip", lang)` (`#8E8E93`, `15px`), sichtbar auf den Slides `0..6`. Tippen setzt `currentPage = 7` (springt direkt zur letzten Folie). Auf Slide `7` ausgeblendet.
  2. **Horizontaler Pager (`8` Seiten, Index `0` bis `7`, mit Seiten-Indikatorpunkten unten):**
     * **Slide 0 – Willkommen:** Rundes Icon-Badge (`100×100`, Hintergrund `rgba(46,125,50,0.15)`) mit `moon.stars.fill` (`48px`, `#2E7D32`), Titel `onboarding_welcome_title` (`28px bold`, weiß, zentriert), Beschreibung `onboarding_welcome_desc` (`17px`, `#8E8E93`, zentriert).
     * **Slide 1 – Islamischer Tagesrhythmus (Maghrib):** Icon `sunset.fill` (`48px`, `#FF9500` auf `rgba(255,149,0,0.15)`), Titel `onboarding_maghrib_title`, Beschreibung `onboarding_maghrib_desc`. **Spezial-Logik beim Tippen auf „Weiter“:** Ist der Standortstatus `notDetermined`, wird `requestWhenInUseAuthorization()` aufgerufen, bevor zu Slide 2 gewechselt wird.
     * **Slide 2 – Quran Auto-Tracking Erklärung:** Icon `book.fill` (`48px`, `#2E7D32`), Titel `onboarding_quran_title`, Beschreibung `onboarding_quran_desc` (erklärt das automatische Grau-Färben beim Scrollen).
     * **Slide 3 – Quran-Tagesziel festlegen:** Icon `book.fill` (`40px`, `#2E7D32`), Titel `onboarding_quran_goal_title`, Untertitel `onboarding_quran_goal_desc`. Darunter eine Karte (`#1C1C1E`, `borderRadius: 16`, `padding: 20`) mit großer Zahl (`48px bold`, `#2E7D32`) + Einheit `pages_per_day` sowie Minus-/Plus-Stepper für `settings.quranDailyGoal` (**Min: `1`, Max: `20`, Schrittweite: `1`, Standard: `5`**). Zeigt zusätzlich die geschätzte Dauer für eine komplette Khatm an (`ceil(604 / quranDailyGoal)` Tage).
     * **Slide 4 – Adhkar im Tagesverlauf:** Titel `onboarding_adhkar_title`, Beschreibung `onboarding_adhkar_desc`, darunter 3 Info-Zeilen im Kartenstil:
       1. `moon.fill` (`#0A84FF`) – `adhkar_sleep`
       2. `sun.max.fill` (`#FFD60A`) – `adhkar_morning`
       3. `sunset.fill` (`#FF9F0A`) – `adhkar_evening`
     * **Slide 5 – Digitale Tasbih Erklärung:** Icon `hand.tap.fill` (`48px`, `#2E7D32`), Titel `onboarding_tasbih_title`, Beschreibung `onboarding_tasbih_desc`.
     * **Slide 6 – Tasbih-Tagesziele anpassen:** Titel `onboarding_tasbih_goals_title`, darunter 3 Stepper-Karten (`#1C1C1E`, `borderRadius: 14`, `padding: 14`):
       1. **Istighfar** (`settings.istighfarGoal`): Bereich `100...50000`, Schritt `100`, Standard `1000`.
       2. **Salawat** (`settings.salawatGoal`): Bereich `100...50000`, Schritt `100`, Standard `500`.
       3. **Subhanallahi wa bihamdihi** (`settings.subhanAllahGoal`): Bereich `10...10000`, Schritt `10`, Standard `100`.
     * **Slide 7 – Sunnah-Highlights & Start:** Icon `sparkles` (`48px`, `#FFD60A`), Titel `onboarding_sunnah_title`, Beschreibung `onboarding_sunnah_desc` (Sure Al-Kahf am Freitag, Sure Al-Mulk vor dem Schlafen).
  3. **Bottom-Button (`paddingHorizontal: 24, paddingBottom: 32`):**
     * Volle Breite, Höhe `54px`, `borderRadius: 14`, Hintergrund `#2E7D32`, weißer Text (`17px semibold`).
     * Auf Slides `0..6`: Beschriftung `next` („Weiter“), wechselt animiert zu `currentPage + 1` (leichte Haptik).
     * Auf Slide `7`: Beschriftung `onboarding_start` („Jetzt starten“), speichert `UserSettings` in DB, setzt `hasSeenOnboarding = true` (Success-Haptik) und öffnet die Haupt-App auf **Tab 2 (Heute)**.

---

### 3.2 Haupt-Tab-Leiste & Globale Overlays (`ContentView`)
* **5 Tabs am unteren Bildschirmrand** (`activeTintColor: #2E7D32`, `inactiveTintColor: #8E8E93`):
  * **Tab 0:** `TasbihView` — Label `tab_tasbih`, Icon `circle.hexagongrid.fill`
  * **Tab 1:** `AdhkarOverviewView` — Label `tab_adhkar`, Icon `book.closed.fill`
  * **Tab 2 (INITIALER START-TAB!):** `TodayView` — Label `tab_today`, Icon `house.fill`
  * **Tab 3:** `QuranView` — Label `tab_quran`, Icon `book.fill`
  * **Tab 4:** `StatsView` — Label `tab_stats`, Icon `chart.bar.fill`
* **KRITISCHE TAB-WECHSEL-REGEL FÜR TAB 3 (QURAN):**
  * Der Quran-Screen **muss im Speicher gemountet bleiben** (`lazy: false` / kein Unmount bei Tab-Wechsel!). Beim Wechsel von Tab 0/1/2/4 zurück zu Tab 3 muss die Scrollposition pixelgenau und völlig starr an der verlassenen Stelle stehen bleiben.
  * Nur wenn der Nutzer sich **bereits auf Tab 3 befindet** und **erneut** auf das Tab-3-Icon tippt (`newTab === 3 && currentTab === 3`), wird das Event `QuranTabRetapped` gefeuert (scrollt sanft zur aktuellen Lesefront).
* **Globale Maghrib-Overlays (für Tabs 0, 1, 3, 4 – auf Tab 2 sind sie direkt im Layout integriert):**
  * **Oben (`top: 45px`, `paddingHorizontal: 16`):**
    * `MaghribFiveMinuteWarningBanner` (wenn `showFiveMinuteWarning == true`): Kompakte Karte mit orangem Rahmen (`rgba(255,149,0,0.4)`), `sunset.fill`-Icon (`#FF9500`), Titel `maghrib_5min_warning_title` (`14px bold`) und Untertitel `maghrib_5min_warning_desc` (`12px`). Verschwindet automatisch nach `7.0` Sekunden.
    * `MaghribCountdownBanner` (wenn `maghribCountdownSeconds != nil`, d. h. letzte `60..1` Sekunden vor Maghrib): Pulsierendes Banner mit Countdown `00:SS` (`monospacedDigit`, `18px bold`, `#FF9500`) und animiertem Fortschrittsbalken (`seconds / 60`).
  * **Unten (`bottom: 65px`, über der Tab-Leiste):**
    * `MaghribDayResetToast` (wenn `showDayResetToast == true`, für `4.5` Sekunden nach Maghrib): Kapsel-Toast (`#2E7D32`, weißer Text + `moon.stars.fill`) mit Text `new_islamic_day_started`.

---

### 3.3 Tab 2: Heute (`TodayView`) — Startbildschirm
Scrollbarer Hauptscreen (`Theme.background`, `padding: 16`, vertikales `spacing: 24`), in der oberen NavigationBar rechts ein Zahnrad-Button (`gearshape.fill`, öffnet `SettingsView` als Sheet):

1. **Maghrib-Banner (ganz oben im `VStack`, falls aktiv):**
   * `MaghribFiveMinuteWarningBanner` (wenn `showFiveMinuteWarning == true`) bzw. `MaghribCountdownBanner` (wenn `maghribCountdownSeconds != nil`).

2. **Zentraler Header-Block (`headerView`, ohne eigene Kartenbox direkt auf dem Hintergrund):**
   * **Zustand A – Standort berechtigt (`canCalculatePrayerTimes == true`):**
     * **Block 1 – Große einzeilige Live-Countdown-Überschrift (`paddingBottom: 16`):**
       Zentrierte einzeilige Textzeile (`40px rounded`, `minimumScaleFactor: 0.7`):
       `"{Gebetsname} {in} {HH:MM:SS}"` — dabei sind Gebetsname (`semibold`) und `prayer_countdown_in` (`regular`) in Sekundärfarbe (`#8E8E93`), während der Countdown `HH:MM:SS` (`bold`, `monospacedDigit`) in **`#2E7D32`** leuchtet. *(Wichtig: Der Countdown zählt nur auf die 5 Pflichtgebete `[Fajr, Dhuhr, Asr, Maghrib, Isha]` herunter und überspringt Shuruq!)*
     * **Block 2 – Kompakte 6er-Gebetszeitenzeile (`paddingHorizontal: 4`, `paddingBottom: 20`):**
       6 gleich breite Spalten nebeneinander (`Fajr`, `Shuruq`, `Dhuhr`, `Asr`, `Maghrib`, `Isha`), jeweils vertikal gestapelt (`spacing: 3`):
       * Oben Gebetsname (`11px`, `bold` & `#2E7D32` falls nächstes Gebet, sonst `regular` & `#8E8E93`).
       * Unten Uhrzeit `HH:mm` (`13px monospacedDigit`, `bold` & `#2E7D32` falls nächstes Gebet, sonst `medium` & Primärfarbe).
     * **Block 3 – Zentrierte Datumszeilen (`spacing: 4`):**
       * **Zeile 1 (oben, größer & grün):** Gregorianisches Datum bzw. zwischen Maghrib und Fajr `"Nacht zum <Wochentag>, <Datum>"` (`17px headline semibold`, Farbe **`#2E7D32`**).
       * **Zeile 2 (unten, kleiner & grau):** Transliteriertes/lokalisiertes Hijri-Datum inkl. islamischem Wochentag, z. B. `"Al-Jumu'ah, 14. Dhu al-Qi'dah 1447 AH"` (`15px subheadline`, Farbe **`#8E8E93`**).
   * **Zustand B – Kein Standort freigegeben (`canCalculatePrayerTimes == false`):**
     * Zeigt oben einen zentrierten Text-Button `enable_location_prayer_times` (`13px footnote`, `#8E8E93`, triggert `requestAuthorization()`) und direkt darunter denselben zweizeiligen Datumsblock (Gregorianisch oben in `#2E7D32`, Hijri unten in `#8E8E93`).

3. **Prominente Fajr-Status-Karte (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`, reine Status-Anzeige – Tippen wechselt animiert zu `selectedTab = 1` / Adhkar-Tab!):**
   * Zeile 1 (`HStack`): Links `sujud_icon.png` (`20×20`, eingefärbt in `#2E7D32`) + Titel `fajr_prayer` (`17px headline`), rechts Symbol `"✓"` (`bold`, `#2E7D32` bei `"onTime"`, `#FF9500` bei `"late"`) bzw. `"○"` (`#8E8E93` bei `"none"`).
   * Zeile 2: Statustext `fajr_status_ontime` (`#2E7D32`), `fajr_status_late` (`#FF9500`) oder `fajr_status_none` (`#8E8E93`) in `15px subheadline`. *(Die eigentliche Eingabe/Änderung des Fajr-Status erfolgt im Adhkar-Tab auf der dortigen Fajr-Karte!)*

4. **Tagesfortschritts-Karten (`ResultCard`-Komponenten, jeweils `Theme.cardBackground`, `borderRadius: 16`, `padding: 16`, Header mit Icon in `#2E7D32` + Titel + `chevron.right`):**
   * **ResultCard 1: Quran (Tippen setzt `selectedTab = 3`):**
     * Icon `book.fill`, Titel `tab_quran`.
     * Zeile: `daily_goal_title` links, rechts `"{displayPercent}%"` (`15px bold`, `#2E7D32` bei `100 %`, `#FF9500` bei `> 0 %`, `#8E8E93` bei `0 %`).
     * Horizontaler Fortschrittsbalken (`ProgressView`, Farbe `#2E7D32`).
     * Unterzeile (`12px caption`, `#8E8E93`): `"{quranPagesRead}/{goal} {pages} · {quranVersesRead} {verses}"`.
   * **ResultCard 2: Adhkar (Tippen setzt `selectedTab = 1`):**
     * Icon `book.closed.fill`, Titel `tab_adhkar`.
     * Vertikale Zeilen (`AdhkarResultRow`, `spacing: 12`) in der Reihenfolge:
       1. `adhkar_sleep` (`schlafAdhkarDone` + Uhrzeit `HH:mm`)
       2. `adhkar_morning` (`morgenAdhkarDone` + Uhrzeit `HH:mm`)
       3. `surah_alkahf` *(nur sichtbar wenn `isFridayKahfVisible == true`, d. h. islamischer Freitag ab Fajr!)*
       4. `adhkar_evening` (`abendAdhkarDone` + Uhrzeit `HH:mm`)
   * **ResultCard 3: Tasbih (Tippen setzt `selectedTab = 0`):**
     * Icon `circle.hexagongrid.fill`, Titel `tab_tasbih`.
     * Vertikale Zeilen (`TasbihResultRow`, `spacing: 10`) für jede aktivierte Tasbih-Kategorie (`istighfar`, `salawat` [mit Freitagsziel falls aktiv], `subhanAllah`, `alhamdulillah`, `allahuAkbar` [= La hawla], `laIlahaIllallah`) mit Name links und `"{count} / {goal}"` + Status-Indikator rechts.

---

### 3.4 Tab 0: Tasbih-Übersicht (`TasbihView`) & Zähler-Detail (`DhikrDetailView`)

#### 3.4.1 `TasbihView` (Liste aller aktiven Tasbih-Zähler)
* **Header:** Navigationstitel `tab_tasbih`.
* **Inhalt (`ScrollView`, `padding: 16`, `spacing: 14`):**
  * Rendert in fester Reihenfolge alle aktivierten Kategorien (`UserSettings.<cat>Enabled == true`), gefolgt von allen `CustomTasbih` mit `isEnabled == true`:
    1. **Istighfar** (`TasbihCategory.istighfar`) – Titel `tasbih_istighfar`, Arabisch der ersten aktiven Form (Standard: `أَسْتَغْفِرُ اللَّهَ`), Ziel `settings.istighfarGoal` (Default `1000`).
    2. **Salawat** (`TasbihCategory.salawat`) – Titel `tasbih_salawat`, Arabisch `اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ`, Ziel: an islamischen Freitagen (Donnerstag Maghrib bis Freitag Maghrib), falls `salawatFridayGoal > 0`, gilt `salawatFridayGoal` (mit grünem Freitags-Badge), sonst `salawatGoal` (Default `500`).
    3. **SubhanAllah wa bihamdihi** (`TasbihCategory.subhanAllah`) – Arabisch `سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ`, Ziel `subhanAllahGoal` (Default `100`).
    4. **Alhamdulillah / Baqiyat as-Salihat** (`TasbihCategory.alhamdulillah`) – Arabisch `سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ`, Ziel `alhamdulillahGoal` (Default `100`).
    5. **La hawla wa la quwwata illa billah** (Technischer Enum-Key: `TasbihCategory.allahuAkbar`!) – Titel-Key `tasbih_lahawla`, Arabisch `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ`, speichert in `allahuAkbarCount`, Ziel `allahuAkbarGoal` (Default `100`).
    6. **La ilaha illallah (Tahlil)** (`TasbihCategory.laIlahaIllallah`) – Arabisch `لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ`, Ziel `laIlahaIllallahGoal` (Default `100`).
    7. **Eigene Tasbihs (`CustomTasbih`):** Sortiert nach `createdAt` aufsteigend.
  * **Aufbau jeder Tasbih-Karte (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`):**
    * Oben: Links lokalisierter Kategoriename (`16px semibold`), rechts Fortschrittszähler `"{count} / {goal}"` (`15px bold monospacedDigit`, `#2E7D32` wenn `count >= goal`, sonst `#8E8E93`).
    * Mitte: Rechtsbündiger arabischer Vorschautext in `UthmanicHafs1Ver18.ttf` (`22px`, max. 2 Zeilen).
    * Unten: Horizontaler Fortschrittsbalken (`height: 6px`, `borderRadius: 3px`, Füllfarbe `#2E7D32` bei `>= 100 %`, sonst `#FF9500`).
    * Tippen navigiert per Stack-Push zu `DhikrDetailView`.

#### 3.4.2 `DhikrDetailView` (Interaktiver Vollbild-Tasbih-Zähler)
Aufbau von oben nach unten (`Theme.background`, kein Scrollen des Hauptcontainers, vertikale Flex-Aufteilung):

1. **Navigation-Bar:**
   * Links: Zurück-Button (`chevron.left`).
   * Mitte: Kategoriename (`17px semibold`).
   * Rechts: Runder Button mit `globe`-Icon (`20px`, `#2E7D32`) -> öffnet ein Bottom-Sheet mit der vollständigen **Übersetzung / Bedeutung** des aktuell gewählten Dhikrs (`currentTranslation`).

2. **Oberer Dhikr-Textbereich (ca. 32 % Bildschirmhöhe):**
   * Falls mehrere Varianten aktiv sind (bei **Istighfar** bis zu 5 Formen, bei **Salawat** bis zu 3 Formen):
     * Oben kleine **Seiten-Punkte (Page-Dots)** (`6×6px`, aktiver Punkt `#2E7D32`, inaktive `rgba(142,142,147,0.35)`).
     * Horizontal wischbarer Pager (`TabView`), der beim Wischen `selectedIndex` wechselt (bei laufendem Auto-Counter passt sich das Zeitintervall sofort an die neu gewählte Variante an!).
   * **Arabischer Text:** Zentriert, Schriftart `KFGQPCHAFSUthmanicScript-Regula`, dynamische Schriftgröße je nach Textlänge (`28px` bei `< 50` Zeichen, `24px` bei `< 120` Zeichen, `20px` bei langen Texten wie Sayyidul Istighfar / Ibrahimiyyah), vertikal scrollbar falls sehr lang.
   * **Transliteration (Umschrift):** Nur sichtbar wenn `settings.showTransliteration == true` UND `settings.language != "ar"`. Zentriert darunter in `14px`, `#8E8E93`.

3. **Zentraler Zählring (Herzstück des Screens, Durchmesser `240×240px`):**
   * Äußerer Hintergrundring: `strokeWidth: 12`, Farbe `rgba(142,142,147,0.15)`.
   * Grüner/Oranger Fortschrittsring: `strokeWidth: 12`, `strokeLinecap: 'round'`, Start bei `-90°` (12 Uhr), Füllgrad `min(1.0, currentCount / goal)`, Farbe `#2E7D32` ab Zielerreichung, sonst `#2E7D32` (im Zählring immer `#2E7D32` mit sanfter Animation).
   * **Grüner Puls-Blitz (`flashOpacity`):** Innerhalb des Kreises liegt eine gefüllte grüne Scheibe (`#2E7D32`), die bei **jedem einzelnen Zählschritt** (manuell und automatisch) kurz aufleuchtet (exakte Formel siehe Abschnitt 5.6.3).
   * **Inhalt im Kreiszentrum:**
     * Aktueller Zählerstand `currentCount` (`64px bold rounded monospacedDigit`, `#FFFFFF` / `#000000`).
     * Darunter Zielanzeige `"/ {goal}"` (`16px medium`, `#8E8E93`).
     * Falls Auto-Counter aktiv (`settings.tasbihAutoCount == true`): Kleines Play-/Pause-Badge (`play.fill` / `pause.fill`, `#2E7D32`) unterhalb des Ziels.
   * **Tap-Verhalten auf den großen Kreis:**
     * Ist `settings.tasbihAutoCount == false` (Manueller Modus): Jeder Tipp zählt `+1`, spielt Haptik (`light`, sofern `tasbihVibrationEnabled == true`) und triggert den grünen Blitz.
     * Ist `settings.tasbihAutoCount == true` (Auto-Modus): Ein Tipp auf den Kreis toggelt **Start / Pause** des automatischen Zählers! (Beim Start beginnt `sessionCount = 0` für die spätere Prozent-Korrektur und `KeepAwake` wird aktiviert.)

4. **Untere Steuerleiste (`paddingHorizontal: 24, paddingBottom: 28`):**
   Drei Elemente nebeneinander (`HStack`, zentriert):
   * **Links – Minus-Button (`48×48`, runder Kreis, Hintergrund `rgba(255,59,48,0.12)`, Icon `minus` in `#FF3B30`):**
     * Deaktiviert (`opacity: 0.35`), wenn `currentCount == 0`.
     * Tippen pausiert ggf. den Auto-Counter und öffnet das **Korrektur-Sheet (Minus-Modal)**:
       * Zeigt aktuellen Stand `actual_count` und – falls `sessionCount > 0` – die Anzahl der letzten Zählsession (`last_session_count`).
       * **Schnell-Prozent-Buttons (nur aktiv wenn `sessionCount > 0`):** 4 rote Pill-Buttons **`-10%`**, **`-30%`**, **`-50%`**, **`-100%`** – ziehen den entsprechenden Prozentsatz von `sessionCount` (`round(sessionCount * pct)`) vom Gesamtzähler ab (gedeckelt auf `>= 0`).
       * **Letzte manuelle Hinzufügung rückgängig machen** (nur sichtbar wenn `lastManualAddedAmount > 0`): Button „Letzte Eingabe (`+{lastManualAddedAmount}`) entfernen“.
       * **Freie Zahl abziehen:** Numerisches Textfeld (nur Ziffern `0-9`, max. `5000`) + roter Bestätigungsbutton.
   * **Mitte – 3-Stufen-Geschwindigkeitswähler (nur sichtbar wenn `settings.tasbihAutoCount == true`):**
     * Kapsel-Container (`Theme.cardBackground`, `borderRadius: 22`, `padding: 4`) mit 3 Segment-Buttons:
       * Stufe `0`: Icon `tortoise.fill` (Langsam)
       * Stufe `1`: Text `Normal` (`13px semibold`)
       * Stufe `2`: Icon `hare.fill` (Schnell)
     * Aktives Segment hat Hintergrund `#2E7D32` und weiße Schrift/Icon. Wird individuell pro Dhikr und pro Istighfar-/Salawat-Variante unter `tasbih_speed_<key>` gespeichert (Default `1` = Normal).
   * **Rechts – Plus-Button (`48×48`, runder Kreis, Hintergrund `rgba(46,125,50,0.15)`, Icon `plus` in `#2E7D32`):**
     * Öffnet das **Manuell-Hinzufügen-Sheet (Plus-Modal)**:
       * Numerisches Eingabefeld (filtert alle Nicht-Ziffern wie Punkte/Kommas sofort heraus, kappt live bei **max. `5000`**!).
       * Schnellauswahl-Chips (`+10`, `+33`, `+100`, `+500`, `+1000`).
       * Grüner „Hinzufügen“-Button addiert den Wert zu `currentCount`, speichert ihn in `lastManualAddedAmount` und schließt das Sheet.

---

### 3.5 Tab 1: Adhkar-Übersicht (`AdhkarOverviewView`), Session (`AdhkarSessionView`) & Suren-Reader

#### 3.5.1 `AdhkarOverviewView`
Scrollbare Übersicht (`Theme.background`, `padding: 16`, `spacing: 16`) mit dem Titel `tab_adhkar`:

Reihenfolge der Karten von oben nach unten (orientiert am Verlauf des **islamischen Tages**, der mit Maghrib beginnt!):
1. **Schlaf-Adhkar (`AdhkarSessionType.sleep`):**
   * Icon: `moon.zzz.fill` (`#5E5CE6` / `#0A84FF`), Titel `adhkar_sleep`, `13` Dhikrs.
   * Zeitfenster: **Aktiv** von `maghribPrev` (Beginn des islamischen Tages) bis `01:00` Uhr nachts; ab `01:00` Uhr bis zum nächsten Maghrib Status `expired` (nachholbar per Einmal-Abhaken).
2. **Fajr-Gebets-Karte (identische Logik wie in `TodayView`):**
   * Vor Fajr gesperrt (`future`, `opacity: 0.6`), zwischen Fajr und Shuruq `active`, nach Shuruq weiterhin für pünktlich/Qada-Eintragung bedienbar.
3. **Morgen-Adhkar (`AdhkarSessionType.morning`):**
   * Icon: `sun.max.fill` (`#FFCC00`), Titel `adhkar_morning`, `25` Dhikrs.
   * Zeitfenster: Vor Fajr `future` (ausgegraut, `opacity: 0.6`, nicht klickbar, zeigt Startzeit Fajr `HH:mm`), von `Fajr` bis `Dhuhr` `active`, ab `Dhuhr` bis Maghrib `expired`.
4. **Sure Al-Kahf Karte (NUR sichtbar an einem islamischen Freitag UND erst ab Fajr: `weekday(trackingDate) == 6 && now >= fajrDate`):**
   * Gold/Grün hervorgehobene Sunnah-Karte mit `sparkles`- & `book.fill`-Icon, Titel `surah_alkahf`.
   * Zeigt erledigt-Häkchen wenn `todayRecord.surahAlKahfDone == true`, sonst Öffnen-Button für `AlKahfReaderView` sowie Direkt-Abhaken-Option.
5. **Abend-Adhkar (`AdhkarSessionType.evening`):**
   * Icon: `sunset.fill` (`#FF9500`), Titel `adhkar_evening`, `23` Dhikrs.
   * Zeitfenster: Vor Asr `future` (gesperrt bis Asr `HH:mm`, `opacity: 0.6`), von `Asr` bis `Maghrib` `active`, ab `Maghrib` beginnt bereits der neue islamische Tag.

**Darstellung der Zustände auf jeder Adhkar-Übersichtskarte:**
* **Erledigt (`Done == true`):** Grüner Kreis mit `checkmark`, grüner Statustext + Uhrzeit der Erledigung (`HH:mm`). Immer antippbar (zum Einsehen oder Rückgängigmachen).
* **Aktiv (`state == .active`, noch offen):** Oranger/Grüner Fortschrittsring (`completedCount / totalMandatoryCount`), Statustext `active_until` + Enduhrzeit.
* **Zukünftig (`state == .future`):** `opacity: 0.6`, Schloss-/Uhr-Icon `clock`, Text `starts_at` + Startuhrzeit, Tap deaktiviert.
* **Abgelaufen (`state == .expired`, noch nicht erledigt):** Oranges `exclamationmark.circle.fill`, Hinweis „Zeit abgelaufen – tippen zum Nachholen/Abhaken“, Karte bleibt antippbar!

#### 3.5.2 `AdhkarSessionView` (Vollbild-Durchführung einer Adhkar-Kategorie)
Wird als `fullScreenCover` / Modal geöffnet:
1. **Top-NavigationBar:**
   * Links: Schließen-Button (`close`) sowie im Normalmodus ein `ellipsis.circle`-Menübutton („Reihenfolge anpassen“ -> schaltet `isEditMode = true`). Im Edit-Modus rechts ein grüner `Fertig`-Pill-Button.
   * Mitte: Kategorietitel (`adhkar_sleep` / `adhkar_morning` / `adhkar_evening`).
   * Rechts (wenn `adhkarState == .active` und nicht im Edit-Modus):
     * **Voice-Mode Toggle-Button:** Runder Button (`speaker.wave.2.fill` in `#2E7D32` wenn aktiv, `speaker.slash` in `#8E8E93` wenn aus).
     * **Fortschrittszähler:** `"{completedItems.count} / {adhkarList.count}"` (`15px bold`, `#8E8E93`).
2. **Einmal-Abhaken / Rückgängig-Banner ganz oben in der Liste (sichtbar sobald `adhkarState != .future`):**
   * **Wenn Kategorie noch NICHT erledigt:** Dezenter Rahmen-Button mit Text `adhkar_already_read_prompt` (*„Bereits gelesen? Hier abhaken“*). Im Zustand `expired` prominenter dargestellt (`15px medium`, `paddingVertical: 10`, Hintergrund `rgba(142,142,147,0.16)`). Ein Tipp speichert vorher einen `AdhkarCompletionSnapshot` (damit etwaige Teilfortschritte und Tasbih-Stände exakt wiederhergestellt werden können!) und markiert alle Pflicht-Items als erledigt.
   * **Wenn Kategorie erledigt UND `hasSnapshot == true`:** Grüner Vollflächen-Button (`#2E7D32`, weißer Text) mit zwei Zeilen: `adhkar_read_done` (*„Als gelesen markiert ✓“*) und darunter `adhkar_tap_to_undo` (*„Tippen zum Rückgängigmachen“*).
3. **Kartenliste (`ForEach` über `localAdhkarList`, `spacing: 20`):**
   Jede `AdhkarCard` (`Theme.cardBackground`, `borderRadius: 16`, `padding: 20`, grüner Rahmen wenn gerade Auto-Count/Audio läuft, leicht ausgegraut wenn erledigt oder optional):
   * **Im Edit-Modus (`isEditMode == true`, auslösbar per Menü oder Long-Press `0.5s` auf eine Karte):** Zeigt oben links Pfeil-Buttons `arrow.up.circle.fill` und `arrow.down.circle.fill` zum Verschieben der Karte; Reihenfolge wird sofort unter `adhkar_custom_order_<type>` gespeichert.
   * **Arabischer Dhikr-Text:** `26px`, Zeilenabstand `10px`, zentriert, RTL (`opacity: 0.6` falls `isMandatory == false`).
   * **Transliteration:** Zentriert darunter (`17px`, `#8E8E93`), ausgeblendet falls `showTransliteration == false` oder `language == "ar"`.
   * **Spezialbutton für Sure Al-Mulk (Schlaf-Adhkar #12):** Grüne Aktionsbox (`rgba(46,125,50,0.12)`, `borderRadius: 12`) mit `book.fill`, Text `read_surah_mulk` und `chevron.right` -> öffnet `AlMulkReaderView`; Klick auf „Als gelesen markieren“ im Reader hakt Schlaf-Adhkar #12 automatisch ab.
   * **Zähl-Kreis-Button unten mittig (`80×80px`, nur sichtbar wenn `adhkarState == .active` UND `item.isMandatory == true`):**
     * *Erledigt:* Gefüllter grüner Kreis (`#2E7D32`) mit weißem `checkmark`; während `1.0s` nach Abschluss erscheint darunter `MashaAllah!`.
     * *Voice-Mode aktiv:* Fortschrittsring (`strokeWidth: 5`) mit `speaker.wave.2.fill` bzw. pulsierendem `pause.fill` (`scale 1.0 <-> 1.05`, `0.6s`) und Zähler `current/target`.
     * *Auto-Count-Modus (`settings.adhkarAutoCount == true`):* Kreis mit `play.fill` / `pause.fill` und aktuellem Zählerstand `current / count`.
     * *Manueller Modus (`settings.adhkarAutoCount == false`):* Bei `count == 1` Kreis mit Häkchen-Umriss / `"1×"`; bei `count > 1` Fortschrittsring mit großer Zahl `current / count`.
   * **Info-/Einstellungs-Icon unten rechts (`globe` / Info-Button):** Öffnet `AdhkarInfoModalView` (zeigt vollständige lokalisierte Übersetzung des Bittgebets, einen Toggle **„Pflicht / Optional“** `adhkar_<prefix>_mandatory` sowie einen 3-Stufen-Geschwindigkeitswähler **Langsam / Normal / Schnell** `adhkar_<prefix>_speed` individuell für genau dieses Bittgebet!).
4. **Abschluss & Benachrichtigungs-Prompt:**
   * Sobald alle `isMandatory == true` Items einer Session erreicht sind, wird automatisch `todayRecord.<type>AdhkarDone = true` und `<type>AdhkarTime = now` gespeichert.
   * Unten am Listenende steht zusätzlich ein grüner Abschluss-Button `finish_adhkar_session`. Wurde der Nutzer nach seiner allerersten abgeschlossenen Session noch nie nach Push-Mitteilungen gefragt (`hasPromptedNotificationPermissionAfterFirstSession == false` und Systemstatus `notDetermined`), öffnet sich `NotificationPermissionSheet`.

#### 3.5.3 Suren-Reader (`AlKahfReaderView`, `AlMulkReaderView`, `AlBaqarahReaderView`)
Alle drei dedizierten Suren-Reader teilen sich exakt denselben Aufbau:
* **NavigationBar:** Titel der Sure (`surah_alkahf` = Sure 18, `surah_almulk` = Sure 67, `surah_baqarah` = Sure 2), links Button `close`, Hintergrund & Textfarbe gemäß `quranTheme`.
* **Inhalt (`ScrollView` mit Pinch-to-Zoom `22pt..42pt` in `2pt`-Schritten, speichert `quranFontSize`):**
  1. Zentrierte **Basmala** (`بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ`) in `KFGQPCHAFSUthmanicScript-Regula` (`fontSize * 0.85`, `opacity: 0.8`, `paddingTop: 20`).
  2. Durchgehender arabischer Textblock aller Verse der Sure (`cleanQuranText()` + arabisch-indische Versnummer in Ornamentklammern `\u{FD3F}١\u{FD3E}`), zentriert/RTL, `paddingHorizontal: 20`.
  3. Am Ende der Sure grüner Vollflächen-Button (`#2E7D32`, `borderRadius: 12`, `padding: 16`):
     * **Al-Kahf:** `mark_as_read` -> setzt `todayRecord.surahAlKahfDone = true`, `surahAlKahfTime = now` und schließt das Modal.
     * **Al-Mulk:** `mark_as_read` -> ruft `onComplete()` auf (inkrementiert Schlaf-Adhkar #12) und schließt das Modal.
     * **Al-Baqarah:** `"{mark_as_read} ({settings.surahBaqarahGoal}%)"` -> setzt `todayRecord.surahBaqarahProgress = settings.surahBaqarahGoal`, `surahBaqarahTime = now` und schließt das Modal.

---

### 3.6 Tab 3: Quran-Reader (`QuranView`, `QuranPageView`, `JustifiedText`)

Der Quran-Reader ist ein kontinuierlicher, vorwärtsgerichteter Mushaf-Lesefluss (Seiten `1` bis `604`, `6.236` Verse):

1. **Kompakter Top-Header (fixiert über dem Scrollbereich, Hintergrund passend zu `quranTheme`):**
   * Links: Aktueller Surenname (arabisch/lokalisiert) + Seitenangabe `"{page} {currentPage}"` (sowie Juz-Info).
   * Rechts: Kompakte Tagesziel-Anzeige `"{todayPages} / {quranDailyGoal}"` + Prozent-Badge (`min(100, round(todayPages / goal * 100))%`, grün ab 100 %, sonst `#2E7D32` / `#FF9500`) und kleiner Fortschrittsbalken.
2. **Unsichtbare obere Lesekante (`threshold = fontLineHeight` im Seiten-Koordinatensystem bzw. `~120pt` Bildschirmkante inklusive Header):**
   * Es wird keine störende Linie gezeichnet, aber exakt an dieser oberen Lesekante entscheidet sich Vers für Vers das Ausgrauen (siehe Kapitel 5.5).
3. **Scrollbereich (`LazyVStack` über Seiten ab der Startseite des aktuellen `readFrontier` bis Seite `604`):**
   * Bereits vollständig gelesene Seiten *vor* der aktuellen Startseite werden beim erneuten Öffnen der App nicht mehr oberhalb gerendert; der Reader startet exakt bei der Seite (und Vers-Offset `delta`) des letzten Lesezeichens.
   * **Aufbau jeder Mushaf-Seite (`QuranPageView`, `paddingHorizontal: 20`, `paddingVertical: 16`):**
     * Beginnt auf dieser Seite eine neue Sure (`ayah == 1`):
       * Dekorativer **Suren-Header-Rahmen** mit kalligrafischem Surennamen in Schriftart `surah-name-v2` (`fontSize * 0.75`).
       * Darunter zentrierte **Basmala** (`بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ`), **außer** bei Sure 1 (Al-Fatiha, da dort Vers 1 selbst die Basmala ist) und Sure 9 (At-Tawbah, keine Basmala!).
     * **Blocksatz-Verskörper (`JustifiedText`):**
       * Alle Verse einer Seite (bzw. jedes Surenabschnitts auf einer Seite) fließen wie in einem echten gedruckten Mushaf ohne Zeilenumbruch zwischen den Versen hintereinander weg: `"{verse.arabic.cleanQuranText()} \u{FD3F}{arabicNumber(verse.ayah)}\u{FD3E} "`.
       * Alle Zeilen eines Absatzes sind im **arabischen Blocksatz (`justified`, RTL)** ausgerichtet; **die letzte Zeile jeder Seite/Sektion ist zentriert (`center`)**, damit kurze Schlusszeilen nicht künstlich auseinandergezogen werden!
       * **Farbe pro Vers im selben Textblock:** Jeder Vers mit `globalIndex <= readFrontier` wird sofort in **Grau (`#808080`)** gezeichnet; jeder Vers mit `globalIndex > readFrontier` in der aktiven **Theme-Textfarbe** (`#FFFFFF` / `#000000` / `#142030` / `#2C2218`).
     * **Seitenfuß:** Dezente zentrierte Seitenzahl (`13px`, `#8E8E93`) + dünne horizontale Trennlinie zur nächsten Seite.
4. **Modals & Spezialzustände im Quran-Reader:**
   * **Pinch-to-Zoom:** Zwei-Finger-Geste skaliert `quranFontSize` live zwischen `22pt` und `42pt` in `1pt`-Stufen und hält dabei den aktuell oben sichtbaren Vers verankert.
   * **Khatm-Abschluss-Karte / Modal (sobald Vers `6236` = Sure 114:6 als gelesen erfasst wird):**
     * Zeigt feierliche Gratulation (`sparkles`, `MashaAllah!`), erhöht `quranKhatmCount` um `+1` und bietet den grünen Button **„Neue Khatm beginnen“** (`start_new_khatm`), der `readFrontier = 0` und das Bookmark auf Seite 1 / Sure Al-Fatiha zurücksetzt, während alle heute/historisch gelesenen Seiten in `DailyRecord` vollständig erhalten bleiben!

---

### 3.7 Tab 4: Statistik (`StatsView`)

Scrollbare Auswertungsansicht (`Theme.background`, `padding: 16`, `spacing: 20`):

1. **Zeitraum-Umschalter (Segmented Picker oben):**
   * 2 Segmente: **„Woche“ (`week`)** und **„Monat“ (`month`, aggregiert intern die Monate des Kalenderjahres!)**.
2. **Zeitraum-Navigator (`HStack` darunter):**
   * Links Pfeil `chevron.left` (1 Woche bzw. 1 Jahr zurück, bis zum frühesten vorhandenen `DailyRecord`), Mitte Zeitraum-Label (bei Woche z. B. `„02.11. – 08.11.“`, bei Monat die Jahreszahl `„2026“`), rechts Pfeil `chevron.right` (deaktiviert in der aktuellen Woche / im aktuellen Jahr).
3. **Karte 1: Quran-Säulendiagramm (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`):**
   * Oben links: Titel `koran_sec`, Gesamtzahl gelesener Seiten im Zeitraum (`28px bold`) + Einheit `pages`.
   * Oben rechts: **Trend-Badge** im Vergleich zur Vorperiode (`+X%` in `#2E7D32` mit `arrow.up.right` oder `-X%` in `#FF9500` mit `arrow.down.right`) sowie rechts daneben (falls `quranKhatmCount > 0`) ein goldenes/grünes **Khatm-Badge** (`sparkles` + `quranKhatmCount`).
   * **Balkendiagramm (`height: 180px`):**
     * Im Modus `week`: 7 Balken (Mo–So bzw. 7 Tage der gewählten Woche), Balkenfarbe `#2E7D32` wenn `pages >= quranDailyGoal`, sonst `rgba(46,125,50,0.45)`.
     * Im Modus `month`: Balken für die Monate des gewählten Jahres (ab dem ersten Monat mit Daten bis Dezember), Balkenfarbe `#2E7D32` wenn `monthPages >= quranDailyGoal * 30`, sonst `rgba(46,125,50,0.45)`.
     * **Gestrichelte Ziellinie (`RuleMark`):** Horizontale gestrichelte Linie (`dash: [5, 5]`, `#8E8E93`) auf Höhe von `quranDailyGoal` (Woche) bzw. `quranDailyGoal * 30` (Monat) mit kleinem Ziel-Label.
4. **Karte 2: Fajr-Gebets-Auswertung (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`):**
   * Zeigt zwei gestapelte/nebeneinanderliegende Kennzahlen + Fortschrittsbalken:
     * **Frühzeitig gebetet (`onTime`):** Anzahl Tage & Prozentanteil in `#2E7D32`.
     * **Nachgebetet (`late`):** Anzahl Tage & Prozentanteil in `#FF9500`.
     * Gesamtquote `prayedDays / totalDaysInPeriod`.
5. **Karte 3: Adhkar-Kreisringe (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`):**
   * 2×2 Grid bzw. horizontale Reihe von **4 runden Fortschrittsringen** (`64×64px`):
     1. **Schlaf-Adhkar:** `schlafDoneCount / totalDaysInPeriod`
     2. **Morgen-Adhkar:** `morgenDoneCount / totalDaysInPeriod`
     3. **Abend-Adhkar:** `abendDoneCount / totalDaysInPeriod`
     4. **Sure Al-Kahf (Freitage):** `kahfDoneCount / max(1, totalFridaysInPeriod)`
   * Jeder Ring zeigt Prozentzahl in der Mitte, darunter Kategoriename und `"X / Y"`. Farbe `#2E7D32` bei `100 %`, sonst `#FF9500`.
6. **Karte 4: Tasbih-Auswertung (`Theme.cardBackground`, `borderRadius: 16`, `padding: 16`):**
   * Listet jedes aktive Standard-Tasbih und jedes aktive `CustomTasbih` untereinander auf:
     * Oben: Name links, `"Gesamtsumme / Periodenziel"` rechts (`monospacedDigit`).
     * Unten: Horizontaler Balken (`#2E7D32` ab 100 %, sonst `#FF9500`).

---

### 3.8 Einstellungen (`SettingsView`) & Alle Unterseiten

Geöffnet über das Zahnrad-Icon oben rechts in `TodayView` (`NavigationStack` im Modal-Sheet, rechts oben Button `done`):

#### Hauptmenü (`SettingsView`, gruppierte Formularliste)
1. **Sektion `settings_goals` („Ziele“):**
   * `QuranSettingsView` — Icon `book.fill` (`#2E7D32`), Titel `koran_sec`
   * `TasbihSettingsView` — Icon `circle.hexagongrid.fill` (`#2E7D32`), Titel `tasbih_sec`
   * `DhikrSettingsView` — Icon `book.closed.fill` (`#2E7D32`), Titel `adhkar_sec`
2. **Sektion `settings_general` („Allgemein“):**
   * `PrayerSettingsView` — Icon `clock.fill` (`#2E7D32`), Titel `prayer_settings_sec`
   * Toggle `dark_mode` (`settings.isDarkMode`, Default `true`)
   * Toggle `show_transliteration` (`settings.showTransliteration`, Default `true`)
   * Menü-Picker `language` (`settings.language`, 11 auswählbare UI-Sprachen: Deutsch `de`, English `en`, العربية `ar`, Français `fr`, Español `es`, اردو `ur`, Bahasa Indonesia `id`, Türkçe `tr`, Русский `ru`, বাংলা `bn`, Bahasa Melayu `ms`; ändert sofort UI + plant Benachrichtigungen in neuer Sprache neu).
3. **Sektion `settings_support_header` („Support & Hilfe“):**
   * NavigationLink `FAQView` — Icon `questionmark.circle.fill` (`#2E7D32`), Titel `faq_title`
   * Button `SupportReportView` (Sheet) — Icon `envelope.fill` (`#2E7D32`), Titel `settings_support_contact`
4. **Sektion `about_section_header` („Über ImanTrack“):**
   * Button `rate_imantrack` — Icon `star.fill` (`#2E7D32`), öffnet `https://apps.apple.com/app/id6782351643?action=write-review`
5. **Footer:** Zentrierter Text `"ImanTrack · Version 2.1.0"` (`13px`, `#8E8E93`).

#### Unterseite 1: `QuranSettingsView` + `SetQuranPositionSheet`
* **Tagesziel:** Stepper `quranDailyGoal` (`1...100` Seiten/Tag, Default `5`).
* **Darstellung (`quranTheme`):** 4 Auswahloptionen (`system`, `light` [Eisblau], `sepia`, `dark`).
* **Schriftgröße (`quranFontSize`):** Slider `22...42 pt` (Schritt `1`, Default `30`) mit Live-Vorschau eines Quran-Verses in `KFGQPCHAFSUthmanicScript-Regula`.
* **Sure Al-Baqarah Tracker:** Toggle `surahBaqarahEnabled` (Default `false`) + Ziel-Picker `surahBaqarahGoal` (`10%...100%`).
* **Aktuelle Leseposition manuell setzen (`SetQuranPositionSheet`):**
  * Ermöglicht die Auswahl einer beliebigen **Sure (`1..114`)** und **Ayah (`1..N`)** oder **Seite (`1..604`)**.
  * Nach Sicherheitsabfrage wird `readFrontier` exakt auf den Vers davor gesetzt (`targetGlobalIndex - 1`) und das `QuranBookmark` auf diesen Zielvers (`delta = 0`) geschrieben, ohne bereits gezählte Tagesstatistiken in `DailyRecord` zu löschen.

#### Unterseite 2: `TasbihSettingsView`
* **Zählmodus:** Auswahl Manuell vs. Automatisch (`settings.tasbihAutoCount`, Default `true`).
* **Haptisches Feedback:** Toggle `settings.tasbihVibrationEnabled` (Default `true`).
* **Standard-Tasbihs konfigurieren:** Für jede der 6 Kategorien ein Ein/Aus-Toggle (`<cat>Enabled`), ein numerisches Tagesziel-Feld (`<cat>Goal`), sowie:
  * Bei **Istighfar:** Multi-Auswahl, welche der 5 Istighfar-Formen aktiv sein sollen (`enabledIstighfarForms`, mindestens 1 muss aktiv bleiben).
  * Bei **Salawat:** Multi-Auswahl der 3 Salawat-Formen (`enabledSalawatForms`, mind. 1 aktiv) + optionales **Freitagsziel** (`salawatFridayGoal`, Default `0` = gleiches Ziel wie sonst, sonst z. B. `1000`).
* **Eigene Tasbihs (`CustomTasbih`):** Liste aller nutzerdefinierten Dhikrs (Toggle, Bearbeiten, Swipe-to-Delete) + Button `add_custom_dhikr` (Modal mit Pflichtfeld `title`, optional `arabic`, optional `transliteration`, numerisches `goal` Default `100`).

#### Unterseite 3: `DhikrSettingsView` (Adhkar-Einstellungen)
* **Zählmodus:** Picker zwischen Manuell (`adhkarAutoCount = false`) und Automatisch (`adhkarAutoCount = true`, Default `false`).
* **Automatisch weiterblättern:** Toggle `adhkarAutoAdvance` (Default `true`).
* **Standard-Geschwindigkeit:** 3-Stufen-Picker (`defaultAdhkarSpeedStep`: `0` = Langsam, `1` = Normal [Default], `2` = Schnell).
* **Stimme / Rezitator für den Sprachmodus (`adhkarReciter`):**
  * Auswahl zwischen `"iapetus"` (**Iapetus – Ruhige Standardstimme**, Default) und `"duraihim"` (**Scheich Hamad Al-Duraihim**), jeweils mit kleinem Play/Stop-Hörproben-Button (`morning_14.m4a` vs. `duraihim_morning_14.m4a`).
* **Adhkar-Erinnerungen (Push-Benachrichtigungen):**
  * 4 Toggles mit individuellen Zeit-Offsets:
    1. **Morgen-Adhkar Erinnerung** (`isMorningAdhkarReminderEnabled`) – Offset nach Fajr (`morningAdhkarOffsetMinutes`, Default `+15` Min).
    2. **Abend-Adhkar Erinnerung** (`isEveningAdhkarReminderEnabled`) – Offset nach Asr (`eveningAdhkarOffsetMinutes`, Default `+15` Min).
    3. **Schlaf-Adhkar Erinnerung** (`isSleepAdhkarReminderEnabled`) – feste Uhrzeit (`sleepAdhkarReminderHour`: Default `22`, `sleepAdhkarReminderMinute`: Default `0` -> `22:00` Uhr).
    4. **Sure Al-Kahf Freitags-Erinnerung** (`isKahfReminderEnabled`) – freitags feste Uhrzeit (Default `10:00` Uhr).

#### Unterseite 4: `PrayerSettingsView` + `CalculationMethodSelectionView`
* **Standort-Anzeige:** Zeigt aktuelle Koordinaten / Ort oder Button zum Aktualisieren der GPS-Position.
* **Berechnungsmethode (`calculationMethod`):** Öffnet `CalculationMethodSelectionView` mit allen **20 Berechnungsmethoden** gruppiert nach Weltregionen (siehe Tabelle in Kapitel 5.2.3; Default `"Muslim World League"`).
* **Asr-Rechtsschule (`asrJuristicMethod`):** Picker zwischen `"Standard"` (Shafi'i, Maliki, Hanbali – Schattenfaktor `1.0`, Default) und `"Hanafi"` (Schattenfaktor `2.0`).
* **Manuelle Minuten-Korrekturen (Offsets `-60` bis `+60` Min pro Gebet):** Stepper für `prayer_offset_fajr`, `prayer_offset_sunrise`, `prayer_offset_dhuhr`, `prayer_offset_asr`, `prayer_offset_maghrib` (beeinflusst auch den islamischen Tageswechsel!), `prayer_offset_isha` (alle Default `0`).
* **Gebets-Benachrichtigungen & Adhan:**
  * Haupt-Toggle Adhan/Gebetserinnerung (`prayerNotificationsEnabled`), 10-Minuten-Vorwarnung (`prayer10MinReminderEnabled`), Einzel-Toggles für Fajr, Dhuhr, Asr, Maghrib, Isha sowie Auswahl des Adhan-Tons aus den 7 gebundelten `.caf`/`.m4a`-Dateien mit Vorhör-Funktion.

#### Unterseite 5: `FAQView` & `SupportReportView`
* **`FAQView`:** Lädt `FAQ.json` für `settings.language` (Fallback `en` -> `de`), zeigt oben grünes `questionmark.circle.fill` (`44px`), Titel und Einleitung, darunter 7 Sektionen (*Erste Schritte, Der Tagesrhythmus, Quran-Tracking, Adhkar, Tasbih, Fajr-Gebet, Statistik*) mit aufklappbaren Akkordeon-Karten (`chevron.right` rotiert um `90°`).
* **`SupportReportView`:**
  * 4 Karten:
    1. Kategorie-Menü (`support_category_bug`, `support_category_feature`, `support_category_feedback`).
    2. Optionales E-Mail-Feld (`envelope`, `name@example.com`).
    3. Pflichtfeld Nachricht (`TextEditor`, Mindesthöhe `120px`).
    4. Optionaler Bildanhang (`PhotosPicker` mit `60×60` Thumbnail & Papierkorb-Button; Bild wird vor Versand auf max. `600px` Kantenlänge skaliert und als JPEG `quality 0.4 -> 0.1` auf `< 38 KB` Base64-String komprimiert!).
  * Senden schickt `POST https://api.emailjs.com/api/v1.0/email/send` mit Header `Origin: https://imantrack.app` und Body `{ service_id: "service_hgtmcvi", template_id: "template_ii1hhma", user_id: "q9-tSdMJF0IHnrSSz", template_params: { ... } }`.

---

## 4. Datenmodelle & Persistenzschema

In Swift werden **SwiftData** (SQLite-basiert, 3 eigenständige Tabellen **ohne** Fremdschlüssel-Beziehungen) sowie **UserDefaults** (Key-Value-Store) genutzt. In React Native / Expo entspricht dies 1:1 **SQLite (`expo-sqlite` / Drizzle)** + **`AsyncStorage` / `react-native-mmkv`**.

### 4.1 Modell 1: `UserSettings` (Singleton-Zeile in DB)
Es existiert immer genau **ein** Datensatz.

| Feldname | Typ | Standardwert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `quranDailyGoal` | `Int` | `5` | Tägliches Quran-Seitenziel (`1..100`) |
| `istighfarBpm` | `Int` | `60` | Legacy BPM-Fallback für Istighfar |
| `salawatBpm` | `Int` | `60` | Legacy BPM-Fallback für Salawat |
| `subhanAllahBpm` | `Int` | `60` | Legacy BPM-Fallback für SubhanAllah |
| `alhamdulillahBpm` | `Int` | `60` | Legacy BPM-Fallback für Alhamdulillah |
| `allahuAkbarBpm` | `Int` | `60` | Legacy BPM-Fallback für La hawla (`allahuAkbar`) |
| `laIlahaIllallahBpm` | `Int` | `40` | Legacy BPM-Fallback für Tahlil |
| `istighfarEnabled` | `Bool` | `true` | Istighfar in Tasbih & Statistik aktiv |
| `salawatEnabled` | `Bool` | `true` | Salawat in Tasbih & Statistik aktiv |
| `subhanAllahEnabled` | `Bool` | `true` | SubhanAllah wa bihamdihi aktiv |
| `alhamdulillahEnabled` | `Bool` | `true` | Baqiyat as-Salihat aktiv |
| `allahuAkbarEnabled` | `Bool` | `true` | La hawla wa la quwwata illa billah aktiv |
| `laIlahaIllallahEnabled` | `Bool` | `true` | La ilaha illallah wahdahu... aktiv |
| `istighfarGoal` | `Int` | `1000` | Tagesziel Istighfar |
| `salawatGoal` | `Int` | `500` | Tagesziel Salawat (Mo–Do, Sa–So) |
| `salawatFridayGoal` | `Int` | `0` | Spezielles Salawat-Ziel am islamischen Freitag (`0` = nutzt `salawatGoal`) |
| `subhanAllahGoal` | `Int` | `100` | Tagesziel SubhanAllah |
| `alhamdulillahGoal` | `Int` | `100` | Tagesziel Alhamdulillah |
| `allahuAkbarGoal` | `Int` | `100` | Tagesziel La hawla (`allahuAkbar`) |
| `laIlahaIllallahGoal` | `Int` | `100` | Tagesziel Tahlil |
| `surahBaqarahEnabled` | `Bool` | `false` | Optionaler Sure Al-Baqarah Tracker aktiv |
| `surahBaqarahGoal` | `Int` | `100` | Tagesziel Al-Baqarah in Prozent (`10..100`) |
| `enabledIstighfarForms` | `String` | `"kurz,extended,gewaltig,yunus,lang"` | Kommagetrennte Liste aktiver `IstighfarForm`-RawValues |
| `enabledSalawatForms` | `String` | `"waSallim,kurz,lang"` | Kommagetrennte Liste aktiver `SalawatForm`-RawValues |
| `istighfarForm` | `String` | `"kurz"` | Zuletzt gewählte primäre Istighfar-Form |
| `salawatForm` | `String` | `"waSallim"` | Zuletzt gewählte primäre Salawat-Form |
| `isDarkMode` | `Bool` | `true` | App-weites Dark-Mode-Flag |
| `language` | `String` | System / `"en"` | ISO-Sprachcode (`de`, `en`, `ar`, `tr`, `id`, `ms`, `fr`, `es`, `ur`, `ru`, `bn`) |
| `showTransliteration` | `Bool` | `true` | Lateinische Umschrift unter arabischen Texten anzeigen |
| `adhkarAutoCount` | `Bool` | `false` | Automatischer Timer-Zählmodus in Adhkar aktiv |
| `adhkarAutoAdvance` | `Bool` | `true` | Nach Abschluss eines Adhkar-Items automatisch zum nächsten springen |
| `adhkarVoiceEnabled` | `Bool` | `false` | Globaler Default für Sprachmodus |
| `adhkarReciter` | `String` | `"iapetus"` | Gewählter Adhkar-Rezitator (`"iapetus"` oder `"duraihim"`) |
| `defaultAdhkarSpeedStep` | `Int` | `1` | Globale Standard-Geschwindigkeit für Adhkar (`0`=Langsam, `1`=Normal, `2`=Schnell) |
| `tasbihAutoCount` | `Bool` | `true` | Freihand-Auto-Counter im Tasbih aktiv |
| `tasbihVibrationEnabled` | `Bool` | `true` | Haptisches Feedback bei jedem Tasbih-Zählschritt |
| `showTajweedHarakat` | `Bool` | `true` | Harakat/Tajweed-Zeichen aktiv |
| `calculationMethod` | `String` | `"Muslim World League"` | Gewählte Gebetszeiten-Berechnungsmethode (1 aus 20) |
| `asrJuristicMethod` | `String` | `"Standard"` | `"Standard"` (Faktor 1.0) oder `"Hanafi"` (Faktor 2.0) |
| `prayerNotificationsEnabled`| `Bool` | `false` | Gebetsbenachrichtigungen global ein/aus |
| `prayer10MinReminderEnabled`| `Bool` | `false` | Vorab-Erinnerung 10 Minuten vor Gebetsbeginn |
| `selectedAdhanSound` | `String` | `"azan.caf"` | Dateiname des gewählten Adhan-Tons |
| `fajrNotificationEnabled` | `Bool` | `true` | Einzel-Toggle Fajr-Mitteilung |
| `dhuhrNotificationEnabled` | `Bool` | `true` | Einzel-Toggle Dhuhr-Mitteilung |
| `asrNotificationEnabled` | `Bool` | `true` | Einzel-Toggle Asr-Mitteilung |
| `maghribNotificationEnabled`| `Bool` | `true` | Einzel-Toggle Maghrib-Mitteilung |
| `ishaNotificationEnabled` | `Bool` | `true` | Einzel-Toggle Isha-Mitteilung |

---

### 4.2 Modell 2: `DailyRecord` (1 Datensatz pro islamischem Tag)
Eindeutiger Primärschlüssel ist `dateString` im Format `"yyyy-MM-dd"` bezogen auf `LocationAndSolarManager.currentTrackingDate`!

| Feldname | Typ | Standardwert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `dateString` (`@Unique`) | `String` | `"yyyy-MM-dd"` | Eindeutiger Tagesschlüssel des islamischen Tracking-Tages |
| `date` | `Date` | `startOfDay` | Mitternachts-Zeitstempel des `trackingDate` für Bereichsabfragen |
| `fajrPrayed` | `Bool` | `false` | Legacy-Flag (wird synchron mit `fajrStatus != "none"` gehalten) |
| `fajrStatus` | `String` | `"none"` | `"none"` \| `"onTime"` (vor Shuruq) \| `"late"` (nach Shuruq / Qada) |
| `fajrPrayedTime` | `Date?` | `null` | Zeitpunkt der Fajr-Eintragung |
| `quranPagesRead` | `Int` | `0` | Heute abgeschlossene Mushaf-Seiten |
| `quranVersesRead` | `Int` | `0` | Heute neu gelesene Quran-Verse |
| `quranCurrentSurah` | `Int` | `1` | Zuletzt gelesene Sure an diesem Tag |
| `quranCurrentAyah` | `Int` | `1` | Zuletzt gelesene Ayah an diesem Tag |
| `morgenAdhkarDone` | `Bool` | `false` | Morgen-Adhkar vollständig erledigt |
| `morgenAdhkarTime` | `Date?` | `null` | Abschlusszeitpunkt Morgen-Adhkar |
| `abendAdhkarDone` | `Bool` | `false` | Abend-Adhkar vollständig erledigt |
| `abendAdhkarTime` | `Date?` | `null` | Abschlusszeitpunkt Abend-Adhkar |
| `schlafAdhkarDone` | `Bool` | `false` | Schlaf-Adhkar vollständig erledigt |
| `schlafAdhkarTime` | `Date?` | `null` | Abschlusszeitpunkt Schlaf-Adhkar |
| `surahAlKahfDone` | `Bool` | `false` | Sure Al-Kahf (am Freitag) gelesen |
| `surahAlKahfTime` | `Date?` | `null` | Abschlusszeitpunkt Sure Al-Kahf |
| `surahBaqarahProgress` | `Int` | `0` | Fortschritt Sure Al-Baqarah in Prozent (`0..100`) |
| `surahBaqarahTime` | `Date?` | `null` | Abschlusszeitpunkt Sure Al-Baqarah |
| `istighfarCount` | `Int` | `0` | Heutiger Zählerstand Istighfar |
| `salawatCount` | `Int` | `0` | Heutiger Zählerstand Salawat |
| `subhanAllahCount` | `Int` | `0` | Heutiger Zählerstand SubhanAllah |
| `alhamdulillahCount` | `Int` | `0` | Heutiger Zählerstand Alhamdulillah |
| `allahuAkbarCount` | `Int` | `0` | Heutiger Zählerstand **La hawla wa la quwwata illa billah** |
| `laIlahaIllallahCount` | `Int` | `0` | Heutiger Zählerstand La ilaha illallah |
| `adhkarProgressJSON` | `String` | `"{}"` | JSON-kodiertes Dictionary `[String: Int]` (`safeKey -> aktueller Zählerstand` pro Adhkar-Item) |
| `customTasbihCountsJSON` | `String` | `"{}"` | JSON-kodiertes Dictionary `[String: Int]` (`CustomTasbih.id -> heutiger Zählerstand`) |
| `adhkarSnapshotsJSON` | `String` | `"{}"` | JSON-kodiertes Dictionary `[String: AdhkarCompletionSnapshot]` für die Rückgängig-Funktion beim Einmal-Abhaken |

#### Eingebettete Struktur `AdhkarCompletionSnapshot` (Codable in `adhkarSnapshotsJSON`)
```ts
interface AdhkarCompletionSnapshot {
  wasDone: boolean;
  previousTime: string | null; // ISO Date
  itemCounts: Record<string, number>; // Vorherige Einzelzähler der Kategorie
  istighfarCount: number;
  salawatCount: number;
  subhanAllahCount: number;
  alhamdulillahCount: number;
  allahuAkbarCount: number;
  laIlahaIllallahCount: number;
}
```

---

### 4.3 Modell 3: `CustomTasbih` (Nutzerdefinierte Tasbih-Einträge)
| Feldname | Typ | Standardwert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `id` (`@Unique`) | `String` | `UUID()` | Stabile UUID als String |
| `title` | `String` | *(Pflicht)* | Anzeigename des eigenen Dhikrs |
| `arabic` | `String` | `""` | Optionaler arabischer Text |
| `transliteration` | `String` | `""` | Optionale lateinische Umschrift |
| `goal` | `Int` | `100` | Individuelles Tagesziel |
| `isEnabled` | `Bool` | `true` | Aktiviert in `TasbihView` und `StatsView` |
| `createdAt` | `Date` | `new Date()` | Erstellungsdatum für stabile Sortierung |

---

### 4.4 Codable-Hilfsmodelle (`QuranBookmark`, `Verse`, `APIVerse`)

```ts
// Gespeichert als JSON-String unter Key "quranFrontierBookmark_v1"
interface QuranBookmark {
  surah: number;      // 1..114
  ayah: number;       // 1..286
  page: number;       // 1..604
  delta: number;      // Vertikaler Offset in Pixeln relativ zur Vers-Oberkante
  fontSize: number;   // Schriftgröße (22..42) zum Zeitpunkt der Speicherung
  savedAt: number;    // Unix-Timestamp
}

// In-Memory-Modell eines Quran-Verses nach Laden aus quran_offline.json
interface Verse {
  id: number;           // 1..6236 (entspricht globalIndex)
  surah: number;        // 1..114 (geparst aus verse_key "S:A")
  ayah: number;         // Versnummer innerhalb der Sure
  arabic: string;       // text_qpc_hafs (für visuelles Rendering!)
  textUthmani: string;  // text_uthmani (für Suche/Vergleich ohne QPC-Sondercodes)
  pageNumber: number;   // 1..604
  juzNumber: number;    // 1..30
  isLastVerseOfPage: boolean; // Vorberechnet beim Laden: nächster Vers hat höhere pageNumber (oder Vers 6236)
}
```

---

### 4.5 Vollständige Tabelle aller Key-Value-Einträge (`UserDefaults` / `AsyncStorage`)

| Schlüsselname (`Key`) | Typ | Default | Zweck |
| :--- | :--- | :--- | :--- |
| `hasSeenOnboarding` | `Bool` | `false` | Steuert Anzeige von `OnboardingView` beim Start |
| `quranMigrationV2_completed` | `Bool` | `false` | Einmaliges Migrations-Flag für historische Seitenzahlen |
| `last_latitude` | `Double` | `0.0` | Zuletzt ermittelter Breitengrad (`0.0` = noch kein Fix) |
| `last_longitude` | `Double` | `0.0` | Zuletzt ermittelter Längengrad (`0.0` = noch kein Fix) |
| `last_five_min_warning_day` | `String` | `""` | Verhindert doppeltes Auslösen des 5-Minuten-Maghrib-Banners am selben Tag |
| `quranReadFrontier` | `Int` | `0` | Globaler Index (`0..6236`) des letzten vollständig gelesenen Quran-Verses in der laufenden Khatm |
| `quranFrontierBookmark_v1` | `JSON` | `null` | Serialisiertes `QuranBookmark` für pixelgenaue Wiederherstellung |
| `quranKhatmCount` | `Int` | `0` | Anzahl vollständig abgeschlossener Khatms |
| `quranFontSize` | `Double` | `30.0` | Aktuelle Quran-Schriftgröße (`22.0 .. 42.0`) |
| `quranTheme` | `String` | `"system"` | `"system"` \| `"light"` \| `"sepia"` \| `"dark"` |
| `quranFontType` | `String` | `"uthmanic"` | Immer `"uthmanic"` (`UthmanicHafs1Ver18.ttf`) |
| `tasbih_speed_<id>` | `Int` | `1` | Tempo-Stufe (`0`, `1`, `2`) pro Dhikr/Form (`istighfar_kurz`, `<customUUID>` usw.) |
| `adhkar_<30alnum>_mandatory` | `Bool` | `true` | Pflicht/Optional-Status pro Adhkar-Karte (`30` alphanumerische Zeichen aus `item.german`) |
| `adhkar_<30alnum>_speed` | `Int` | `defaultAdhkarSpeedStep` | Individuelle Tempo-Stufe (`0`, `1`, `2`) pro Adhkar-Karte |
| `adhkar_custom_order_<type>` | `[String]` | `[]` | Nutzerdefinierte Sortierreihenfolge für `sleep`, `morning`, `evening` |
| `adhkarReciter` | `String` | `"iapetus"` | `"iapetus"` oder `"duraihim"` |
| `defaultAdhkarSpeedStep` | `Int` | `1` | Standard-Adhkar-Tempo (`0..2`) |
| `prayer_offset_fajr` | `Int` | `0` | Manuelle Minutenkorrektur Fajr (`-60..+60`) |
| `prayer_offset_sunrise` | `Int` | `0` | Manuelle Minutenkorrektur Shuruq (`-60..+60`) |
| `prayer_offset_dhuhr` | `Int` | `0` | Manuelle Minutenkorrektur Dhuhr (`-60..+60`) |
| `prayer_offset_asr` | `Int` | `0` | Manuelle Minutenkorrektur Asr (`-60..+60`) |
| `prayer_offset_maghrib` | `Int` | `0` | Manuelle Minutenkorrektur Maghrib (`-60..+60`, verschiebt auch den Tageswechsel!) |
| `prayer_offset_isha` | `Int` | `0` | Manuelle Minutenkorrektur Isha (`-60..+60`) |
| `isMorningAdhkarReminderEnabled` | `Bool` | `false` | Morgen-Adhkar Push aktiv |
| `morningAdhkarOffsetMinutes` | `Int` | `15` | Minuten nach Fajr für Morgen-Adhkar Push |
| `isEveningAdhkarReminderEnabled` | `Bool` | `false` | Abend-Adhkar Push aktiv |
| `eveningAdhkarOffsetMinutes` | `Int` | `15` | Minuten nach Asr für Abend-Adhkar Push |
| `isSleepAdhkarReminderEnabled` | `Bool` | `false` | Schlaf-Adhkar Push aktiv |
| `sleepAdhkarReminderHour` | `Int` | `22` | Stunde für Schlaf-Adhkar Push |
| `sleepAdhkarReminderMinute` | `Int` | `0` | Minute für Schlaf-Adhkar Push |
| `isKahfReminderEnabled` | `Bool` | `false` | Freitags-Push für Sure Al-Kahf aktiv |
| `hasPromptedNotificationPermissionAfterFirstSession` | `Bool` | `false` | Einmal-Prompt nach erster beendeter Adhkar-Session bereits gezeigt |
| `emailjs_service_id` | `String` | `"service_hgtmcvi"` | EmailJS Service-ID für Support-Formular |
| `emailjs_template_id` | `String` | `"template_ii1hhma"` | EmailJS Template-ID |
| `emailjs_public_key` | `String` | `"q9-tSdMJF0IHnrSSz"` | EmailJS Public Key |

---

## 5. Gesamte Geschäftslogik & Algorithmen im Detail

### 5.1 Islamischer Tageswechsel ab Maghrib & Verhalten ohne Standort

#### 5.1.1 Bestimmung des aktiven Tracking-Tages (`currentTrackingDate`)
ImanTrack speichert den täglichen Fortschritt (`DailyRecord`) nicht nach bürgerlicher Mitternacht, sondern nach dem **islamischen Kalendertag**, der mit dem Sonnenuntergang (**Maghrib**) beginnt:

1. **Mit Standortberechtigung (`hasLocationPermission == true` und gültige Koordinaten vorhanden):**
   * Berechne den astronomischen Sonnenuntergang des heutigen bürgerlichen Kalendertages `today` und addiere das manuelle Offset:
     `effectiveSunset = calculateSunset(today, lat, lon) + prayer_offset_maghrib * 60s`.
   * **Vergleich:**
     * Wenn `now >= effectiveSunset`: Der neue islamische Tag hat bereits begonnen!
       `trackingDate = startOfDay(now) + 1 Kalendertag` (Beispiel: Donnerstag 18:15 Uhr nach Maghrib -> `trackingDate` ist `"2026-11-06"` = **Freitag**!).
     * Wenn `now < effectiveSunset`:
       `trackingDate = startOfDay(now)`.
2. **Ohne Standortberechtigung (Konzept lt. FAQ & UI-Anzeige vs. technischer Fallback):**
   * Ist keine Standortberechtigung erteilt (`authorizationStatus` nicht `authorizedWhenInUse`/`authorizedAlways`), blendet `TodayView` den Gebetszeiten-Block komplett aus (`canCalculatePrayerTimes == false`), zeigt den Standort-Aktivierungsbutton und setzt `isNightTime = false` (keine `"Nacht zum ..."`-Anzeige).
   * Für den **sauberen Nachbau in React Native** gilt gemäß Produktdefinition (`FAQ.json`): Solange kein Standort freigegeben ist und keine gecachten Koordinaten (`last_latitude == 0 && last_longitude == 0`) vorliegen, wechselt `trackingDate` exakt um **00:00 Uhr Mitternacht** (`trackingDate = startOfDay(now)`). Sobald Standortzugriff erlaubt wird, wechselt der Tag ab sofort bei `effectiveSunset`, wobei bereits gespeicherte `DailyRecord`-Einträge unangetastet bleiben (Hinweis: Im Swift-Code existiert zusätzlich ein interner Koordinaten-Fallback auf Düsseldorf `51.2217° N, 6.7762° E` bzw. `18:30` Uhr bei Polarnacht für interne Solar-Hilfsfunktionen).

#### 5.1.2 Sekündlicher Maghrib-Übergangs-Automat
Ein `1.0s`-Intervall-Timer prüft kontinuierlich `diff = effectiveSunset.getTime() - now.getTime()` (in Sekunden):
* **`60 < diff <= 300` (5 Minuten vor Maghrib):**
  * Falls `last_five_min_warning_day !== todayDateString`:
    * Setze `last_five_min_warning_day = todayDateString`.
    * Spiele Haptik `NotificationFeedbackType.Warning`.
    * Zeige `showFiveMinuteWarning = true` für `7.0` Sekunden.
* **`0 < diff <= 60` (Letzte 60 Sekunden vor Maghrib):**
  * Setze `maghribCountdownSeconds = Math.ceil(diff)` (`60` herunter bis `1`).
  * Zeige das pulsierende `MaghribCountdownBanner` mit Fortschrittsbalken `diff / 60`.
* **`-3.5 < diff <= 0` (Exakter Maghrib-Moment / Tageswechsel!):**
  * `maghribCountdownSeconds = null`.
  * Aktualisiere `currentTrackingDate` auf den neuen Tag (`+1 Tag`).
  * Flush des Quran-Puffers (`QuranProgressStore.flushIfNeeded()`) noch vor dem Wechsel bzw. nahtloser Übergang auf den neuen `DailyRecord`.
  * Sende globales Event `MaghribDayResetTriggered`:
    * Laufender Tasbih-Auto-Counter in `DhikrDetailView` stoppt sofort (`pauseTimer()`), setzt `sessionCount = 0` und blendet einen Hinweis-Toast (`reset_msg`) ein.
    * Spiele Haptik `NotificationFeedbackType.Success`.
    * Zeige `MaghribDayResetToast` (`showDayResetToast = true`) für `4.5` Sekunden.

#### 5.1.3 Anzeige „Nacht zum <Wochentag>“ (`IslamicDateHelper.nightTitle`)
Zwischen `effectiveSunset` (Abend) und `effectiveFajr` (Morgendämmerung) befindet sich der Nutzer in der **Nacht zum neuen Wochentag**:
* `isNightTime == true`, wenn Standort aktiv UND (`now >= todayEffectiveSunset` ODER `now < todayEffectiveFajr`).
* In diesem Zeitraum zeigt `TodayView` als Haupttitel nicht bloß `"Freitag"`, sondern lokalisiert `"Nacht zum Freitag"` (`night_to_weekday`), inklusive sprachspezifischer Grammatikregeln (z. B. im Russischen Akkusativ für weibliche Wochentage среда -> среду, пятница -> пятницу, суббота -> субботу; im Französischen `"Nuit du vendredi"`; im Arabischen `"ليلة الجمعة"`). Ab `now >= effectiveFajr` springt der Titel auf den normalen Wochentagsnamen (`"Freitag"` / `"الجمعة"`).

---

### 5.2 Astronomische Gebetszeiten-Berechnung (NOAA-Algorithmus)

Alle Gebetszeiten werden zu 100 % offline anhand der **NOAA Solar Equations** berechnet (`LocationAndSolarManager.swift`).

#### 5.2.1 Grundgleichungen (für Kalendertag $d$, Breitengrad $\phi$ in Grad, Längengrad $\lambda$ in Grad, lokale Zeitzonen-Differenz $Z$ in Stunden zu UTC)

1. **Tag des Jahres ($N$):** $1 \dots 365/366$.
2. **Gebrochenes Jahr ($\gamma$, in Radiant):**
   $$\gamma = \frac{2\pi}{365} \cdot (N - 1 + \frac{12 - 12}{24}) = \frac{2\pi}{365} \cdot (N - 1)$$
3. **Zeitgleichung ($\text{eqtime}$, in Minuten):**
   $$\text{eqtime} = 229.18 \cdot \big(0.000075 + 0.001868\cos\gamma - 0.032077\sin\gamma - 0.014615\cos(2\gamma) - 0.040849\sin(2\gamma)\big)$$
4. **Sonnendeklination ($\delta$, in Radiant):**
   $$\delta = 0.006918 - 0.399912\cos\gamma + 0.070257\sin\gamma - 0.006758\cos(2\gamma) + 0.000907\sin(2\gamma) - 0.002697\cos(3\gamma) + 0.00148\sin(3\gamma)$$
5. **Stundenwinkel $H(z)$ (in Grad) für einen gegebenen Zenitwinkel $z$ (in Grad):**
   $$\cos H = \frac{\cos(z \cdot \frac{\pi}{180})}{\cos(\phi \cdot \frac{\pi}{180}) \cdot \cos\delta} - \tan(\phi \cdot \frac{\pi}{180}) \cdot \tan\delta$$
   * Ist $|\cos H| > 1$, erreicht die Sonne diesen Winkel in hohen Breitengraden nicht (siehe High-Latitude-Regel in 5.2.2!).
   * Sonst: $H = \arccos(\cos H) \cdot \frac{180}{\pi}$.

#### 5.2.2 Berechnung der 6 Tageszeiten + Manuelle Offsets

* **Sonnenmittag (Dhuhr, in UTC-Minuten ab 00:00):**
  $$T_{\text{noon,UTC}} = 720 - 4\lambda - \text{eqtime}$$
  Lokale Uhrzeit in Minuten ab Mitternacht: $T_{\text{dhuhr}} = T_{\text{noon,UTC}} + 60 \cdot Z$ (äquivalent zum Mittelwert aus Sonnenaufgang und Sonnenuntergang).
* **Sonnenaufgang (Shuruq) & Sonnenuntergang (Maghrib):**
  Verwendet Standard-Refraktions-Zenit $z_0 = 90.833^\circ$:
  $$T_{\text{sunrise,UTC}} = 720 - 4(\lambda + H(90.833^\circ)) - \text{eqtime}$$
  $$T_{\text{sunset,UTC}} = 720 - 4(\lambda - H(90.833^\circ)) - \text{eqtime}$$
* **Asr-Gebet (Standard vs. Hanafi):**
  Schattenlängenfaktor $f = 1.0$ für `"Standard"` (Shafi'i, Maliki, Hanbali) bzw. $f = 2.0$ für `"Hanafi"`:
  $$\cot A = f + \tan\big(|\phi \cdot \frac{\pi}{180} - \delta|\big)$$
  Sonnenhöhe $A = \arctan\left(\frac{1}{\cot A}\right) \cdot \frac{180}{\pi}$, daraus Zenitwinkel $z_{\text{asr}} = 90^\circ - A$:
  $$T_{\text{asr,UTC}} = 720 - 4(\lambda - H(z_{\text{asr}})) - \text{eqtime}$$
* **Fajr-Gebet (mit Dämmerungswinkel $\alpha_{\text{fajr}}$ & Hochbreiten-Schutz):**
  Zenitwinkel $z_{\text{fajr}} = 90^\circ + \alpha_{\text{fajr}}$.
  * **Nachtdauer:** $\text{nightDuration} = (T_{\text{sunrise}} + 24\text{h}) - T_{\text{sunset,Vortag}}$.
  * **30-%-Nachtlimit (High-Latitude-Fallback für Mitteleuropa im Sommer):** $\text{twilightLimit} = 0.30 \cdot \text{nightDuration}$.
  * Ist $|\cos H(z_{\text{fajr}})| > 1$ **oder** liegt die astronomische Fajr-Zeit weiter vor Sonnenaufgang als $\text{twilightLimit}$, wird gedeckelt auf:
    $$T_{\text{fajr}} = T_{\text{sunrise}} - 0.30 \cdot \text{nightDuration}$$
* **Isha-Gebet (Winkel $\alpha_{\text{isha}}$ ODER festes Minuten-Intervall):**
  * Hat die gewählte Methode ein festes Intervall (z. B. Umm al-Qura / Katar `+90 min`):
    $$T_{\text{isha}} = T_{\text{sunset}} + \text{intervalMinutes}$$
  * Sonst mit Zenitwinkel $z_{\text{isha}} = 90^\circ + \alpha_{\text{isha}}$:
    * Ist $|\cos H(z_{\text{isha}})| > 1$, oder gilt $|\phi| > 50^\circ$ und $(T_{\text{isha}} - T_{\text{sunset}}) > 0.30 \cdot \text{nightDuration}$, wird gedeckelt auf:
      $$T_{\text{isha}} = T_{\text{sunset}} + 0.30 \cdot \text{nightDuration}$$
* **Anwendung der manuellen Minuten-Offsets (`-60..+60`):**
  Zu jeder der 6 berechneten Zeiten wird abschließend `prayer_offset_<name> * 60s` addiert.

#### 5.2.3 Vollständige Tabelle aller 20 Berechnungsmethoden (`CalculationMethod`)

| Gespeicherter String (`rawValue`) | Region / Organisation | Fajr-Winkel ($\alpha_{\text{fajr}}$) | Isha-Winkel ($\alpha_{\text{isha}}$) | Festes Isha-Intervall |
| :--- | :--- | :---: | :---: | :---: |
| `"Muslim World League"` *(Default)* | Weltweit / Europa (MWL) | `18.0°` | `17.0°` | — |
| `"Umm al-Qura"` | Saudi-Arabien (Mekka) | `18.5°` | — | `+90 Min` nach Maghrib |
| `"Egyptian General Authority"` | Ägypten / Afrika | `19.5°` | `17.5°` | — |
| `"University of Islamic Sciences, Karachi"` | Pakistan / Südasien | `18.0°` | `18.0°` | — |
| `"UAE / Dubai"` | Vereinigte Arabische Emirate | `18.2°` | `18.2°` *(bzw. `18.0°`)* | — |
| `"Kuwait"` | Kuwait | `18.0°` | `17.5°` | — |
| `"Qatar"` | Katar | `18.0°` | — | `+90 Min` nach Maghrib |
| `"Diyanet (Turkey)"` | Türkei / DITIB Deutschland | `18.0°` | `17.0°` | — |
| `"MUIS (Singapore)"` | Singapur | `20.0°` | `18.0°` | — |
| `"JAKIM (Malaysia)"` | Malaysia | `20.0°` | `18.0°` | — |
| `"KEMENAG (Indonesia)"` | Indonesien | `20.0°` | `18.0°` | — |
| `"Morocco"` | Marokko | `19.0°` | `17.0°` | — |
| `"Tunisia"` | Tunesien | `18.0°` | `18.0°` | — |
| `"Algeria"` | Algerien | `18.0°` | `17.0°` | — |
| `"ISNA (North America)"` | Nordamerika | `15.0°` | `15.0°` | — |
| `"Moonsighting Committee"` | Weltweit / UK | `18.0°` | `18.0°` | — |
| `"France (18°)"` | Frankreich (18°) | `18.0°` | `18.0°` | — |
| `"France (15°)"` | Frankreich (15°) | `15.0°` | `15.0°` | — |
| `"UOIF (France 12°)"` | Frankreich (Musulmans de France) | `12.0°` | `12.0°` | — |
| `"Institute of Geophysics, Tehran"` | Iran | `17.7°` | `14.0°` | — |

#### 5.2.4 Live-Countdown-Berechnung (`resolveNextPrayer`)
* In der kompakten Gebetszeile werden alle **6 Tageszeiten** `[Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha]` angezeigt.
* Für den großen Live-Countdown (`resolveNextPrayer`) werden gezielt die **5 Pflichtgebete** `[Fajr, Dhuhr, Asr, Maghrib, Isha]` geprüft (Shuruq wird beim Countdown übersprungen):
  * Das nächste Gebet ist das erste Element dieser 5er-Liste mit `time > now`.
  * Sind heute bereits alle 5 Gebete vorbei (`now >= Isha`), ist das nächste Ziel **Fajr von morgen** (`tomorrowFajr`).
  * Der Countdown wird jede Sekunde aktualisiert: `hours = floor(diff/3600)`, `mins = floor((diff%3600)/60)`, `secs = floor(diff%60)`, formatiert als `HH:MM:SS`.

---

### 5.3 Hijri-Datum (`IslamicDateHelper`)
* Verwendet den **Umm-al-Qura-Kalender** (`Intl.DateTimeFormat('en-u-ca-islamic-umalqura', { day: 'numeric', month: 'numeric', year: 'numeric' })`) mit `trackingDate` als Eingabedatum! Da `trackingDate` bereits ab Maghrib um `+1 Tag` weiterspringt, springt auch das islamische Hijri-Datum automatisch exakt bei Sonnenuntergang auf den nächsten Tag um.
* Die 12 islamischen Monatsnamen:
  1. Muharram (`محرم`)
  2. Safar (`صفر`)
  3. Rabi' al-Awwal (`ربيع الأول`)
  4. Rabi' ath-Thani (`ربيع الثاني`)
  5. Jumada al-Ula (`جمادى الأولى`)
  6. Jumada al-Akhirah (`جمادى الآخرة`)
  7. Rajab (`رجب`)
  8. Sha'ban (`شعبان`)
  9. Ramadan (`رمضان`)
  10. Shawwal (`شوال`)
  11. Dhu l-Qa'da (`ذو القعدة`)
  12. Dhu l-Hijja (`ذو الحجة`)

---

### 5.4 Adhkar-Logik im Detail

#### 5.4.1 Automatischer Zustands-Wechsel (`AdhkarState`: `future` | `active` | `expired`)
Alle Zeitgrenzen werden relativ zum aktuellen islamischen `trackingDate` berechnet (`prevDay = trackingDate - 1 Kalendertag`):

| Kategorie | Zustand `future` (gesperrt, `opacity: 0.6`) | Zustand `active` (reguläres Zählen & Audio aktiv) | Zustand `expired` (nur Nachholen per Einmal-Abhaken) |
| :--- | :--- | :--- | :--- |
| **Schlaf-Adhkar (`sleep`)** | *(nie `future`, da Tag mit Maghrib startet)* | `maghrib(prevDay) <= now < 01:00 Uhr(trackingDate)` | `01:00 Uhr(trackingDate) <= now < maghrib(trackingDate)` |
| **Fajr-Karte (`fajr`)** | `now < fajr(trackingDate)` | `fajr(trackingDate) <= now < dhuhr(trackingDate)` *(vor Shuruq = pünktlich)* | `now >= dhuhr(trackingDate)` *(Qada möglich bis Maghrib)* |
| **Morgen-Adhkar (`morning`)** | `now < fajr(trackingDate)` | `fajr(trackingDate) <= now < dhuhr(trackingDate)` | `dhuhr(trackingDate) <= now < maghrib(trackingDate)` |
| **Abend-Adhkar (`evening`)** | `now < asr(trackingDate)` | `asr(trackingDate) <= now < maghrib(trackingDate)` | *(ab `maghrib(trackingDate)` startet sofort der neue Tag!)* |
| **Sure Al-Kahf** | Unsichtbar vor `fajr(Freitag)` und an Nicht-Freitagen | Sichtbar & aktiv wenn `weekday(trackingDate) == Freitag` UND `now >= fajr(trackingDate)` bis `maghrib(trackingDate)` | — |

#### 5.4.2 Stabiler Persistenz-Schlüssel pro Adhkar-Karte (`safeKey`)
Damit Zählerstände in `DailyRecord.adhkarProgressJSON` sprachunabhängig stabil bleiben:
```ts
function safeAdhkarKey(typeId: 'morning' | 'evening' | 'sleep', item: AdhkarItem): string {
  const germanClean = item.german.replace(/[^a-zA-Z0-9]/g, '');
  const transClean = item.transliteration.replace(/[^a-zA-Z0-9]/g, '');
  const combined = (germanClean + transClean).slice(0, 60);
  return `${typeId}_${item.count}_${combined}`;
}
```
Für Pflicht/Optional und individuelles Tempo in `AsyncStorage`:
```ts
const prefix = 'adhkar_' + item.german.slice(0, 30).replace(/[^a-zA-Z0-9]/g, '');
// Keys: `${prefix}_mandatory` (boolean), `${prefix}_speed` (0 | 1 | 2)
```
Für die nutzerdefinierte Sortierung (`adhkar_custom_order_<typeId>`):
```ts
const orderKey = `${item.count}_${(germanClean + transClean).slice(0, 40)}`;
```

#### 5.4.3 Auto-Count-Intervallberechnung & Auto-Advance
* Jedes `AdhkarItem` besitzt optionale gemessene Sprechdauern `slowInterval`, `normalInterval`, `quickInterval` (in Sekunden, Fallback `defaultInterval = 2.0s`):
  * Stufe `0` (Langsam): `item.slowInterval ?? (normalVal * 1.184)`
  * Stufe `1` (Normal): `item.normalInterval ?? 2.0`
  * Stufe `2` (Schnell): `item.quickInterval ?? (normalVal * 0.816)`
* **Tasbih-Gutschrift (`linkedTasbihCategory`):** Bei **jedem einzelnen Zählschritt** eines Adhkar-Items mit gesetzter `linkedTasbihCategory` (sowie anteilig für noch fehlende Wiederholungen beim Einmal-Abhaken!) wird der entsprechende Tageszähler in `DailyRecord` (`istighfarCount`, `salawatCount`, `laIlahaIllallahCount`) automatisch um `+1` (bzw. `+diff`) miterhöht!
* **Auto-Advance:** Erreicht ein Item `next == item.count`, erscheint `1.0s` lang `MashaAllah!`. Danach scrollt die Liste automatisch zentriert zum nächsten noch offenen Pflicht-Item (`!completed && isMandatory`). Sind `adhkarAutoCount && adhkarAutoAdvance` aktiv, startet nach weiteren `0.6s` automatisch der Timer des nächsten Items (bzw. im Voice-Mode die nächste Audio-Datei!).

#### 5.4.4 Voice-Mode (Sprachmodus) & Audio-Äquivalenz-Auflösung
* `AVAudioSession` / Expo Audio läuft im Modus `spokenAudio` mit `duckOthers` und aktiviertem `KeepAwake`.
* Hat ein `AdhkarItem` in den Stammdaten `audioFileName == nil`, weist `AdhkarSessionView` beim Initialisieren automatisch `"${typeId}_${index + 1}"` zu (1-basiert nach Originalreihenfolge, z. B. `"morning_5"`, `"evening_5"`, `"sleep_4"`).
* **Auflösungs-Reihenfolge der `.m4a`-Datei für Rezitator `"duraihim"` vs. `"iapetus"`:**
  1. Ist `adhkarReciter === "duraihim"`, suche zuerst `duraihim_<fileName>.m4a`, dann `duraihim_<equivalent>.m4a`, dann Fallback auf `<fileName>.m4a` bzw. `<equivalent>.m4a`.
  2. Ist `adhkarReciter === "iapetus"`, suche zuerst `<fileName>.m4a`, dann `<equivalent>.m4a`, dann Fallback auf `duraihim_<fileName>.m4a`.
* **`equivalentAudioMap` (Teilung identischer Aufnahmen zwischen Morgen/Abend/Schlaf):**
  ```json
  {
    "evening_1": "quran_ayat_kursi",
    "evening_2": "quran_ikhlas",
    "evening_3": "quran_falaq",
    "evening_4": "quran_nas",
    "evening_7": "morning_7",
    "evening_10": "morning_10",
    "evening_11": "morning_11",
    "evening_12": "morning_12",
    "evening_13": "morning_13",
    "evening_14": "morning_14",
    "evening_15": "morning_15",
    "evening_16": "morning_16",
    "evening_19": "morning_19",
    "evening_20": "morning_20",
    "evening_21": "morning_23",
    "evening_22": "morning_24",
    "evening_23": "morning_25",
    "sleep_2": "quran_ayat_kursi",
    "sleep_3": "quran_baqarah_last2",
    "sleep_12": "quran_mulk"
  }
  ```
* Ist für ein Item (z. B. Sure Al-Mulk falls keine Audio-Datei gewählt oder fehlend) kein Audio vorhanden, öffnet Al-Mulk den `AlMulkReaderView`, alle anderen fallen sauber auf den Auto-Count-Timer zurück.
* Wiederholungen im Voice-Mode: Ist `item.count > 1` (z. B. `3×` Al-Ikhlas oder `100×` Subhanallahi wa bihamdihi), spielt der Player die `.m4a`-Datei in einer Schleife genau `(item.count - startRepetition)`-mal ab und zählt nach jedem Durchlauf `+1` hoch.

#### 5.4.5 Einmal-Abhaken & Verlustfreie Rückgängig-Funktion (`Snapshot` & `Undo`)
* **`markAllAdhkarCompleted(type)`:**
  1. Erzeugt einen `AdhkarCompletionSnapshot` mit dem aktuellen `Done`-Flag, der bisherigen Abschlusszeit, einer Kopie aller bisherigen Einzel-Zähler dieser Kategorie (`itemCounts`) sowie den exakten Ständen aller 6 Tasbih-Zähler.
  2. Für jedes Pflicht-Item (`isMandatory == true`) der Kategorie wird die noch fehlende Differenz `diff = max(0, item.count - currentItemCount)` ermittelt, der Item-Zähler auf `item.count` gesetzt und ggf. `linkedTasbihCategory` um `+diff` erhöht.
  3. Setzt `<type>AdhkarDone = true` und `<type>AdhkarTime = now` und speichert den Snapshot in `adhkarSnapshotsJSON[typeId]`.
* **`markAdhkarUncompleted(type)`:**
  1. Liest `snapshot = adhkarSnapshotsJSON[typeId]`.
  2. Stellt `<type>AdhkarDone = snapshot.wasDone`, `<type>AdhkarTime = snapshot.previousTime`, sämtliche `itemCounts` dieser Kategorie sowie alle 6 Tasbih-Zähler exakt auf die Werte aus dem Snapshot zurück und löscht den Snapshot.
  3. Sobald der Nutzer hingegen manuell auf einer einzelnen Karte weiterzählt (`incrementCount`), wird ein eventuell vorhandener Snapshot dieser Kategorie gelöscht (`clearAdhkarSnapshot`), damit kein veralteter Zustand überschrieben wird.

#### 5.4.6 Vollständige Referenztabelle aller 61 Adhkar-Items (`AdhkarData.swift`)

##### A. Morgen-Adhkar (`morgenAdhkar` — 25 Items)
| # | Kurzbeschreibung / Anfang | `count` | Tasbih-Link | `slow` (s) | `normal` (s) | `quick` (s) | Primäre Audio-Datei |
| :-: | :--- | :-: | :---: | :-: | :-: | :-: | :--- |
| 1 | Ayat al-Kursi (2:255) | `1` | — | `22.52` | `19.02` | `15.52` | `quran_ayat_kursi.m4a` |
| 2 | Sure Al-Ikhlas (112) | `3` | — | `8.39` | `7.09` | `5.79` | `quran_ikhlas.m4a` |
| 3 | Sure Al-Falaq (113) | `3` | — | `11.73` | `9.91` | `8.09` | `quran_falaq.m4a` |
| 4 | Sure An-Nas (114) | `3` | — | `12.22` | `10.32` | `8.42` | `quran_nas.m4a` |
| 5 | Asbahna wa asbahal-mulku lillah... | `1` | — | `25.86` | `21.84` | `17.82` | `morning_5.m4a` |
| 6 | Allahumma bika asbahna wa bika amsayna... | `1` | — | `5.73` | `4.84` | `3.95` | `morning_6.m4a` |
| 7 | Sayyidul Istighfar (*Allahumma Anta Rabbi...*) | `1` | `.istighfar` | `15.47` | `12.97` | `10.47` | `morning_7.m4a` |
| 8 | Allahumma inni asbahtu ushhiduka... | `4` | — | `12.22` | `10.32` | `8.42` | `morning_8.m4a` |
| 9 | Allahumma ma asbaha bi min ni'matin... | `1` | — | `7.83` | `6.61` | `5.39` | `morning_9.m4a` |
| 10 | Allahumma 'afini fi badani / sam'i / basari | `3` | — | `14.60` | `12.33` | `10.06` | `morning_10.m4a` |
| 11 | Hasbiyallahu la ilaha illa Huwa... | `7` | — | `8.10` | `6.85` | `5.60` | `morning_11.m4a` |
| 12 | Allahumma inni as'alukal-'afwa wal-'afiyah... | `1` | — | `22.71` | `19.18` | `15.65` | `morning_12.m4a` |
| 13 | Allahumma 'Alimal-ghaybi wash-shahadah... | `1` | — | `16.50` | `13.94` | `11.38` | `morning_13.m4a` |
| 14 | Bismillahil-ladhi la yadurru ma'as-mihi... | `3` | — | `6.96` | `5.88` | `4.80` | `morning_14.m4a` |
| 15 | Radiytu billahi Rabban wabil-Islami dinan... | `3` | — | `5.92` | `5.00` | `4.08` | `morning_15.m4a` |
| 16 | Ya Hayyu ya Qayyum bi-rahmatika astaghith... | `1` | — | `6.87` | `5.80` | `4.73` | `morning_16.m4a` |
| 17 | Asbahna wa asbahal-mulku lillahi Rabbil-'alamin | `1` | — | `12.88` | `10.88` | `8.88` | `morning_17.m4a` |
| 18 | Asbahna 'ala fitratil-Islam... | `1` | — | `13.26` | `11.20` | `9.14` | `morning_18.m4a` |
| 19 | Subhanallahi wa bihamdihi | `100` | — | `1.62` | `1.37` | `1.12` | `morning_19.m4a` |
| 20 | La ilaha illallahu wahdahu la sharika lah... | `10` | `.laIlahaIllallah` | `13.20` | `11.08` | `9.00` | `morning_20.m4a` |
| 21 | Subhanallahi wa bihamdihi 'adada khalqihi... | `3` | — | `6.11` | `5.16` | `4.21` | `morning_21.m4a` |
| 22 | Allahumma inni as'aluka 'ilman nafi'an... | `1` | — | `4.96` | `4.19` | `3.42` | `morning_22.m4a` |
| 23 | Astaghfirullaha wa atubu ilayh | `100` | `.istighfar` | `2.67` | `1.73` | `0.79` | `morning_23.m4a` |
| 24 | A'udhu bi-kalimatillahit-tammati min sharri... | `3` | — | `3.53` | `2.98` | `2.43` | `morning_24.m4a` |
| 25 | Allahumma salli wa sallim 'ala Nabiyyina... | `10` | `.salawat` | `3.85` | `2.70` | `1.56` | `morning_25.m4a` |

##### B. Abend-Adhkar (`abendAdhkar` — 23 Items)
| # | Kurzbeschreibung / Anfang | `count` | Tasbih-Link | `slow` (s) | `normal` (s) | `quick` (s) | Audio / Äquivalent |
| :-: | :--- | :-: | :---: | :-: | :-: | :-: | :--- |
| 1–4 | Ayat al-Kursi, Al-Ikhlas (3×), Al-Falaq (3×), An-Nas (3×) | `1,3,3,3` | — | wie Morgen | wie Morgen | wie Morgen | `quran_*` |
| 5 | Amsayna wa amsal-mulku lillah... | `1` | — | `40.70` | `34.36` | `28.00` | `evening_5.m4a` |
| 6 | Allahumma bika amsayna wa bika asbahna... | `1` | — | `10.15` | `8.56` | `7.00` | `evening_6.m4a` |
| 7 | Sayyidul Istighfar | `1` | `.istighfar` | `15.47` | `12.97` | `10.47` | `evening_7` / `morning_7` |
| 8 | Allahumma inni amsaytu ushhiduka... | `4` | — | `12.22` | `10.32` | `8.42` | `evening_8.m4a` |
| 9 | Allahumma ma amsa bi min ni'matin... | `1` | — | `7.83` | `6.61` | `5.39` | `evening_9.m4a` |
| 10–16 | Identisch mit Morgen #10–#16 | `3,7,1,1,3,3,1` | — | wie Morgen | wie Morgen | wie Morgen | `evening_10..16` -> `morning_10..16` |
| 17 | Amsayna wa amsal-mulku lillahi Rabbil-'alamin | `1` | — | `23.40` | `19.72` | `16.00` | `evening_17.m4a` |
| 18 | Amsayna 'ala fitratil-Islam... | `1` | — | `13.26` | `11.20` | `9.14` | `evening_18.m4a` |
| 19 | Subhanallahi wa bihamdihi | `100` | — | `1.62` | `1.37` | `1.12` | `evening_19` / `morning_19` |
| 20 | La ilaha illallahu wahdahu la sharika lah... | `10` | `.laIlahaIllallah` | `13.20` | `11.08` | `9.00` | `evening_20` / `morning_20` |
| 21 | Astaghfirullaha wa atubu ilayh | `100` | `.istighfar` | `2.67` | `1.73` | `0.79` | `evening_21` / `morning_23` |
| 22 | A'udhu bi-kalimatillahit-tammati min sharri... | `3` | — | `3.53` | `2.98` | `2.43` | `evening_22` / `morning_24` |
| 23 | Allahumma salli wa sallim 'ala Nabiyyina... | `10` | `.salawat` | `3.85` | `2.70` | `1.56` | `evening_23` / `morning_25` |

##### C. Schlaf-Adhkar (`schlafAdhkar` — 13 Items)
| # | Kurzbeschreibung / Anfang | `count` | Tasbih-Link | Intervalle (`slow`/`norm`/`quick`) | Primäre Audio-Datei |
| :-: | :--- | :-: | :---: | :---: | :--- |
| 1 | Hände zusammenführen & 3 Schutzsuren (112–114) | `3` | — | Standard (`2.37` / `2.00` / `1.63`) | `sleep_1.m4a` |
| 2 | Ayat al-Kursi (2:255) | `1` | — | Standard | `quran_ayat_kursi.m4a` |
| 3 | Letzte 2 Verse Sure Al-Baqarah (2:285–286) | `1` | — | Standard | `quran_baqarah_last2.m4a` / `sleep_3.m4a` |
| 4 | Bismika Rabbi wada'tu janbi... | `1` | — | Standard | `sleep_4.m4a` |
| 5 | Allahumma innaka khalaqta nafsi... | `1` | — | `16.50` / `14.04` / `11.50` | `sleep_5.m4a` |
| 6 | Allahumma qini 'adhabaka yawma tab'athu 'ibadak | `3` | — | Standard | `sleep_6.m4a` |
| 7 | Bismika Allahumma amutu wa ahya | `1` | — | `4.60` / `3.88` / `3.10` | `sleep_7.m4a` |
| 8 | Tasbih Fatimah (33× SubhanAllah, 33× Alhamdulillah, 34× Allahu Akbar) | `33` | — | `5.70` / `4.75` / `3.80` | `sleep_8.m4a` |
| 9 | Allahumma Rabbas-samawatis-sab'i... | `1` | — | Standard | `sleep_9.m4a` |
| 10 | Alhamdulillahil-ladhi at'amana wa saqana... | `1` | — | Standard | `sleep_10.m4a` |
| 11 | Allahumma 'Alimal-ghaybi wash-shahadah... | `1` | — | Standard | `sleep_11.m4a` |
| 12 | Sure Al-Mulk (Sure 67, mit eigenem Reader-Button!) | `1` | — | Standard | `quran_mulk.m4a` / `sleep_12.m4a` |
| 13 | Allahumma aslamtu nafsi ilayk... | `1` | — | Standard | `sleep_13.m4a` |

---

### 5.5 Quran-Leser-Logik im Detail (`QuranView`, `QuranProgressStore`)

#### 5.5.1 Exakte Textbereinigungs-Pipeline (`cleanQuranText()`)
Vor dem Rendern jedes Quran-Verses aus `text_qpc_hafs` muss zwingend folgende 5-stufige Funktion ausgeführt werden:

```ts
export function cleanQuranText(raw: string): string {
  let s = raw;
  // 0. Entferne nachlaufende QPC-Versnummern + geschützte Leerzeichen am Versende
  s = s.replace(/[\u00A0\u0660-\u0669\u06D4\s]+$/u, '');
  // 1. Ersetze Standard-Sukun (U+0652) durch koranisches Khah-Kopf-Sukun (U+06E1)
  s = s.replaceAll('\u0652', '\u06E1');
  // 2. Entferne störende schwarze/gepunktete Kreise (U+06DF, U+25CC)
  s = s.replaceAll('\u06DF', '').replaceAll('\u25CC', '');
  // 3. Typografischer Iqlab/Idgham-Fix vor kleinem Meem (U+06E2 / U+06E8):
  //    Doppeltes Tanwin (inkl. QPC Open Tanwin U+0657, U+065E, U+08F0..08F2) -> einfache Haraka + Meem
  const iqlabPairs: [string, string][] = [
    ['\u064B\u06E2', '\u064E\u06E2'], ['\u064C\u06E2', '\u064F\u06E2'], ['\u064D\u06E2', '\u0650\u06E2'],
    ['\u064B\u06E8', '\u064E\u06E8'], ['\u064C\u06E8', '\u064F\u06E8'], ['\u064D\u06E8', '\u0650\u06E8'],
    ['\u0657\u06E2', '\u064E\u06E2'], ['\u065E\u06E2', '\u064F\u06E2'],
    ['\u08F0\u06E2', '\u064E\u06E2'], ['\u08F1\u06E2', '\u064F\u06E2'], ['\u08F2\u06E2', '\u0650\u06E2'],
    ['\u0657\u06E8', '\u064E\u06E8'], ['\u065E\u06E8', '\u064F\u06E8'],
    ['\u08F0\u06E8', '\u064E\u06E8'], ['\u08F1\u06E8', '\u064F\u06E8'], ['\u08F2\u06E8', '\u0650\u06E8'],
  ];
  for (const [from, to] of iqlabPairs) s = s.replaceAll(from, to);
  // 4. Tatweel + Dagger-Alif Fix (z. B. bei Ar-Rahman)
  s = s.replaceAll('\u0640\u0670', '\u0670').replaceAll('\u064E\u0640\u0670', '\u064E\u0670');
  return s;
}
```
Danach wird die eigene Versnummer in arabisch-indischen Ziffern (`٠١٢٣٤٥٦٧٨٩`) mit Uthmanischen Ornamentklammern angehängt: ` \uFD3F${toArabicDigits(ayah)}\uFD3E `.

#### 5.5.2 Zeichengenaue Vers-Erfassung & Ausgrauen (KRITISCHE KERNREGEL)
1. **Zeichenbereich pro Vers (`characterRange`):** Innerhalb jedes Seiten-Textblocks merkt sich das Text-Layout für jeden Vers den genauen Start- und End-Zeichenindex (`NSRange`) inklusive seiner Versnummer-Klammer, und berechnet daraus das umschließende Rechteck (`boundingRect` -> `minY` = Oberkante der ersten Zeile des Verses, `maxY` = Unterkante der allerletzten Zeile des Verses).
2. **Bedingung zum Ausgrauen / Als-Gelesen-Zählen:**
   * Es darf **nur beim aktiven Herunterscrollen** (`isScrollingDown == true`) geprüft werden! Beim Hochscrollen wird niemals ein Vers als gelesen markiert.
   * Ein Vers gilt erst in genau dem Moment als gelesen, wenn seine **vollständige Unterkante (`maxY`)** die obere Leselinie (`120pt` Bildschirmkoordinate bzw. `threshold = fontLineHeight` relativ zur Oberkante des Scroll-Viewports) nach oben hin überschritten hat (`verseMaxY <= threshold`). Solange noch die letzte Zeile des Verses im oberen Lesebereich sichtbar ist, bleibt der Vers in normaler Textfarbe!
3. **Strikt monotones Vorwärts-Frontier (`readFrontier: 0..6236`):**
   * Ein Vers mit `globalIndex` (`1..6236`) wird nur gezählt, wenn `globalIndex === readFrontier + 1` (bzw. lückenlos ab `readFrontier + 1` bis zum höchsten aktuell über die Lesekante gescrollten Vers).
   * Jeder Vers zählt innerhalb einer Khatm **exakt ein einziges Mal**:
     * `readFrontier` wird erhöht.
     * Im RAM-Puffer (`QuranProgressStore`) wird `pendingVersesDelta += 1` gezählt.
     * **Seiten-Zählung (`quranPagesRead`):** Hat der soeben gelesene Vers das Flag `verse.isLastVerseOfPage == true` (d. h. es war der letzte Vers einer der 604 Mushaf-Seiten!), wird `pendingPagesDelta += 1` erhöht -> das Tagesziel (`quranPagesRead / quranDailyGoal`) steigt sofort live im Header!

#### 5.5.3 Einweg-Scrollfluss (Hochscroll-Sperre) & Nachrutsch-Bremse (Anti-Fast-Swipe)
Damit Kinder oder versehentliche schnelle Wischgesten nicht dutzende Seiten ungelesen überspringen:
1. **Nachrutsch-Bremse (Momentum-Clamp):**
   * Bei `onScrollBeginDrag` wird `dragStartOffsetY = scrollView.contentOffset.y` gespeichert.
   * Während Trägheits-Auslaufens (`onMomentumScroll` / `scrollViewWillEndDragging` mit Ziel-Offset `targetContentOffsetY`) wird die maximale Vorwärtsdistanz eines einzelnen Wischvorgangs auf **höchstens eine halbe Bildschirmhöhe (`maxForwardJump = 0.5 * viewportHeight`)** begrenzt:
     `targetOffsetY = Math.min(targetOffsetY, dragStartOffsetY + 0.5 * viewportHeight)`.
2. **Hochscroll-Sperre (`minAllowedOffsetY`):**
   * Sobald eine Mushaf-Seite vollständig abgeschlossen ist (`isLastVerseOfPage` überschritten) bzw. die Lesefront voranschreitet, rückt `minAllowedOffsetY` bis zur Oberkante des ersten ungelesenen Verses nach. Der Nutzer kann innerhalb des sichtbaren Kontexts lesen, aber **nicht** zurück in bereits abgeschlossene frühere Seiten scrollen (`if (contentOffset.y < minAllowedOffsetY) contentOffset.y = minAllowedOffsetY`).

#### 5.5.4 Lesezeichen-Wiederherstellung (`QuranBookmark`) & Pinch-to-Zoom
* Beim Pausieren des Scrollens (Debounce `400ms`) sowie bei jedem App-Hintergrundwechsel speichert `QuranProgressStore` ein `QuranBookmark`:
  * `surah`, `ayah`, `page` des ersten ungelesenen Verses (`readFrontier + 1`),
  * `delta`: exakter Pixel-Abstand zwischen Vers-Oberkante (`verseMinY`) und Viewport-Oberkante,
  * `fontSize`: aktuelle Schriftgröße.
* Beim Neustart der App lädt `QuranView` die Seiten ab `bookmark.page`, wartet auf das Text-Layout, sucht `verseMinY` von `(bookmark.surah, bookmark.ayah)` und setzt `contentOffset.y = verseMinY + bookmark.delta * (currentFontSize / bookmark.fontSize)`. Dadurch landet der Nutzer **immer millimetergenau an derselben Textzeile**.
* **Khatm-Abschluss (`readFrontier >= 6236`):** Sobald Vers `114:6` (Sure An-Nas, Vers 6, `id == 6236`) die obere Lesekante passiert, öffnet sich das Khatm-Gratulations-Modal; Bestätigung inkrementiert `quranKhatmCount += 1`, setzt `readFrontier = 0`, löscht `quranFrontierBookmark_v1` und scrollt auf Seite 1 zurück.

---

### 5.6 Tasbih-Logik im Detail (`TasbihView`, `DhikrDetailView`)

#### 5.6.1 Alle Varianten von Istighfar (`5` Formen) & Salawat (`3` Formen)

##### `IstighfarForm` (`UserSettings.swift`)
| `rawValue` | Anzeigename (DE) | Arabischer Originaltext | Umschrift |
| :--- | :--- | :--- | :--- |
| `"kurz"` | Kurzform | `أَسْتَغْفِرُ اللَّهَ` | *Astaghfirullah* |
| `"extended"` | Erweitert | `أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ` | *Astaghfirullaha wa atubu ilayh* |
| `"gewaltig"` | Al-'Azim | `أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ` | *Astaghfirullahal-'Azimal-ladhi la ilaha illa Huwal-Hayyul-Qayyumu wa atubu ilayh* |
| `"yunus"` | Bittgebet von Yunus (a.s.) | `لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ` | *La ilaha illa Anta Subhanaka inni kuntu minaz-zalimin* |
| `"lang"` | Sayyidul Istighfar | `اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ` | *Allahumma Anta Rabbi la ilaha illa Ant, khalaqtani wa ana 'abduka...* |

##### `SalawatForm` (`UserSettings.swift`)
| `rawValue` | Anzeigename (DE) | Arabischer Originaltext | Umschrift |
| :--- | :--- | :--- | :--- |
| `"waSallim"` | Kompakt | `اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ` | *Allahumma salli wa sallim 'ala Nabiyyina Muhammad* |
| `"kurz"` | Mit Familie | `اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ` | *Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad* |
| `"lang"` | Ibrahimiyyah | `اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ` | *Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima...* |

#### 5.6.2 Exakte Auto-Counter-Intervalle für alle 12 Presets (`DhikrDetailView`)
Jedes Preset hat fein abgestimmte Sprechzeiten in Sekunden für **Stufe 0 (Schildkröte / Langsam)**, **Stufe 1 (Normal, Default)** und **Stufe 2 (Hase / Schnell)**:

| Tasbih / Variante | `tasbih_speed_*` Key | Stufe `0` (Langsam) | Stufe `1` (Normal) | Stufe `2` (Schnell) |
| :--- | :--- | :---: | :---: | :---: |
| Istighfar – `kurz` | `tasbih_speed_istighfar_kurz` | `1.35 s` | `1.08 s` | `0.67 s` |
| Istighfar – `extended` | `tasbih_speed_istighfar_extended` | `1.75 s` | `1.51 s` | `1.15 s` |
| Istighfar – `gewaltig` | `tasbih_speed_istighfar_gewaltig` | `5.26 s` | `4.95 s` | `4.47 s` |
| Istighfar – `yunus` | `tasbih_speed_istighfar_yunus` | `4.36 s` | `4.00 s` | `3.44 s` |
| Istighfar – `lang` (Sayyidul) | `tasbih_speed_istighfar_lang` | `14.46 s` | `13.45 s` | `11.88 s` |
| Salawat – `waSallim` | `tasbih_speed_salawat_waSallim` | `2.47 s` | `2.20 s` | `1.78 s` |
| Salawat – `kurz` | `tasbih_speed_salawat_kurz` | `2.94 s` | `2.63 s` | `2.14 s` |
| Salawat – `lang` (Ibrahimiyyah) | `tasbih_speed_salawat_lang` | `10.97 s` | `10.45 s` | `9.64 s` |
| SubhanAllah wa bihamdihi... | `tasbih_speed_subhanAllah` | `3.50 s` | `3.28 s` | `2.94 s` |
| Alhamdulillah (Baqiyat as-Salihat) | `tasbih_speed_alhamdulillah` | `5.05 s` | `4.57 s` | `3.82 s` |
| La hawla (`allahuAkbar`) | `tasbih_speed_allahuAkbar` | `3.04 s` | `2.80 s` | `2.43 s` |
| La ilaha illallah wahdahu... | `tasbih_speed_laIlahaIllallah` | `6.10 s` | `5.63 s` | `4.91 s` |
| **Eigene Tasbihs (`CustomTasbih`)** | `tasbih_speed_<uuid>` | `1.50 s` (40 BPM) | `1.00 s` (60 BPM) | `0.67 s` (90 BPM) |

#### 5.6.3 Dynamischer Grüner Puls-Blitz (`triggerGreenFlash` aus `Theme.swift` & `DhikrDetailView`)
Damit der grüne Kreis-Blitz bei sehr schnellem Zählen nicht dauerhaft flackert, skaliert die Animation dynamisch mit dem aktuellen Zeitintervall $I$ (in Sekunden):
* Normierungsfaktor $t = \text{clamp}\left(\frac{I - 0.5}{2.0 - 0.5},\, 0.0,\, 1.0\right)$.
* **Ziel-Deckkraft (`peakOpacity`):** $0.30 \cdot (0.35 + 0.65 \cdot t)$ (also `0.105` bei `0.5s` Takt bis `0.30` ab `2.0s` Takt).
* **Dauer-Skalierung (`durScale`):** $0.50 + 0.50 \cdot t$, zusätzlich gedeckelt, sodass `fadeIn + hold + fadeOut <= 0.40 * I`:
  * Basiswerte bei $t=1$: `fadeIn = 0.08s`, `hold = 0.12s`, `fadeOut = 0.12s` (Summe `0.32s`).

#### 5.6.4 Sicherheits-Limits, Sanitization & Minus-Korrektur
* **Auto-Sanitization (`onAppear`):** Ist ein gespeicherter Zählerstand korrupt/extrem (`currentCount > 500_000` oder `< 0`), wird er beim Öffnen von `DhikrDetailView` automatisch auf `0` zurückgesetzt.
* **Manuelles Hinzufügen (`+`-Sheet):**
  * Erlaubt ausschließlich ASCII-Ziffern `0-9` (keine Punkte, Kommas, Minuszeichen oder Leerzeichen).
  * Kappt jede Eingabe sofort auf **maximal `5000`** pro Addition!
  * Speichert den zuletzt hinzugefügten Wert in `lastManualAddedAmount`.
* **Minus-Korrektur (`-`-Sheet):**
  * Während eine Auto-Count- oder Tipp-Session läuft, zählt `sessionCount` im Hintergrund mit (`+1` pro Schritt).
  * Wählt der Nutzer im Minus-Modal `-10%`, `-30%`, `-50%` oder `-100%`, wird `deduct = Math.max(1, Math.round(sessionCount * percentage))` berechnet, `currentCount = Math.max(0, currentCount - deduct)` und `sessionCount = Math.max(0, sessionCount - deduct)` gesetzt.
  * Wählt der Nutzer „Letzte manuelle Eingabe entfernen“, wird `currentCount = Math.max(0, currentCount - lastManualAddedAmount)` abgezogen und `lastManualAddedAmount = 0` gesetzt.

---

### 5.7 Fajr-Status-Logik
`DailyRecord` speichert den Fajr-Zustand in `fajrStatus`:
* `"none"`: Nicht gebetet (`isFajrPrayed == false`).
* `"onTime"`: Rechtzeitig vor Sonnenaufgang (`Shuruq`) verrichtet (`isFajrPrayed == true`, Farbe `#2E7D32`).
* `"late"`: Nach Sonnenaufgang nachgebetet / Qada (`isFajrPrayed == true`, Farbe `#FF9500`).
* Rückwärtskompatibilität: Falls ein älterer Datensatz `fajrPrayed == true && fajrStatus == "none"` hat, gilt er als `"onTime"`.

---

### 5.8 Statistik-Logik (`StatsView`)

#### 5.8.1 Zeiträume & Aggregation
1. **Modus `week` (Woche):**
   * Bestimmt die 7 Tage der gewählten Kalenderwoche (Montag bis Sonntag nach ISO-Woche bzw. aktuellem `weekOffset <= 0`) relativ zu `currentTrackingDate`.
   * `totalDaysInPeriod = 7`, `totalFridaysInPeriod = 1`.
   * Vergleichsperiode für den Trend: exakt die 7 Tage davor (`prevWeek`).
   * Gestrichelte Ziellinie im Quran-Chart: `quranDailyGoal` pro Tag; Perioden-Gesamtziel für Tasbih: `6 * normalGoal + 1 * effectiveFridayGoal`.
2. **Modus `month` (Monats-/Jahresübersicht — exakte Ist-Logik aus `StatsView.swift`):**
   * Der Segmented-Tab heißt `"Monat"`, zeigt im Balkendiagramm jedoch die **Monate des gewählten Kalenderjahres** (`year = currentYear + periodOffset`, von `firstMonthWithData` bis `12`, X-Achse mit Monatskurznamen Jan–Dez, Überschrift `"2026"`).
   * `currentRecords`: Alle `DailyRecord`-Einträge des gewählten Kalenderjahres; `previousRecords`: Alle Einträge des Vorjahres (`stats_prev_year`).
   * Gestrichelte Ziellinie im Monats-Balkendiagramm: `quranDailyGoal * 30` Seiten pro Monat.
   * `totalDaysInPeriod` für Ringe/Tasbih nutzt die Tagesanzahl des aktuellen Kalendermonats (`28..31`), während `totalFridaysInPeriod` die Freitage des Jahres zählt. *(Hinweis für Portierung: Kann 1:1 übernommen oder optional um einen expliziten 3. Tab `Jahr` ergänzt werden, da `FAQ.json` bereits Woche/Monat/Jahr erwähnt).*

#### 5.8.2 Trend-Berechnungsformel
Für `currentSum` (aktuelle Periode) und `prevSum` (Vorperiode):
* Wenn `prevSum == 0`:
  * Ist `currentSum > 0`: Trend `+100%` (grün).
  * Ist `currentSum == 0`: Trend `0%` (neutral/grau).
* Wenn `prevSum > 0`:
  $$\text{trendPct} = \text{round}\left(\frac{\text{currentSum} - \text{prevSum}}{\text{prevSum}} \cdot 100\right)$$
  * `trendPct >= 0`: Farbe `#2E7D32`, Pfeil `arrow.up.right`, Text `+{trendPct}%`.
  * `trendPct < 0`: Farbe `#FF9500`, Pfeil `arrow.down.right`, Text `{trendPct}%`.

---

### 5.9 Lokale Push-Benachrichtigungen (`PrayerNotificationManager` & `AdhkarReminderManager`)

Alle Benachrichtigungen werden lokal auf dem Gerät im Voraus geplant und bei jedem App-Start im Vordergrund erneuert:

1. **Gebets- & Adhan-Benachrichtigungen (`PrayerNotificationManager` — 4-Tage-Rollfenster):**
   * Löscht vorher alle ausstehenden Notifications mit Präfix `"prayer_notif_"`.
   * Berechnet für Tag `0, 1, 2, 3` ab heute die exakten Gebetszeiten (inkl. Offsets) für `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`.
   * Falls `prayerNotificationsEnabled == true` und das jeweilige Einzel-Gebets-Toggle aktiv ist:
     * Plant Haupt-Notification zur Gebetszeit (`id: "prayer_notif_<prayer>_<yyyy-MM-dd>"`, Sound: `selectedAdhanSound`, Interruption-Level: `timeSensitive`).
     * Falls `prayer10MinReminderEnabled == true`: Plant zusätzlich eine Vorwarnung `10 Minuten` vorher (`id: "prayer_notif_10min_<prayer>_<yyyy-MM-dd>"`, Standard-Systemton).
2. **Adhkar-Erinnerungen (`AdhkarReminderManager` — 7-Tage-Rollfenster):**
   * Löscht vorherige Adhkar-Reminder (`"adhkar_reminder_*"`).
   * Plant für die nächsten `7` Tage (wobei für **heute** bereits als `Done` markierte Kategorien übersprungen werden!):
     * **Morgen-Adhkar:** `fajrTime + morningAdhkarOffsetMinutes` (Default `+15 Min`).
     * **Abend-Adhkar:** `asrTime + eveningAdhkarOffsetMinutes` (Default `+15 Min`).
     * **Schlaf-Adhkar:** Täglich zu `sleepAdhkarReminderHour:sleepAdhkarReminderMinute` (Default `22:00` Uhr).
     * **Sure Al-Kahf:** Jeden Freitag um `10:00` Uhr morgens.
3. **Maghrib 5-Minuten-Tageswechsel-Hinweis:**
   * Geplant auf `effectiveSunset - 5 Minuten` (`id: "MaghribDayReset_5Min_<offset>"`).

---

## 6. Alle Einstellungen mit Standardwerten

Die folgende Referenztabelle fasst sämtliche vom Nutzer konfigurierbaren Einstellungen, ihre Speicherorte, gültigen Wertebereiche und Werks-Standardwerte zusammen:

| Bereich | Einstellung | Speicherort / Feld | Typ & Wertebereich | Standardwert |
| :--- | :--- | :--- | :--- | :--- |
| **Allgemein** | Erscheinungsbild (Dark Mode) | `UserSettings.isDarkMode` | `Boolean` | `true` (Dunkel) |
| **Allgemein** | App-Sprache | `UserSettings.language` | `de\|en\|ar\|fr\|es\|ur\|id\|tr\|ru\|bn\|ms` | Gerätesprache (Fallback `"en"`) |
| **Allgemein** | Lateinische Umschrift anzeigen | `UserSettings.showTransliteration` | `Boolean` | `true` |
| **Quran** | Tägliches Seitenziel | `UserSettings.quranDailyGoal` | `Int` (`1..20` Onboarding, `1..100` Settings) | `5` Seiten/Tag |
| **Quran** | Farbschema des Readers | `AsyncStorage.quranTheme` | `"system"` \| `"light"` \| `"sepia"` \| `"dark"` | `"system"` |
| **Quran** | Schriftgröße des Korantexts | `AsyncStorage.quranFontSize` | `Double` (`22.0 .. 42.0`, Schritt `1.0`) | `30.0` |
| **Quran** | Sure Al-Baqarah Tracker aktiv | `UserSettings.surahBaqarahEnabled` | `Boolean` | `false` |
| **Quran** | Sure Al-Baqarah Tagesziel | `UserSettings.surahBaqarahGoal` | `Int` (`10..100` %) | `100` % |
| **Tasbih** | Automatischer Zählmodus | `UserSettings.tasbihAutoCount` | `Boolean` (`true`=Auto, `false`=Manuell) | `true` |
| **Tasbih** | Vibration beim Zählen | `UserSettings.tasbihVibrationEnabled`| `Boolean` | `true` |
| **Tasbih** | Aktiv-Status der 6 Kategorien | `UserSettings.<cat>Enabled` | `Boolean` (je Kategorie) | alle `true` |
| **Tasbih** | Tagesziel Istighfar | `UserSettings.istighfarGoal` | `Int` (`1..500000`) | `1000` |
| **Tasbih** | Tagesziel Salawat (Normaltag) | `UserSettings.salawatGoal` | `Int` (`1..500000`) | `500` |
| **Tasbih** | Tagesziel Salawat am Freitag | `UserSettings.salawatFridayGoal` | `Int` (`0` = wie Normaltag, sonst `>0`) | `0` |
| **Tasbih** | Tagesziel SubhanAllah / Alhamdulillah / La hawla / Tahlil | `UserSettings.<cat>Goal` | `Int` (`1..500000`) | je `100` |
| **Tasbih** | Aktive Istighfar-Varianten | `UserSettings.enabledIstighfarForms` | CSV aus `kurz,extended,gewaltig,yunus,lang` | alle 5 aktiv |
| **Tasbih** | Aktive Salawat-Varianten | `UserSettings.enabledSalawatForms` | CSV aus `waSallim,kurz,lang` | alle 3 aktiv |
| **Tasbih** | Geschwindigkeit pro Dhikr | `AsyncStorage.tasbih_speed_<id>` | `Int` (`0`=Schildkröte, `1`=Normal, `2`=Hase)| `1` (Normal) |
| **Adhkar** | Zählmodus | `UserSettings.adhkarAutoCount` | `Boolean` (`false`=Manuell, `true`=Auto) | `false` |
| **Adhkar** | Automatisch zum nächsten Dhikr | `UserSettings.adhkarAutoAdvance` | `Boolean` | `true` |
| **Adhkar** | Globales Standard-Tempo | `UserSettings.defaultAdhkarSpeedStep`| `Int` (`0`, `1`, `2`) | `1` (Normal) |
| **Adhkar** | Individuelles Tempo pro Karte | `AsyncStorage.adhkar_<id>_speed` | `Int` (`0`, `1`, `2`) | erbt `1` |
| **Adhkar** | Pflicht / Optional pro Karte | `AsyncStorage.adhkar_<id>_mandatory` | `Boolean` | `true` |
| **Adhkar** | Eigene Reihenfolge pro Session | `AsyncStorage.adhkar_custom_order_*` | `string[]` | Originalreihenfolge |
| **Adhkar** | Stimme / Rezitator | `UserSettings.adhkarReciter` | `"iapetus"` \| `"duraihim"` | `"iapetus"` |
| **Adhkar** | Morgen-Adhkar Erinnerung | `isMorningAdhkarReminderEnabled` + Offset | `Bool` + `Int` Minuten nach Fajr | `false`, `+15` Min |
| **Adhkar** | Abend-Adhkar Erinnerung | `isEveningAdhkarReminderEnabled` + Offset | `Bool` + `Int` Minuten nach Asr | `false`, `+15` Min |
| **Adhkar** | Schlaf-Adhkar Erinnerung | `isSleepAdhkarReminderEnabled` + Uhrzeit | `Bool` + `HH:mm` | `false`, `22:00` |
| **Adhkar** | Sure Al-Kahf Erinnerung (Fr.) | `isKahfReminderEnabled` | `Bool` (freitags `10:00` Uhr) | `false` |
| **Gebet** | Berechnungsmethode | `UserSettings.calculationMethod` | 1 aus 20 Methoden (Kap. 5.2.3) | `"Muslim World League"` |
| **Gebet** | Asr-Rechtsschule | `UserSettings.asrJuristicMethod` | `"Standard"` \| `"Hanafi"` | `"Standard"` |
| **Gebet** | Manuelle Gebetszeit-Korrekturen| `prayer_offset_<prayer>` (6×) | `Int` (`-60 .. +60` Minuten) | alle `0` |
| **Gebet** | Gebetsbenachrichtigung / Adhan | `UserSettings.prayerNotificationsEnabled`| `Boolean` | `false` |
| **Gebet** | 10-Minuten-Vorab-Erinnerung | `UserSettings.prayer10MinReminderEnabled`| `Boolean` | `false` |
| **Gebet** | Einzel-Gebets-Toggles (5×) | `UserSettings.<prayer>NotificationEnabled`| `Boolean` | alle `true` |
| **Gebet** | Adhan-Klingelton | `UserSettings.selectedAdhanSound` | 1 aus 7 `.caf`-Dateien | `"azan.caf"` |

---

## 7. Herkunft & Format aller Inhalte, Medien & `Translations.json`

### 7.1 Quran-Textdaten (`quran_offline.json`)
* **Dateipfad im Projekt:** `ImanTrack/Assets.xcassets/quran_offline.dataset/quran_offline.json` (~4,3 MB).
* **Herkunft (`fetch_quran.py`):** Offizielle **Quran.com v4 API** (`https://api.quran.com/api/v4/verses/by_page/{1..604}`) kombiniert mit dem offiziellen **King Fahd Glorious Quran Printing Complex (KFGQPC) Hafs Uthmanic Script** Text (`text_qpc_hafs`).
* **Format:** Top-Level JSON-Array mit exakt **`6.236` Vers-Objekten**, aufsteigend sortiert nach Mushaf-Seite (`1..604`) und Versreihenfolge.
* **Exaktes JSON-Schema eines Eintrags:**
  ```json
  {
    "id": 1,
    "verse_number": 1,
    "verse_key": "1:1",
    "hizb_number": 1,
    "rub_el_hizb_number": 1,
    "ruku_number": 1,
    "manzil_number": 1,
    "sajdah_number": null,
    "text_uthmani": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
    "page_number": 1,
    "juz_number": 1,
    "text_qpc_hafs": "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١"
  }
  ```
  * **`text_qpc_hafs` -> `Verse.arabic`:** Wird zwingend für das **visuelle Rendering** mit `UthmanicHafs1Ver18.ttf` (+ `cleanQuranText()`) verwendet.
  * **`text_uthmani` -> `Verse.textUthmani`:** Wird für reine Textsuche und Vergleiche genutzt.

---

### 7.2 Adhkar-Texte & Übersetzungen (`AdhkarData.swift`)
* **Dateipfad im Projekt:** `ImanTrack/Models/AdhkarData.swift` (sollte bei der Portierung als statische JSON-Datei `adhkar_data.json` übernommen werden).
* **Herkunft:** Klassische authentische Adhkar-Sammlung (*Hisnul Muslim* / authentische Sunnah: Ayat al-Kursi, Al-Mu'awwidhat, Sayyidul Istighfar, Tasbih Fatimah, Sure Al-Mulk, Ende Al-Baqarah).
* **Umfang:** `25` Morgen-Adhkar + `23` Abend-Adhkar + `13` Schlaf-Adhkar = **`61` Einträge**.
* **Sprachabdeckung der Adhkar-Bedeutungen (`AdhkarTranslations`):**
  * Direkt am `AdhkarItem`: Arabisch (`arabic`), Lateinische Transliteration (`transliteration`), Deutsch (`german`) und Englisch (`english` via `AdhkarTranslations.translations`).
  * Zusätzlich in `AdhkarTranslations.localizedTranslations` (gematcht über eindeutige arabische Präfix-Schlüssel): Vollständige Übersetzungen in **Französisch (`fr`), Spanisch (`es`), Urdu (`ur`), Indonesisch/Malaiisch (`id`/`ms`), Türkisch (`tr`), Russisch (`ru`) und Bengalisch (`bn`)**.

---

### 7.3 Aufbau von `Translations.json` & Alle unterstützten Sprachen
* **Dateipfad:** `ImanTrack/Translations.json` (`379` Lokalisierungsschlüssel).
* **JSON-Struktur:** Ein flaches Dictionary der Form `Record<TranslationKey, Record<LangCode, string>>`:
  ```json
  {
    "about_section_header": {
      "de": "Über ImanTrack",
      "en": "About ImanTrack",
      "ar": "عن التطبيق",
      "tr": "ImanTrack Hakkında",
      "id": "Tentang ImanTrack",
      "ms": "Mengenai ImanTrack",
      "fr": "À propos d'ImanTrack",
      "es": "Acerca de ImanTrack",
      "ur": "ImanTrack کے بارے میں",
      "ru": "О приложении ImanTrack",
      "bn": "ImanTrack সম্পর্কে"
    }
  }
  ```
* **Fallback-Kette (`L10n.tr(key, lang)`):**
  `translations[key]?.[lang.toLowerCase()] ?? translations[key]?.["en"] ?? key`.

#### Vollständige Übersicht aller 20 Sprachcodes im Projekt
1. **11 vollständig ausgebaute UI-Hauptsprachen** (wählbar im Sprach-Picker in `SettingsView` UND vollständig in `FAQ.json` enthalten):
   * `de` — Deutsch (`379 / 379` Keys, RTL: nein)
   * `en` — Englisch (`379 / 379` Keys, Fallback-Sprache, RTL: nein)
   * `ar` — Arabisch (`379 / 379` Keys, **RTL: ja**)
   * `fr` — Französisch (`312` Keys, RTL: nein)
   * `tr` — Türkisch (`312` Keys, RTL: nein)
   * `es` — Spanisch (`306` Keys, RTL: nein)
   * `id` — Indonesisch (`306` Keys, RTL: nein)
   * `ms` — Malaiisch (`306` Keys, RTL: nein)
   * `ur` — Urdu (`306` Keys, **RTL: ja**)
   * `ru` — Russisch (`306` Keys, RTL: nein)
   * `bn` — Bengalisch (`306` Keys, RTL: nein)
2. **9 zusätzliche Basis-/System-Sprachen** (enthalten Basis-Keys in `Translations.json` sowie lokalisierte Systemberechtigungstexte in `ImanTrack/<lang>.lproj/InfoPlist.strings`):
   * `fa` (Persisch/Farsi, **RTL**), `ps` (Paschtu, **RTL**), `ku` (Kurdisch, **RTL**), `ha` (Hausa), `jv` (Javanisch), `pa` (Panjabi), `so` (Somali), `sw` (Swahili), `uz` (Usbekisch).

---

### 7.4 `FAQ.json` & Audio-Medien

#### `FAQ.json` (`ImanTrack/FAQ.json`)
* Enthält für alle **11 Hauptsprachen** (`de`, `en`, `ar`, `tr`, `fr`, `es`, `id`, `ms`, `ur`, `ru`, `bn`) jeweils `navTitle`, `bannerTitle`, `bannerDesc` sowie `7` thematische Sektionen mit Fragen & Antworten (`iconColor`-Werte: `"islamicGreen"`, `"orange"`, `"purple"`, `"blue"`, `"indigo"`).

#### Audio-Dateien (`113` `.m4a`-Dateien + `7` `.caf`-Dateien)
1. **Adhkar-Rezitationen (`ImanTrack/Audio/Adhkar/` — `106` `.m4a`-Dateien):**
   * **Quran-Suren & Verse (`6` Dateien):** `quran_ayat_kursi.m4a`, `quran_ikhlas.m4a`, `quran_falaq.m4a`, `quran_nas.m4a`, `quran_baqarah_last2.m4a`, `quran_mulk.m4a`.
   * **Stimme 1 – Iapetus (Standard):** `morning_5.m4a` .. `morning_25.m4a` (21 Dateien), `evening_5.m4a` .. `evening_13.m4a`, `evening_15.m4a` .. `evening_23.m4a` (18 Dateien), `sleep_1.m4a`, `sleep_3.m4a` .. `sleep_13.m4a` (12 Dateien) sowie `ghamdi_sleep_*.m4a` (8 Dateien).
   * **Stimme 2 – Scheich Hamad Al-Duraihim (`41` Dateien):** `duraihim_morning_5.m4a` .. `duraihim_morning_25.m4a`, `duraihim_evening_5..11.m4a`, `duraihim_evening_18.m4a`, `duraihim_evening_21..23.m4a`, `duraihim_sleep_4..11.m4a`, `duraihim_sleep_13.m4a`.
2. **Adhan- & Fajr-Klingeltöne (`ImanTrack/Adhan ringtones/` — je `7` `.caf`-Dateien für Push-Notifications `< 30s` und `7` `.m4a`-Dateien):**
   * `azan.caf` / `azan.m4a`
   * `azan (2).caf` / `azan (2).m4a`
   * `azan_holy_makkah.caf` / `azan_holy_makkah.m4a`
   * `beautifull_azan.caf` / `beautifull_azan.m4a`
   * `fajar.caf` / `fajar.m4a`
   * `fajar (1).caf` / `fajar (1).m4a`
   * `fajr_alarm_mecca.caf` / `fajr_alarm_mecca.m4a`

---

## 8. Haptik, Animationen, Audio-Session & Berechtigungen

### 8.1 Haptik-Matrix (`UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` -> `expo-haptics`)
| Benutzeraktion / Systemereignis | Haptik-Typ | Bedingung |
| :--- | :--- | :--- |
| Tasbih einzelner Zählschritt (Tap oder Auto-Tick) | `ImpactFeedbackStyle.Light` | Nur wenn `settings.tasbihVibrationEnabled == true` |
| Adhkar manueller Tap auf Zählkreis | `ImpactFeedbackStyle.Medium` | Immer |
| Adhkar automatischer Tick / Voice-Wiederholung | `ImpactFeedbackStyle.Light` | Immer |
| Adhkar Einmal-Abhaken & Rückgängigmachen | `ImpactFeedbackStyle.Medium` | Immer |
| Adhkar Karte per Long-Press verschieben (Hoch/Runter) | `ImpactFeedbackStyle.Light` | Immer |
| Onboarding „Weiter“-Button & Voice-Toggle | `ImpactFeedbackStyle.Light` | Immer |
| Maghrib 5-Minuten-Vorwarnung erscheint | `NotificationFeedbackType.Warning` | Einmal täglich |
| Maghrib Tages-Reset (`00:00` erreicht) & Onboarding-Start | `NotificationFeedbackType.Success` | Immer |

### 8.2 Animationen & Übergänge
* **Tasbih Grüner Blitz:** `easeIn` (`0.04s–0.08s`) -> `hold` (`0.06s–0.12s`) -> `easeOut` (`0.06s–0.12s`), dynamisch skaliert nach Intervall (Abschnitt 5.6.3).
* **Adhkar Voice-Mode Pulsieren:** Aktiver Audio-Ring pulsiert kontinuierlich zwischen `scale(1.0)` und `scale(1.05)` mit `easeInOut(duration: 0.6s, autoreverse: true)`.
* **Adhkar Edit-Modus & FAQ-Akkordeon:** Federanimation `spring(response: 0.35s, dampingFraction: 0.7–0.8)`; FAQ-Chevron rotiert mit `easeInOut(duration: 0.2s)` von `0°` auf `90°`.
* **Maghrib-Banner & Toasts:** Slide-Transition von oben bzw. unten kombiniert mit Opacity (`0.3s`).
* **Quran-Reader:** Bewusst **keine** verspielten Bounce-/Layout-Animationen beim Ausgrauen gelesener Verse – der Farbwechsel von Textfarbe zu `#808080` erfolgt verzögerungsfrei direkt im Text-Rendering, damit das Auge beim Lesen absolut ruhig bleibt.

### 8.3 Systemberechtigungen, Entitlements & Gerätesteuerung
1. **Standort (`NSLocationWhenInUseUsageDescription`):**
   * Nur **„Beim Verwenden der App“** (`WhenInUse`), grobe Genauigkeit (`Accuracy.Balanced` / `3 km` reicht völlig aus).
   * Kein Hintergrund-Standort-Tracking nötig! Standort wird beim Öffnen einmalig aktualisiert und in `last_latitude` / `last_longitude` gecacht.
   * Lokalisierter Berechtigungstext in allen 20 `.lproj/InfoPlist.strings` (erklärt, dass der Standort ausschließlich lokal für Gebetszeiten und den Tagesbeginn ab Maghrib berechnet wird).
2. **Mitteilungen (`UserNotifications` + Entitlement `com.apple.developer.usernotifications.time-sensitive`):**
   * Optionen: `alert`, `sound`, `badge`, auf iOS zusätzlich `timeSensitive` für Gebetszeiten/Adhan, damit Erinnerungen auch im Fokus-/Nicht-stören-Modus zugestellt werden können.
   * Android-Äquivalent in Expo: Notification-Channel mit `Importance.HIGH` / `MAX`, eigenem Adhan-Sound und `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM`.
3. **Fotomediathek (`PhotosPicker` im Support-Formular):**
   * Nutzt den systemeigenen Out-of-Process Photo-Picker (keine permanente Vollzugriffs-Berechtigung auf alle Fotos nötig).
4. **Bildschirmsperre verhindern (`isIdleTimerDisabled` / `expo-keep-awake`):**
   * Aktiviert, solange der **Tasbih-Auto-Counter** läuft, der **Adhkar-Auto-Counter** läuft oder die **Adhkar-Audio-Wiedergabe** spielt. Wird bei Pause/Stop/`onDisappear` sofort wieder freigegeben.

---

## 9. Externe Bibliotheken & React-Native / Expo Portierungs-Mapping

### 9.1 Externe Bibliotheken im bestehenden Swift-iOS-Projekt
**Keine (0 Drittanbieter-Bibliotheken!).**
Das gesamte Xcode-Projekt (`ImanTrack.xcodeproj`) besitzt **weder Swift Package Manager (SPM) Packages noch CocoaPods**. Es wurden ausschließlich native Apple-Systemframeworks verwendet:

1. `SwiftUI` — Deklaratives UI-Framework
2. `SwiftData` — Lokale SQLite-Objektpersistenz
3. `UIKit` & `CoreText` — Präzises arabisches OpenType-`calt`-Textlayout (`UITextView` / `NSLayoutManager`), Haptik & Idle-Timer
4. `CoreLocation` — Einmalige GPS-Standortbestimmung
5. `UserNotifications` — Lokale Gebets- & Adhkar-Benachrichtigungen inkl. Custom-`.caf`-Adhan
6. `AVFoundation` — Lokale `.m4a`-Audio-Wiedergabe für Adhkar & Rezitator-Vorschau
7. `Charts` (Swift Charts) — Balkendiagramm & gestrichelte Ziellinie in `StatsView`
8. `PhotosUI` — Bildauswahl im Support-Formular
9. `StoreKit` / `UIApplication.open` — App-Store-Bewertungslink
10. `Foundation`, `Combine`, `QuartzCore`, `os` — Kalender (`islamicUmmAlQura`), JSON, Timer & Performance-Signposts

---

### 9.2 Empfohlenes Paket-Mapping für den 1:1-Nachbau in React Native / Expo

| Funktionsbereich | Empfohlenes Expo / React Native Paket | Wichtiger Implementierungshinweis für 1:1-Parität |
| :--- | :--- | :--- |
| **Framework & Routing** | `expo` (SDK 52/53+) + `expo-router` oder `@react-navigation/bottom-tabs` | `lazy: false` / `detachInactiveScreens: false` für Tab 3 setzen, damit der Quran-Reader bei Tab-Wechseln 100 % starr stehen bleibt! |
| **Lokale Datenbank** | `expo-sqlite` (optional mit `drizzle-orm`) | Tabellen `user_settings`, `daily_records` (`UNIQUE(date_string)`), `custom_tasbihs`. |
| **Schneller Key-Value-Store** | `react-native-mmkv` oder `@react-native-async-storage/async-storage` | Ideal für synchrone Zugriffe auf `quranReadFrontier`, `quranFrontierBookmark_v1`, `tasbih_speed_*`, `prayer_offset_*`. |
| **Schriftarten** | `expo-font` | `UthmanicHafs1Ver18.ttf` und `surah-name-v2.ttf` beim Splash-Screen vorladen; OpenType `calt` im nativen Text-Renderer aktivieren! |
| **Quran-Vers-Tracking** | Eigenes leichtgewichtiges **Expo Native View Module** (`UITextView`/`TextKit` auf iOS, `StaticLayout` auf Android) | Da Standard-RN-`<Text>` keine exakten `boundingRect`-Koordinaten einzelner Inline-Verse im Blocksatz liefert, garantiert ein kleines Expo-Modul (~150 Zeilen Swift/Kotlin) die exakte `maxY <= 120pt` Vers-Ausgrau-Logik und Blocksatz + zentrierte Schlusszeile! |
| **Standort** | `expo-location` | `Location.requestForegroundPermissionsAsync()` + `getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced })`. |
| **Push-Erinnerungen & Adhan** | `expo-notifications` | Custom Adhan-Sounds in `app.json` unter `expo-notifications` (`sounds: [...]`) registrieren, damit sie auch bei geschlossener App abgespielt werden. |
| **Adhkar-Audio** | `expo-audio` / `expo-av` | `playsInSilentModeIOS: true`, `shouldDuckAndroid: true`, Loop-Zählung über `playbackStatusUpdate`. |
| **Haptik** | `expo-haptics` | `impactAsync(Light/Medium)` und `notificationAsync(Warning/Success)`. |
| **Display wachhalten** | `expo-keep-awake` | Imperativ `activateKeepAwakeAsync()` / `deactivateKeepAwake()` in Auto-Countern & Audio-Player. |
| **Ringe & Diagramme** | `react-native-svg` + `victory-native` (oder eigenes SVG-BarChart) | Für die Fortschrittsringe (`TodayView`, `DhikrDetailView`, `AdhkarSessionView`, `StatsView`) und das Balkendiagramm mit gestrichelter Ziellinie. |
| **Screenshot-Anhang** | `expo-image-picker` + `expo-image-manipulator` | Skalierung auf max. `600px` und JPEG-Kompression `< 38 KB` Base64 vor dem `fetch`-POST an EmailJS. |
| **Hijri-Kalender** | `Intl.DateTimeFormat('<locale>-u-ca-islamic-umalqura')` (Hermes-Engine integriert) | Kein externes Paket nötig; Eingabedatum ist immer `currentTrackingDate`. |
