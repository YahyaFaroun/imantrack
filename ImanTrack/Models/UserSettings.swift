import Foundation
import SwiftData

@Model
final class UserSettings {
    // Quran
    var quranDailyGoal: Int = 5
    
    // Tasbih
    var subhanAllahPerMinute: Int = 16
    var alhamdulillahPerMinute: Int = 11
    var allahuAkbarPerMinute: Int = 18
    var istighfarPerMinute: Int = 36
    var salawatPerMinute: Int = 18
    var laIlahaIllallahPerMinute: Int = 9
    var globalTasbihTempo: Int = 60
    
    // Tasbih Enabled
    var istighfarEnabled: Bool = true
    var salawatEnabled: Bool = true
    var subhanAllahEnabled: Bool = true
    var alhamdulillahEnabled: Bool = true
    var allahuAkbarEnabled: Bool = true
    var laIlahaIllallahEnabled: Bool = true
    var surahBaqarahEnabled: Bool = true
    
    // Tasbih Goals
    var istighfarGoal: Int = 1000
    var salawatGoal: Int = 500
    var subhanAllahGoal: Int = 100
    var alhamdulillahGoal: Int = 100
    var allahuAkbarGoal: Int = 100
    var laIlahaIllallahGoal: Int = 100
    var surahBaqarahGoal: Int = 100
    
    var istighfarVersion: String = "mittel"
    var salawatVersion: String = "mittel"
    
    // Tasbih Version Visibility
    var showIstighfarKurz: Bool = true
    var showIstighfarExtended: Bool = true
    var showIstighfarGewaltig: Bool = true
    var showIstighfarLang: Bool = true
    var showIstighfarQuranisch: Bool = true
    
    var showSalawatKurz: Bool = true
    var showSalawatLang: Bool = true
    
    // Individual Tempos (BPM)
    var istighfarKurzBpm: Int = 36
    var istighfarExtendedBpm: Int = 29
    var istighfarGewaltigBpm: Int = 11
    var istighfarLangBpm: Int = 4
    var istighfarQuranischBpm: Int = 8
    
    var salawatKurzBpm: Int = 18
    var salawatLangBpm: Int = 5
    
    // Appearance
    var isDarkMode: Bool = true
    var language: String = "en"
    
    // Adhkar counting mode
    var adhkarAutoCount: Bool = true
    
    // Tasbih counting mode
    var tasbihAutoCount: Bool = true
    
    // Adhkar auto advance to next item
    var adhkarAutoAdvance: Bool = true
    
    // Tasbih vibration
    var tasbihVibrationEnabled: Bool = true
    
    // Default Adhkar Playback Tempo Step (0 = Langsam, 1 = Normal, 2 = Schnell)
    var defaultAdhkarSpeedStep: Int = 1
    
    // Quran Tajweed Harakat Option
    var useTajweedHarakat: Bool = false
    
    init() {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        if ["de", "en", "ar"].contains(locale) {
            self.language = locale
        } else {
            self.language = "en"
        }
    }
}

enum IstighfarForm: String, CaseIterable, Codable {
    case kurz = "kurz"
    case extended = "mittel"
    case gewaltig = "gewaltig"
    case lang = "lang"
    case quranisch = "quranisch"
    
    var displayName: String {
        displayName(for: "de")
    }
    
    func displayName(for lang: String) -> String {
        switch self {
        case .kurz: return L10n.tr("istighfar_kurz_title", lang)
        case .extended: return L10n.tr("istighfar_extended_title", lang)
        case .gewaltig: return L10n.tr("istighfar_gewaltig_title", lang)
        case .lang: return L10n.tr("istighfar_lang_title", lang)
        case .quranisch: return L10n.tr("istighfar_quranisch_title", lang)
        }
    }
    
    func shortDisplayName(for lang: String) -> String {
        let full = displayName(for: lang)
        let words = full.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count <= 4 {
            return full
        } else {
            return words.prefix(4).joined(separator: " ") + "..."
        }
    }
    
    var subtitle: String {
        subtitle(for: "de")
    }
    
    func subtitle(for lang: String) -> String {
        switch self {
        case .kurz: return "Astaghfirullah"
        case .extended: return "Astaghfirullaha wa atubu ilayh"
        case .gewaltig: return "Astaghfirullahal 'Adheemal-ladhi la ilaha illa Huwal-Hayyul-Qayyumu wa atubu ilayh"
        case .lang: return "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant."
        case .quranisch: return "Rabbana dhalamna anfusana wa-in lam taghfir lana wa-tarhamna lanakunanna minal-khasireen"
        }
    }
    
    var arabic: String {
        switch self {
        case .kurz: return "أَسْتَغْفِرُ اللَّهَ"
        case .extended: return "أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ"
        case .gewaltig: return "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ"
        case .lang: return "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ"
        case .quranisch: return "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ"
        }
    }
    
    var defaultBpm: Int {
        switch self {
        case .kurz: return 80
        case .extended: return 60
        case .gewaltig: return 30
        case .lang: return 4
        case .quranisch: return 20
        }
    }
}

enum SalawatForm: String, CaseIterable, Codable {
    case kurz = "kurz"
    case lang = "lang"
    
    var displayName: String {
        displayName(for: "de")
    }
    
    func displayName(for lang: String) -> String {
        switch self {
        case .kurz: return L10n.tr("salawat_kurz_title", lang)
        case .lang: return L10n.tr("salawat_lang_title", lang)
        }
    }
    
    func shortDisplayName(for lang: String) -> String {
        let full = displayName(for: lang)
        let words = full.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count <= 4 {
            return full
        } else {
            return words.prefix(4).joined(separator: " ") + "..."
        }
    }
    
    var subtitle: String {
        subtitle(for: "de")
    }
    
    func subtitle(for lang: String) -> String {
        switch self {
        case .kurz: return "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad"
        case .lang: return "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid."
        }
    }
    
    var arabic: String {
        switch self {
        case .kurz: return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ"
        case .lang: return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ"
        }
    }
    
    var defaultBpm: Int {
        switch self {
        case .kurz: return 50
        case .lang: return 8
        }
    }
}
