import Foundation
import SwiftUI
import SwiftData
import Combine
import QuartzCore
import os

struct QuranBookmark: Codable, Equatable {
    let verseIndex: Int
    let delta: CGFloat
    let fontSize: CGFloat
}

@MainActor
class QuranProgressStore: ObservableObject {
    static let shared = QuranProgressStore()
    
    @Published private(set) var readFrontier: Int = 0
    private let oldBookmarkKey = "quranBookmark"
    private let bookmarkKey = "quranFrontierBookmark_v1"
    private(set) var bookmark: QuranBookmark? = nil
    
    private var lastSaveTime: Date = .distantPast
    private var pendingSaveTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Alten Lesezeichen-Key endgültig löschen
        UserDefaults.standard.removeObject(forKey: oldBookmarkKey)
        
        let stored = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        self.readFrontier = stored
        if let data = UserDefaults.standard.data(forKey: bookmarkKey),
           let bm = try? JSONDecoder().decode(QuranBookmark.self, from: data) {
            self.bookmark = bm
        }
        let bmStr = bookmark != nil ? "Vers #\(bookmark!.verseIndex) delta=\(String(format: "%.1f", bookmark!.delta))pt" : "keines"
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
        print("[QURAN_RESUME] Gespeichert: Vers #\(bookmark.verseIndex) delta=\(String(format: "%.1f", bookmark.delta))pt (fontSize: \(bookmark.fontSize))")
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
    
    // MARK: - Hebel A: In-Memory Puffer für neu gelesene Verse/Seiten
    private(set) var pendingVersesDelta: Int = 0
    private(set) var pendingPagesDelta: Int = 0
    private var pendingTrackingDate: Date? = nil
    private weak var lastModelContext: ModelContext? = nil
    
    /// Live-Zähler für Anzeige im Quran-Tab (gespeicherter Wert + Puffer)
    func liveVersesToday(baseCount: Int) -> Int {
        return baseCount + pendingVersesDelta
    }
    
    func livePagesToday(baseCount: Int) -> Int {
        return baseCount + pendingPagesDelta
    }
    
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
        
        self.lastModelContext = modelContext
        
        let (advanceState, advanceT0) = QuranPerf.shared.begin("1_advance_total")
        let oldFrontier = readFrontier
        let verseDelta = newIndex - oldFrontier
        
        var pageDelta = 0
        for idx in oldFrontier..<newIndex {
            if QuranAPIService.shared.isLastVerseOfPage(verseIndex: idx) {
                pageDelta += 1
            }
        }
        
        // 1a: readFrontier ändern (@Published Nachricht auslösen)
        let (pubState, pubT0) = QuranPerf.shared.begin("1a_publish_readFrontier")
        self.readFrontier = newIndex
        QuranPerf.shared.end("1a_publish_readFrontier", state: pubState, t0: pubT0, extra: "\(oldFrontier)->\(newIndex)")
        
        UserDefaults.standard.set(newIndex, forKey: "quranReadFrontier")
        // KEIN UserDefaults.standard.synchronize() im Scroll-Pfad (verhindert synchrones Disk-I/O Blocking)
        
        // 1b: Hebel A - In-Memory Pufferung statt synchroner DailyRecord/SwiftData Mutation bei jedem Vers!
        let (recState, recT0) = QuranPerf.shared.begin("1b_access_DailyRecord")
        let currentTrackingDate = LocationAndSolarManager.shared.getTrackingDate(for: date)
        if let pendingDate = pendingTrackingDate {
            let pendingDateStr = getIslamicDateString(for: pendingDate)
            let currentDateStr = getIslamicDateString(for: currentTrackingDate)
            if pendingDateStr != currentDateStr {
                print("[QURAN_BUFFER] Maghrib/Tageswechsel erkannt! Flushe vorherigen Tag (\(pendingDateStr)) vor Akkumulation von neuem Tag (\(currentDateStr)).")
                flushPendingChanges(modelContext: modelContext)
            }
        }
        
        self.pendingVersesDelta += verseDelta
        self.pendingPagesDelta += pageDelta
        self.pendingTrackingDate = currentTrackingDate
        QuranPerf.shared.end("1b_access_DailyRecord", state: recState, t0: recT0, extra: "delta: +\(verseDelta) (pending: \(pendingVersesDelta)V, \(pendingPagesDelta)S)")
        
        let newVerse = QuranAPIService.shared.getVerseAtIndex(newIndex - 1)
        let verseId = newVerse?.id ?? "index:\(newIndex)"
        
        QuranPerf.shared.end("1_advance_total", state: advanceState, t0: advanceT0, extra: "verse=\(verseId)")
        print("[QURAN_STATE] advance: neuer Wert im Speicher = \(self.readFrontier), Wert in UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier")), verse=\(verseId)")
        print("[QURAN_READ] advance to verse: \(verseId) (index \(newIndex)), old \(oldFrontier) -> new \(newIndex), verseDelta: +\(verseDelta), pageDelta: +\(pageDelta), pendingVerses: \(pendingVersesDelta), pendingPages: \(pendingPagesDelta)")
    }
    
    /// Hebel A: Schreibt alle gepufferten Verse und Seiten in SwiftData (todayRecord) und plant das Speichern.
    func flushPendingChanges(modelContext: ModelContext) {
        guard pendingVersesDelta > 0 || pendingPagesDelta > 0 else { return }
        guard let targetDate = pendingTrackingDate else { return }
        
        let (flushState, flushT0) = QuranPerf.shared.begin("1c_flush_DailyRecord")
        let versesToAdd = pendingVersesDelta
        let pagesToAdd = pendingPagesDelta
        let dateForFlush = targetDate
        
        // Puffer leeren vor Mutation (Schutz vor Reentrancy)
        self.pendingVersesDelta = 0
        self.pendingPagesDelta = 0
        self.pendingTrackingDate = nil
        
        let todayRecord = getCachedTodayRecord(in: modelContext, date: dateForFlush)
        todayRecord.quranVersesRead += versesToAdd
        todayRecord.quranPagesRead += pagesToAdd
        
        scheduleDebouncedSwiftDataSave(modelContext: modelContext)
        
        QuranPerf.shared.end("1c_flush_DailyRecord", state: flushState, t0: flushT0, extra: "+\(versesToAdd)V, +\(pagesToAdd)S")
        print("[QURAN_BUFFER] flushPendingChanges übertragen: +\(versesToAdd) Verse, +\(pagesToAdd) Seiten -> todayRecord(verses=\(todayRecord.quranVersesRead), pages=\(todayRecord.quranPagesRead), tag=\(getIslamicDateString(for: dateForFlush)))")
    }
    
    func resetKhatm(modelContext: ModelContext) {
        flushPendingChanges(modelContext: modelContext)
        let oldVal = readFrontier
        self.readFrontier = 0
        self.bookmark = nil
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(0, forKey: "quranReadFrontier")
        UserDefaults.standard.removeObject(forKey: oldBookmarkKey)
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        UserDefaults.standard.synchronize()
        try? modelContext.save()
        print("[QURAN_STATE] resetKhatm: alt \(oldVal) -> neu 0, UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier"))")
    }
    
    func setReadFrontier(_ newIndex: Int, modelContext: ModelContext) {
        flushPendingChanges(modelContext: modelContext)
        let clamped = max(0, min(newIndex, 6236))
        let oldVal = readFrontier
        self.readFrontier = clamped
        self.bookmark = nil
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(clamped, forKey: "quranReadFrontier")
        UserDefaults.standard.removeObject(forKey: oldBookmarkKey)
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        UserDefaults.standard.synchronize()
        try? modelContext.save()
        print("[QURAN_STATE] setReadFrontier manual debug override: alt \(oldVal) -> neu \(clamped), UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier"))")
    }
    
    private func scheduleDebouncedSwiftDataSave(modelContext: ModelContext) {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            let saveStart = CACurrentMediaTime()
            self.lastSaveTime = Date()
            try? modelContext.save()
            let saveMs = (CACurrentMediaTime() - saveStart) * 1000.0
            print("[QURAN_PERF] Debounced SwiftData save abgeschlossen: \(String(format: "%.2f", saveMs)) ms")
        }
    }
    
    private func flushPendingSaveImmediately() {
        if let mc = lastModelContext {
            flushPendingChanges(modelContext: mc)
            try? mc.save()
        }
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        lastSaveTime = Date()
        print("[PROGRESS_STORE] Flushed pending SwiftData save on app background/inactive")
    }
}

// MARK: - Performance Instrumentation (OSSignposter)
public final class QuranPerf {
    public static let shared = QuranPerf()
    public let poster = OSSignposter(subsystem: "com.yahyafaroun.ImanTrack", category: "QuranPerf")
    
    private init() {}
    
    @discardableResult
    @inline(__always)
    public func trace<T>(_ name: StaticString, extra: String = "", action: () throws -> T) rethrows -> T {
        let id = poster.makeSignpostID()
        let state = poster.beginInterval(name, id: id)
        let t0 = CACurrentMediaTime()
        defer {
            poster.endInterval(name, state)
            let dt = (CACurrentMediaTime() - t0) * 1000.0
            if !extra.isEmpty {
                print("[QURAN_PERF] \(name) [\(extra)]: \(String(format: "%.2f", dt)) ms")
            } else {
                print("[QURAN_PERF] \(name): \(String(format: "%.2f", dt)) ms")
            }
        }
        return try action()
    }
    
    @inline(__always)
    public func begin(_ name: StaticString) -> (OSSignpostIntervalState, Double) {
        let id = poster.makeSignpostID()
        let state = poster.beginInterval(name, id: id)
        let t0 = CACurrentMediaTime()
        return (state, t0)
    }
    
    @inline(__always)
    public func end(_ name: StaticString, state: OSSignpostIntervalState, t0: Double, extra: String = "") {
        poster.endInterval(name, state)
        let dt = (CACurrentMediaTime() - t0) * 1000.0
        if !extra.isEmpty {
            print("[QURAN_PERF] \(name) [\(extra)]: \(String(format: "%.2f", dt)) ms")
        } else {
            print("[QURAN_PERF] \(name): \(String(format: "%.2f", dt)) ms")
        }
    }
    
    @inline(__always)
    public func event(_ name: StaticString, message: String = "") {
        let id = poster.makeSignpostID()
        poster.emitEvent(name, id: id)
        if !message.isEmpty {
            print("[QURAN_EVENT] \(name): \(message)")
        } else {
            print("[QURAN_EVENT] \(name)")
        }
    }
}

