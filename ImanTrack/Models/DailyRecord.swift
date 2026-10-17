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
    var surahBaqarahDone: Bool = false
    var surahBaqarahTime: Date? = nil
    var surahBaqarahProgress: Int = 0
    
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
    var adhkarSnapshotsJSON: String = "{}"
    
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
    
    // MARK: - Adhkar Snapshot & Single-Tap Completion / Reversion
    
    struct AdhkarCompletionSnapshot: Codable {
        var previousCounts: [String: Int] = [:]
        var creditedTasbih: [String: Int] = [:]
    }
    
    func getAdhkarSnapshot(for typeId: String) -> AdhkarCompletionSnapshot? {
        guard let data = adhkarSnapshotsJSON.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: AdhkarCompletionSnapshot].self, from: data) else {
            return nil
        }
        return dict[typeId]
    }
    
    func saveAdhkarSnapshot(for typeId: String, snapshot: AdhkarCompletionSnapshot) {
        var dict: [String: AdhkarCompletionSnapshot] = [:]
        if let data = adhkarSnapshotsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: AdhkarCompletionSnapshot].self, from: data) {
            dict = decoded
        }
        dict[typeId] = snapshot
        if let data = try? JSONEncoder().encode(dict),
           let jsonString = String(data: data, encoding: .utf8) {
            adhkarSnapshotsJSON = jsonString
        }
    }
    
    func clearAdhkarSnapshot(for typeId: String) {
        guard let data = adhkarSnapshotsJSON.data(using: .utf8),
              var dict = try? JSONDecoder().decode([String: AdhkarCompletionSnapshot].self, from: data) else {
            return
        }
        dict.removeValue(forKey: typeId)
        if let data = try? JSONEncoder().encode(dict),
           let jsonString = String(data: data, encoding: .utf8) {
            adhkarSnapshotsJSON = jsonString
        }
    }
    
    func isAdhkarDone(type: AdhkarSessionType) -> Bool {
        switch type {
        case .sleep: return schlafAdhkarDone
        case .morning: return morgenAdhkarDone
        case .evening: return abendAdhkarDone
        }
    }
    
    func markAllAdhkarCompleted(type: AdhkarSessionType) {
        let items = adhkarItems(for: type)
        var snapshot = AdhkarCompletionSnapshot()
        
        for item in items {
            let key = safeAdhkarKey(typeId: type.idStr, item: item)
            let current = getAdhkarCount(for: key)
            snapshot.previousCounts[key] = current
            
            if current < item.count {
                let diff = item.count - current
                setAdhkarCount(for: key, count: item.count)
                
                if let category = item.linkedTasbihCategory {
                    snapshot.creditedTasbih[category.rawValue, default: 0] += diff
                    switch category {
                    case .istighfar: self.istighfarCount += diff
                    case .salawat: self.salawatCount += diff
                    case .subhanAllah: self.subhanAllahCount += diff
                    case .alhamdulillah: self.alhamdulillahCount += diff
                    case .allahuAkbar: self.allahuAkbarCount += diff
                    case .laIlahaIllallah: self.laIlahaIllallahCount += diff
                    }
                }
            }
        }
        
        saveAdhkarSnapshot(for: type.idStr, snapshot: snapshot)
        
        let now = Date()
        switch type {
        case .sleep:
            self.schlafAdhkarDone = true
            self.schlafAdhkarTime = now
        case .morning:
            self.morgenAdhkarDone = true
            self.morgenAdhkarTime = now
        case .evening:
            self.abendAdhkarDone = true
            self.abendAdhkarTime = now
        }
    }
    
    func markAdhkarUncompleted(type: AdhkarSessionType) {
        let items = adhkarItems(for: type)
        let snapshot = getAdhkarSnapshot(for: type.idStr)
        
        // 1. Genau die beim Abhaken gutgeschriebene Tasbih-Differenz wieder abziehen
        if let snapshot = snapshot {
            for (categoryRaw, creditedAmount) in snapshot.creditedTasbih {
                if let category = TasbihCategory(rawValue: categoryRaw) {
                    switch category {
                    case .istighfar: self.istighfarCount = max(0, self.istighfarCount - creditedAmount)
                    case .salawat: self.salawatCount = max(0, self.salawatCount - creditedAmount)
                    case .subhanAllah: self.subhanAllahCount = max(0, self.subhanAllahCount - creditedAmount)
                    case .alhamdulillah: self.alhamdulillahCount = max(0, self.alhamdulillahCount - creditedAmount)
                    case .allahuAkbar: self.allahuAkbarCount = max(0, self.allahuAkbarCount - creditedAmount)
                    case .laIlahaIllallah: self.laIlahaIllallahCount = max(0, self.laIlahaIllallahCount - creditedAmount)
                    }
                }
            }
        }
        
        // 2. Einzelzähler auf den Stand VOR dem Abhaken zurücksetzen
        for item in items {
            let key = safeAdhkarKey(typeId: type.idStr, item: item)
            let prev = snapshot?.previousCounts[key] ?? 0
            setAdhkarCount(for: key, count: prev)
        }
        
        // 3. Snapshot löschen
        clearAdhkarSnapshot(for: type.idStr)
        
        // 4. Flag zurück auf false, Zeitstempel entfernen
        switch type {
        case .sleep:
            self.schlafAdhkarDone = false
            self.schlafAdhkarTime = nil
        case .morning:
            self.morgenAdhkarDone = false
            self.morgenAdhkarTime = nil
        case .evening:
            self.abendAdhkarDone = false
            self.abendAdhkarTime = nil
        }
    }
    
    @MainActor
    init(date: Date = Date()) {
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        self.date = trackingDate
        self.dateString = getIslamicDateString(for: date)
        self.isFajrPrayed = false
        self.fajrPrayerStatus = "none"
        self.customTasbihCountsJSON = "{}"
    }
}
