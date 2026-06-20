import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var dateString: String
    var date: Date
    var isFajrPrayed: Bool = false
    var fajrPrayerStatus: String = "none"
    
    // Quran
    var quranPagesRead: Int = 0
    var quranVersesRead: Int = 0
    
    // Adhkar
    var morgenAdhkarDone: Bool = false
    var morgenAdhkarTime: Date? = nil
    var abendAdhkarDone: Bool = false
    var abendAdhkarTime: Date? = nil
    var schlafAdhkarDone: Bool = false
    var schlafAdhkarTime: Date? = nil
    var surahAlKahfDone: Bool = false
    var surahAlKahfTime: Date? = nil
    
    // Tasbih
    var istighfarCount: Int = 0
    var istighfarMediumCount: Int = 0
    var istighfarSayyidCount: Int = 0
    
    var salawatCount: Int = 0
    var salawatCombinedCount: Int = 0
    var salawatIbrahimiyahCount: Int = 0
    
    var subhanAllahCount: Int = 0
    var alhamdulillahCount: Int = 0
    var allahuAkbarCount: Int = 0
    var laIlahaIllallahCount: Int = 0
    
    var adhkarProgressJSON: String = "{}"
    var customTasbihCountsJSON: String = "{}"
    
    var totalIstighfarCount: Int {
        istighfarCount + istighfarMediumCount + istighfarSayyidCount
    }
    
    var totalSalawatCount: Int {
        salawatCount + salawatCombinedCount + salawatIbrahimiyahCount
    }
    
    
    func getAdhkarCount(for key: String) -> Int {
        guard let data = adhkarProgressJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return 0
        }
        return dict[key] ?? 0
    }
    
    func setAdhkarCount(for key: String, count: Int) {
        var dict: [String: Int] = [:]
        if let data = adhkarProgressJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dict = decoded
        }
        dict[key] = count
        if let data = try? JSONEncoder().encode(dict),
           let jsonString = String(data: data, encoding: .utf8) {
            adhkarProgressJSON = jsonString
        }
    }
    
    func getCustomTasbihCount(for id: String) -> Int {
        guard let data = customTasbihCountsJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return 0
        }
        return dict[id] ?? 0
    }
    
    func setCustomTasbihCount(for id: String, count: Int) {
        var dict: [String: Int] = [:]
        if let data = customTasbihCountsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dict = decoded
        }
        dict[id] = count
        if let data = try? JSONEncoder().encode(dict),
           let jsonString = String(data: data, encoding: .utf8) {
            customTasbihCountsJSON = jsonString
        }
    }
    
    init(date: Date = Date()) {
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        self.date = trackingDate
        self.dateString = getIslamicDateString(for: date)
        self.isFajrPrayed = false
        self.fajrPrayerStatus = "none"
        self.customTasbihCountsJSON = "{}"
    }
}
