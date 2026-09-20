import Foundation
import SwiftData

@MainActor
func getIslamicDateString(for date: Date = Date()) -> String {
    let cal = Calendar.current
    let isMidnight = cal.component(.hour, from: date) == 0 && cal.component(.minute, from: date) == 0 && cal.component(.second, from: date) == 0
    let trackingDate = isMidnight ? date : LocationAndSolarManager.shared.getTrackingDate(for: date)
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: trackingDate)
}

extension DailyRecord {
    @MainActor
    static func current(in modelContext: ModelContext, allRecords: [DailyRecord], date: Date = Date()) -> DailyRecord {
        let key = getIslamicDateString(for: date)
        if let existing = allRecords.first(where: { $0.dateString == key }) {
            return existing
        }
        
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.dateString == key })
        if let existingInContext = try? modelContext.fetch(descriptor).first {
            return existingInContext
        }
        
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        let newRecord = DailyRecord(date: trackingDate)
        newRecord.dateString = key
        modelContext.insert(newRecord)
        try? modelContext.save()
        return newRecord
    }
}
