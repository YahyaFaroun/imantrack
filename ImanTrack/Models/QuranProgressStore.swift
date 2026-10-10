import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class QuranProgressStore: ObservableObject {
    static let shared = QuranProgressStore()
    
    @Published var readFrontier: Int = 0
    
    private var lastSaveTime: Date = .distantPast
    private var pendingSaveTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let stored = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        self.readFrontier = stored
        migrateIfNeeded()
        setupBackgroundSaveObserver()
    }
    
    private func setupBackgroundSaveObserver() {
        #if os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification))
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.flushPendingSaveImmediately()
                }
            }
            .store(in: &cancellables)
        #endif
    }
    
    func migrateIfNeeded() {
        let migrationKey = "hasMigratedToReadFrontier_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        
        UserDefaults.standard.set(true, forKey: migrationKey)
        
        let existingFrontier = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        if existingFrontier > 0 {
            self.readFrontier = existingFrontier
            print("[PROGRESS_STORE_MIGRATION] Migration skipped. Existing quranReadFrontier = \(existingFrontier)")
            return
        }
        
        var highestIndex = -1
        
        // 1. Try to migrate from currentKhatmReadVerseIds
        if let data = UserDefaults.standard.data(forKey: "currentKhatmReadVerseIds"),
           let ids = try? JSONDecoder().decode([String].self, from: data), !ids.isEmpty {
            for id in ids {
                if let idx = QuranAPIService.shared.getVerseIndex(id: id) {
                    if idx > highestIndex {
                        highestIndex = idx
                    }
                }
            }
        }
        
        if highestIndex >= 0 {
            let migratedFrontier = highestIndex + 1
            self.readFrontier = migratedFrontier
            UserDefaults.standard.set(migratedFrontier, forKey: "quranReadFrontier")
            print("[PROGRESS_STORE_MIGRATION] Migrated from currentKhatmReadVerseIds -> readFrontier = \(migratedFrontier)")
            return
        }
        
        // 2. Fallback to lastReadVerseId
        if let lastId = UserDefaults.standard.string(forKey: "lastReadVerseId"), !lastId.isEmpty,
           let idx = QuranAPIService.shared.getVerseIndex(id: lastId) {
            let migratedFrontier = idx + 1
            self.readFrontier = migratedFrontier
            UserDefaults.standard.set(migratedFrontier, forKey: "quranReadFrontier")
            print("[PROGRESS_STORE_MIGRATION] Migrated from lastReadVerseId ('\(lastId)') -> readFrontier = \(migratedFrontier)")
            return
        }
        
        self.readFrontier = 0
        UserDefaults.standard.set(0, forKey: "quranReadFrontier")
        print("[PROGRESS_STORE_MIGRATION] Migration completed. Default readFrontier = 0")
    }
    
    private var cachedTodayRecord: DailyRecord? = nil
    private var cachedTrackingDateString: String? = nil
    
    private func getCachedTodayRecord(in modelContext: ModelContext, date: Date) -> DailyRecord {
        let trackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        let dateString = getIslamicDateString(for: trackingDate)
        if let record = cachedTodayRecord, cachedTrackingDateString == dateString {
            return record
        }
        let allRecords = (try? modelContext.fetch(FetchDescriptor<DailyRecord>())) ?? []
        let record = DailyRecord.current(in: modelContext, allRecords: allRecords, date: date)
        self.cachedTodayRecord = record
        self.cachedTrackingDateString = dateString
        return record
    }

    func advance(toIndex newIndex: Int, modelContext: ModelContext, date: Date = Date()) {
        guard newIndex > readFrontier else { return }
        
        let oldFrontier = readFrontier
        let verseDelta = newIndex - oldFrontier
        
        var pageDelta = 0
        for idx in oldFrontier..<newIndex {
            if QuranAPIService.shared.isLastVerseOfPage(verseIndex: idx) {
                pageDelta += 1
            }
        }
        
        self.readFrontier = newIndex
        UserDefaults.standard.set(newIndex, forKey: "quranReadFrontier")
        
        let todayRecord = getCachedTodayRecord(in: modelContext, date: date)
        
        todayRecord.quranVersesRead += verseDelta
        todayRecord.quranPagesRead += pageDelta
        
        scheduleDebouncedSwiftDataSave(modelContext: modelContext)
        
        let newVerse = QuranAPIService.shared.getVerseAtIndex(newIndex - 1)
        let verseId = newVerse?.id ?? "index:\(newIndex)"
        print("[QURAN_READ] advance to verse: \(verseId) (index \(newIndex)), old \(oldFrontier) -> new \(newIndex), verseDelta: \(verseDelta), pageDelta: \(pageDelta), totalVersesToday: \(todayRecord.quranVersesRead), totalPagesToday: \(todayRecord.quranPagesRead)")
    }
    
    func resetKhatm(modelContext: ModelContext) {
        let oldVal = readFrontier
        self.readFrontier = 0
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(0, forKey: "quranReadFrontier")
        try? modelContext.save()
        print("[PROGRESS_STORE] Khatm reset: old \(oldVal) -> new 0")
    }
    
    func setReadFrontier(_ newIndex: Int, modelContext: ModelContext) {
        let clamped = max(0, min(newIndex, 6236))
        let oldVal = readFrontier
        self.readFrontier = clamped
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(clamped, forKey: "quranReadFrontier")
        try? modelContext.save()
        print("[PROGRESS_STORE] setReadFrontier manual debug override: old \(oldVal) -> new \(clamped)")
    }
    
    private func scheduleDebouncedSwiftDataSave(modelContext: ModelContext) {
        let now = Date()
        if now.timeIntervalSince(lastSaveTime) >= 2.0 {
            lastSaveTime = now
            try? modelContext.save()
        } else {
            pendingSaveTask?.cancel()
            pendingSaveTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                self.lastSaveTime = Date()
                try? modelContext.save()
            }
        }
    }
    
    private func flushPendingSaveImmediately() {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        lastSaveTime = Date()
        print("[PROGRESS_STORE] Flushed pending SwiftData save on app background/inactive")
    }
}
