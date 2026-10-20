// MARK: - CRITICAL RULE / REGEL
// DIE KORAN-SCHRIFTART (KFGQPCHAFSUthmanicScript-Regula / UthmanicHafs1Ver18.ttf) DARF NIEMALS GEÄNDERT WERDEN!
// JEDE ÄNDERUNG AN DER KORAN-SCHRIFTART ERFORDERT DIE EXPLIZITE ZUSTIMMUNG DES USERS.

import SwiftUI

struct Theme {
    static var islamicGreen: Color {
        return Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255) // green
    }
    
    static var background: Color {
        Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? .black
                : UIColor(red: 245 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1.0)
        })
    }
    
    static var darkBackground: Color {
        Color.black
    }
    
    static var cardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
                : .white
        })
    }
    
    static var accent: Color {
        return islamicGreen
    }
    
    // MARK: - Tasbih Flash Konfiguration
    /// Grundstärke der Deckkraft für den Tasbih-Blitz (bei ruhigem Tempo >= 2,0s)
    static let tasbihFlashBaseOpacity: Double = 0.3
    
    /// Schwellenwert für langsames/ruhiges Tempo in Sekunden (ab hier 100% Grundstärke & Standard-Dauer)
    static let tasbihFlashSlowIntervalThreshold: Double = 2.0
    
    /// Schwellenwert für sehr schnellen Takt in Sekunden (ca. 0,5s)
    static let tasbihFlashFastIntervalThreshold: Double = 0.5
    
    /// Minimale Stärke im Verhältnis zur Grundstärke bei schnellem Takt (ca. 30–40%, hier 35%)
    static let tasbihFlashMinStrengthFactor: Double = 0.35
    
    /// Minimaler Dauer-Faktor bei schnellem Takt (50% der Standard-Dauer)
    static let tasbihFlashMinDurationFactor: Double = 0.50
    
    /// Standard-Dauer für easeIn bei ruhigem Tempo
    static let tasbihFlashBaseFadeInDuration: Double = 0.08
    
    /// Standard-Haltezeit bis easeOut bei ruhigem Tempo
    static let tasbihFlashBaseHoldDuration: Double = 0.12
    
    /// Standard-Dauer für easeOut bei ruhigem Tempo
    static let tasbihFlashBaseFadeOutDuration: Double = 0.12
    
    /// Maximale Gesamtdauer des Blitzes im Verhältnis zum Intervall (max. 40% des Abstands)
    static let tasbihFlashMaxDurationRatio: Double = 0.40
    
    static func uthmaniFont(size: CGFloat) -> Font {
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
        }
        return .custom("Geeza Pro", size: size)
    }
    
    static func uthmaniUIFont(size: CGFloat) -> UIFont {
        var baseFont: UIFont? = nil
        if let font = UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) {
            baseFont = font
        } else if let font = UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) {
            baseFont = font
        }
        
        guard let font = baseFont else {
            return UIFont(name: "GeezaPro", size: size) ?? UIFont.systemFont(ofSize: size)
        }
        
        // OpenType 'calt' (Contextual Alternates) für versetztes Tanwin in UthmanicHafs1Ver18.ttf aktivieren
        let featureSettings: [[UIFontDescriptor.FeatureKey: Int]] = [
            [
                .type: kContextualAlternatesType,
                .selector: kContextualAlternatesOnSelector
            ]
        ]
        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: featureSettings
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
    
    static func uthmaniFontForced(size: CGFloat) -> Font {
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
        }
        return .custom("Geeza Pro", size: size)
    }
    
    static func surahNameFont(size: CGFloat) -> Font {
        if UIFont(name: "surah-name-v2", size: size) != nil {
            return .custom("surah-name-v2", size: size)
        } else if UIFont(name: "QCF_SurahHeader_COLOR", size: size) != nil {
            return .custom("QCF_SurahHeader_COLOR", size: size)
        }
        return .system(size: size)
    }
    
    static func getQuranBackgroundColor(for theme: String, systemColorScheme: ColorScheme) -> Color {
        switch theme {
        case "light":
            return Color(red: 235 / 255, green: 243 / 255, blue: 250 / 255) // Soft Ice Blue
        case "sepia":
            return Color(red: 244/255, green: 236/255, blue: 216/255)
        case "dark":
            return .black
        default: // system
            return systemColorScheme == .dark ? .black : Color(red: 245 / 255, green: 247 / 255, blue: 245 / 255)
        }
    }

    static func getQuranTextColor(for theme: String, systemColorScheme: ColorScheme) -> Color {
        switch theme {
        case "light":
            return Color(red: 20 / 255, green: 32 / 255, blue: 48 / 255) // Deep navy/charcoal for soft contrast
        case "sepia":
            return Color(red: 44/255, green: 34/255, blue: 24/255) // dunkelbraun
        case "dark":
            return .white
        default: // system
            return .primary
        }
    }

    static func getQuranUIBackgroundColor(for theme: String, systemColorScheme: ColorScheme) -> UIColor {
        switch theme {
        case "light":
            return UIColor(red: 235 / 255, green: 243 / 255, blue: 250 / 255, alpha: 1.0)
        case "sepia":
            return UIColor(red: 244/255, green: 236/255, blue: 216/255, alpha: 1.0)
        case "dark":
            return .black
        default: // system
            return systemColorScheme == .dark ? .black : UIColor(red: 245 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1.0)
        }
    }

    static func getQuranUITextColor(for theme: String, systemColorScheme: ColorScheme) -> UIColor {
        switch theme {
        case "light":
            return UIColor(red: 20 / 255, green: 32 / 255, blue: 48 / 255, alpha: 1.0)
        case "sepia":
            return UIColor(red: 44/255, green: 34/255, blue: 24/255, alpha: 1.0)
        case "dark":
            return .white
        default: // system
            return systemColorScheme == .dark ? .white : .black
        }
    }
    
    static func quranFont(type: String = "uthmanic", size: CGFloat) -> Font {
        return uthmaniFont(size: size)
    }
    
    static func quranUIFont(type: String = "uthmanic", size: CGFloat) -> UIFont {
        return uthmaniUIFont(size: size)
    }
}

struct L10n {
    static let translations: [String: [String: String]] = loadTranslations()

    private static func loadTranslations() -> [String: [String: String]] {
        let bundle = Bundle(for: ThemeBundleToken.self)
        let url = Bundle.main.url(forResource: "Translations", withExtension: "json") ??
                  bundle.url(forResource: "Translations", withExtension: "json")
        guard let url = url,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return [:]
        }
        return dict
    }

    static func tr(_ key: String, _ lang: String) -> String {
        let l = lang.lowercased()
        guard let translationsForKey = translations[key] else { return key }
        return translationsForKey[l] ?? translationsForKey["en"] ?? key
    }
}

private final class ThemeBundleToken {}

extension String {
    func cleanQuranText() -> String {
        var cleaned = self
        
        // 0. Trimm nachlaufende QPC-Versnummern (U+00A0 + arabische Ziffern)
        if let range = cleaned.range(of: "[\\u{00A0}\\u{0660}-\\u{0669}\\u{06D4}\\s]+$", options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        
        // 1. Ersetze Standard-Sukun (U+0652) durch das koranische Sukun-Zeichen (U+06E1 - kleine Khah-Kopfform)
        cleaned = cleaned.replacingOccurrences(of: "\u{0652}", with: "\u{06E1}")
        
        // 2. Entferne schwarze/ausgefüllte Kreise und Dotted Circles (U+06DF, U+25CC),
        // da sie auf iOS als störende schwarze Punkte (z. B. auf 'أُولَـٰٓئِكَ') dargestellt werden.
        cleaned = cleaned.replacingOccurrences(of: "\u{06DF}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{25CC}", with: "")
        
        // 3. Typografischer Iqlab/Idgham-Fix: Ersetze doppelten Haraka (Tanwin) vor dem kleinen Meem (\u{06E2}/\u{06E8})
        // durch die einzelne Haraka (Fatha/Damma/Kasra) + Meem.
        // Dies verhindert das unschöne Überlappen/Kollidieren von Meem und Tanwin-Strichen in iOS CoreText.
        cleaned = cleaned.replacingOccurrences(of: "\u{064B}\u{06E2}", with: "\u{064E}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064C}\u{06E2}", with: "\u{064F}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064D}\u{06E2}", with: "\u{0650}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064B}\u{06E8}", with: "\u{064E}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064C}\u{06E8}", with: "\u{064F}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064D}\u{06E8}", with: "\u{0650}\u{06E8}")
        
        // Erweiterter Iqlab-Fix für QPC Open Tanwin (\u{0657}, \u{065E}, \u{08F0}..) vor Meem
        cleaned = cleaned.replacingOccurrences(of: "\u{0657}\u{06E2}", with: "\u{064E}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{065E}\u{06E2}", with: "\u{064F}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F0}\u{06E2}", with: "\u{064E}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F1}\u{06E2}", with: "\u{064F}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F2}\u{06E2}", with: "\u{0650}\u{06E2}")
        cleaned = cleaned.replacingOccurrences(of: "\u{0657}\u{06E8}", with: "\u{064E}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{065E}\u{06E8}", with: "\u{064F}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F0}\u{06E8}", with: "\u{064E}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F1}\u{06E8}", with: "\u{064F}\u{06E8}")
        cleaned = cleaned.replacingOccurrences(of: "\u{08F2}\u{06E8}", with: "\u{0650}\u{06E8}")
        
        // 4. Positionierungs-Fix: Ersetze Tatweel (U+0640) + Dagger Alif (U+0670) durch einfaches Dagger Alif,
        // um das Verrutschen des Dagger Alif auf das Folgezeichen (z.B. bei 'Ar-Rahman') zu verhindern.
        cleaned = cleaned.replacingOccurrences(of: "\u{0640}\u{0670}", with: "\u{0670}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064E}\u{0640}\u{0670}", with: "\u{064E}\u{0670}")
        
        return cleaned
    }
}