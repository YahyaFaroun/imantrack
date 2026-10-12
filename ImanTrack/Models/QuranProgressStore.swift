import Foundation
import SwiftUI
import SwiftData
import Combine

struct QuranBookmark: Codable, Equatable {
    let page: Int
    let offsetInPage: CGFloat
    let fontSize: CGFloat
}

@MainActor
class QuranProgressStore: ObservableObject {
    static let shared = QuranProgressStore()
    
    @Published private(set) var readFrontier: Int = 0
    private let bookmarkKey = "quranBookmark"
    @Published private(set) var bookmark: QuranBookmark? = nil
    
    private var lastSaveTime: Date = .distantPast
    private var pendingSaveTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let stored = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        self.readFrontier = stored
        if let data = UserDefaults.standard.data(forKey: bookmarkKey),
           let bm = try? JSONDecoder().decode(QuranBookmark.self, from: data) {
            self.bookmark = bm
        }
        let bmStr = bookmark != nil ? "S.\(bookmark!.page) +\(String(format: "%.1f", bookmark!.offsetInPage))pt" : "keines"
        print("[QURAN_STATE] Store-init: readFrontier im Speicher = \(readFrontier), Wert in UserDefaults = \(stored), Lesezeichen=\(bmStr)")
        // Altlasten endgültig entfernen
        UserDefaults.standard.removeObject(forKey: "lastReadVerseId")
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        migrateIfNeeded()
        setupBackgroundSaveObserver()
    }
    
    func saveBookmark(_ bookmark: QuranBookmark) {
        guard self.bookmark != bookmark else { return }
        self.bookmark = bookmark
        if let data = try? JSONEncoder().encode(bookmark) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            UserDefaults.standard.synchronize()
        }
        print("[QURAN_RESUME] Gespeichert: S.\(bookmark.page) +\(String(format: "%.1f", bookmark.offsetInPage))pt (fontSize: \(bookmark.fontSize))")
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
        
        let existingFrontier = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        if existingFrontier > 0 {
            if existingFrontier >= self.readFrontier {
                self.readFrontier = existingFrontier
            }
            UserDefaults.standard.set(true, forKey: migrationKey)
            UserDefaults.standard.synchronize()
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
            if migratedFrontier < self.readFrontier {
                print("[QURAN_STATE] WARNUNG: migrateIfNeeded mit kleinerem Index (\(migratedFrontier) < \(self.readFrontier)) abgewiesen!")
            } else {
                self.readFrontier = migratedFrontier
                UserDefaults.standard.set(migratedFrontier, forKey: "quranReadFrontier")
            }
            UserDefaults.standard.set(true, forKey: migrationKey)
            UserDefaults.standard.synchronize()
            print("[PROGRESS_STORE_MIGRATION] Migrated from currentKhatmReadVerseIds -> readFrontier = \(self.readFrontier)")
            return
        }
        
        if self.readFrontier == 0 {
            self.readFrontier = 0
            UserDefaults.standard.set(0, forKey: "quranReadFrontier")
        }
        UserDefaults.standard.set(true, forKey: migrationKey)
        UserDefaults.standard.synchronize()
        print("[PROGRESS_STORE_MIGRATION] Migration completed. Default readFrontier = \(self.readFrontier)")
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
        if newIndex < readFrontier {
            print("[QURAN_STATE] WARNUNG: advance Versuch mit kleinerem Index (\(newIndex) < \(readFrontier)) abgewiesen!")
            return
        }
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
        UserDefaults.standard.synchronize()
        
        let todayRecord = getCachedTodayRecord(in: modelContext, date: date)
        
        todayRecord.quranVersesRead += verseDelta
        todayRecord.quranPagesRead += pageDelta
        
        scheduleDebouncedSwiftDataSave(modelContext: modelContext)
        
        let newVerse = QuranAPIService.shared.getVerseAtIndex(newIndex - 1)
        let verseId = newVerse?.id ?? "index:\(newIndex)"
        print("[QURAN_STATE] advance: neuer Wert im Speicher = \(self.readFrontier), Wert in UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier")), verse=\(verseId)")
        print("[QURAN_READ] advance to verse: \(verseId) (index \(newIndex)), old \(oldFrontier) -> new \(newIndex), verseDelta: \(verseDelta), pageDelta: \(pageDelta), totalVersesToday: \(todayRecord.quranVersesRead), totalPagesToday: \(todayRecord.quranPagesRead)")
    }
    
    func resetKhatm(modelContext: ModelContext) {
        let oldVal = readFrontier
        self.readFrontier = 0
        self.bookmark = nil
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(0, forKey: "quranReadFrontier")
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        UserDefaults.standard.synchronize()
        try? modelContext.save()
        print("[QURAN_STATE] resetKhatm: alt \(oldVal) -> neu 0, UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier"))")
    }
    
    func setReadFrontier(_ newIndex: Int, modelContext: ModelContext) {
        let clamped = max(0, min(newIndex, 6236))
        let oldVal = readFrontier
        self.readFrontier = clamped
        self.bookmark = nil
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(clamped, forKey: "quranReadFrontier")
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        UserDefaults.standard.synchronize()
        try? modelContext.save()
        print("[QURAN_STATE] setReadFrontier manual debug override: alt \(oldVal) -> neu \(clamped), UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier"))")
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
