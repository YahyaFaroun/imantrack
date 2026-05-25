import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var dateString: String
    var date: Date
    
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
    
    var totalIstighfarCount: Int {
        istighfarCount + istighfarMediumCount + istighfarSayyidCount
    }
    
    var totalSalawatCount: Int {
        salawatCount + salawatCombinedCount + salawatIbrahimiyahCount
    }
    
    init(date: Date = Date()) {
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        self.date = trackingDate
        self.dateString = getIslamicDateString(for: date)
    }
}
