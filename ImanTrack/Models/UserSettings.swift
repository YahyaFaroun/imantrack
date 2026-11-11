import Foundation
import SwiftData

@Model
final class UserSettings {
    // Quran
    var quranDailyGoal: Int = 5
    
    // Tasbih
    var subhanAllahPerMinute: Int = 60
    var alhamdulillahPerMinute: Int = 60
    var allahuAkbarPerMinute: Int = 60
    var istighfarPerMinute: Int = 60
    var salawatPerMinute: Int = 60
    var laIlahaIllallahPerMinute: Int = 60
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
    var salawatFridayGoalEnabled: Bool = false
    var salawatFridayGoal: Int = 1000
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
    var showIstighfarYunus: Bool = true
    
    var showSalawatWaSallim: Bool = true
    var showSalawatKurz: Bool = true
    var showSalawatLang: Bool = true
    
    // Individual Tempos (BPM)
    var istighfarKurzBpm: Int = 60
    var istighfarExtendedBpm: Int = 50
    var istighfarGewaltigBpm: Int = 40
    var istighfarLangBpm: Int = 40
    var istighfarQuranischBpm: Int = 40
    var istighfarYunusBpm: Int = 40
    
    var salawatWaSallimBpm: Int = 60
    var salawatKurzBpm: Int = 60
    var salawatLangBpm: Int = 40
    
    // Appearance
    var isDarkMode: Bool = true
    var language: String = "en"
    var showTransliteration: Bool = true
    
    // Adhkar counting mode
    var adhkarAutoCount: Bool = true
    
    // Tasbih counting mode
    var tasbihAutoCount: Bool = true
    
    // Adhkar auto advance to next item
    var adhkarAutoAdvance: Bool = true
    
    // Adhkar Voice Mode
    var adhkarVoiceEnabled: Bool = false
    var adhkarReciter: String = "iapetus"
    
    // Tasbih vibration
    var tasbihVibrationEnabled: Bool = true
    
    // Default Adhkar Playback Tempo Step (0 = Langsam, 1 = Normal, 2 = Schnell)
    var defaultAdhkarSpeedStep: Int = 1
    
    // Quran Tajweed Harakat Option
    var useTajweedHarakat: Bool = false
    
    // Prayer Calculation Settings
    var calculationMethodRaw: String = "mwl"
    var asrSchoolRaw: String = "standard"
    
    // Prayer Notifications & Adhan
    var prayerAdhanEnabled: Bool = false
    var prayerReminder10MinEnabled: Bool = false
    var prayerAdhanSound: String = "azan.caf"
    var prayerFajrEnabled: Bool = true
    var prayerDhuhrEnabled: Bool = true
    var prayerAsrEnabled: Bool = true
    var prayerMaghribEnabled: Bool = true
    var prayerIshaEnabled: Bool = true
    
    init() {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        if ["de", "en", "ar", "tr", "id", "ms", "fr", "es", "ur", "ru", "bn"].contains(locale) {
            self.language = locale
        } else {
            self.language = "en"
        }
    }
    
    func isIslamicFriday(for date: Date = Date()) -> Bool {
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        return Calendar.current.component(.weekday, from: trackingDate) == 6
    }
    
    func effectiveSalawatGoal(for date: Date = Date()) -> Int {
        if salawatFridayGoalEnabled && isIslamicFriday(for: date) {
            return salawatFridayGoal
        }
        return salawatGoal
    }
}

enum IstighfarForm: String, CaseIterable, Codable {
    case kurz = "kurz"
    case extended = "mittel"
    case gewaltig = "gewaltig"
    case yunus = "yunus"
    case lang = "lang"
    
    var displayName: String {
        displayName(for: "de")
    }
    
    func displayName(for lang: String) -> String {
        switch self {
        case .kurz: return L10n.tr("istighfar_kurz_title", lang)
        case .extended: return L10n.tr("istighfar_extended_title", lang)
        case .gewaltig: return L10n.tr("istighfar_gewaltig_title", lang)
        case .yunus: return L10n.tr("istighfar_yunus_title", lang)
        case .lang: return L10n.tr("istighfar_lang_title", lang)
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
        case .yunus: return "La ilaha illa anta, subhanaka inni kuntu minaz-zalimin"
        case .lang: return "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant."
        }
    }
    
    var arabic: String {
        switch self {
        case .kurz: return "أَسْتَغْفِرُ اللَّهَ"
        case .extended: return "أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ"
        case .gewaltig: return "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ"
        case .yunus: return "لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ"
        case .lang: return "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ"
        }
    }
    
    var defaultBpm: Int {
        switch self {
        case .kurz: return 60
        case .extended: return 50
        case .gewaltig: return 40
        case .yunus: return 40
        case .lang: return 40
        }
    }
}

enum AdhkarReciter: String, CaseIterable, Identifiable, Codable {
    case iapetus = "iapetus"
    case duraihim = "duraihim"
    
    var id: String { rawValue }
    
    func title(for lang: String) -> String {
        switch self {
        case .iapetus: return L10n.tr("reader_iapetus", lang)
        case .duraihim: return L10n.tr("reader_al_duraihim", lang)
        }
    }
    
    func subtitle(for lang: String) -> String {
        switch self {
        case .iapetus: return L10n.tr("reader_iapetus_desc", lang)
        case .duraihim: return L10n.tr("reader_al_duraihim_desc", lang)
        }
    }
}

enum SalawatForm: String, CaseIterable, Codable {
    case waSallim = "waSallim"
    case kurz = "kurz"
    case lang = "lang"
    
    var displayName: String {
        displayName(for: "de")
    }
    
    func displayName(for lang: String) -> String {
        switch self {
        case .waSallim: return L10n.tr("salawat_wa_sallim_title", lang)
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
        case .waSallim: return "Allahumma salli wa sallim 'ala Muhammad"
        case .kurz: return "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad"
        case .lang: return "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid."
        }
    }
    
    var arabic: String {
        switch self {
        case .waSallim: return "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى مُحَمَّدٍ"
        case .kurz: return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ"
        case .lang: return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ"
        }
    }
    
    var defaultBpm: Int {
        switch self {
        case .waSallim: return 60
        case .kurz: return 60
        case .lang: return 40
        }
    }
}
