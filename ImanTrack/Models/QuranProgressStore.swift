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
    @Published var khatmResetToken: UUID = UUID()
    @Published var showRestoreNotice: Bool = false
    @Published var restoredLocationInfo: (surah: Int, ayah: Int, page: Int)? = nil
    @Published private(set) var khatmCount: Int = UserDefaults.standard.integer(forKey: "quranKhatmCount")
    
    private let oldBookmarkKey = "quranBookmark"
    private let bookmarkKey = "quranFrontierBookmark_v1"
    private(set) var bookmark: QuranBookmark? = nil
    
    private var lastSaveTime: Date = .distantPast
    private var pendingSaveTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Alten Lesezeichen-Key löschen, alte Lesestandsdaten (currentKhatmReadVerseIds etc.) NIE löschen!
        UserDefaults.standard.removeObject(forKey: oldBookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        
        let stored = UserDefaults.standard.integer(forKey: "quranReadFrontier")
        self.readFrontier = stored
        if let data = UserDefaults.standard.data(forKey: bookmarkKey),
           let bm = try? JSONDecoder().decode(QuranBookmark.self, from: data) {
            self.bookmark = bm
        }
        let bmStr = bookmark != nil ? "Vers #\(bookmark!.verseIndex) delta=\(String(format: "%.1f", bookmark!.delta))pt" : "keines"
        print("[QURAN_STATE] Store-init: readFrontier im Speicher = \(readFrontier), Wert in UserDefaults = \(stored), Lesezeichen=\(bmStr)")
        
        migrateIfNeeded()
        checkAndPerformRepairV2()
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
        
        // Khatm-Zähler zuverlässig inkrementieren
        let currentKhatm = UserDefaults.standard.integer(forKey: "quranKhatmCount")
        let updatedKhatm = currentKhatm + 1
        UserDefaults.standard.set(updatedKhatm, forKey: "quranKhatmCount")
        self.khatmCount = updatedKhatm
        
        UserDefaults.standard.synchronize()
        try? modelContext.save()
        self.khatmResetToken = UUID()
        print("[QURAN_STATE] resetKhatm: alt \(oldVal) -> neu 0, KhatmCount=\(updatedKhatm), token = \(self.khatmResetToken)")
        NotificationCenter.default.post(name: Notification.Name("ResetQuranStartPage"), object: nil)
    }
    
    /// Manuelles Festlegen der Lesestelle (ohne die Tagesstatistiken zu berühren!)
    func setReadFrontierManually(toIndex: Int) {
        let clamped = max(0, min(toIndex, 6236))
        let oldVal = readFrontier
        self.readFrontier = clamped
        self.bookmark = QuranBookmark(verseIndex: clamped, delta: 0, fontSize: 30)
        self.cachedTodayRecord = nil
        self.cachedTrackingDateString = nil
        UserDefaults.standard.set(clamped, forKey: "quranReadFrontier")
        if let data = try? JSONEncoder().encode(self.bookmark) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
        UserDefaults.standard.removeObject(forKey: oldBookmarkKey)
        UserDefaults.standard.removeObject(forKey: "quranResumeAnchor")
        UserDefaults.standard.synchronize()
        self.khatmResetToken = UUID()
        print("[QURAN_STATE] setReadFrontierManually: alt \(oldVal) -> neu \(clamped)")
        NotificationCenter.default.post(name: Notification.Name("ResetQuranStartPage"), object: nil)
    }
    
    func dismissRestoreNotice() {
        self.showRestoreNotice = false
        self.restoredLocationInfo = nil
    }
    
    // MARK: - Einmalige Reparatur V2 für 3.0.0-Nutzer
    func checkAndPerformRepairV2() {
        let repairKey = "hasRepairedMigration_v2"
        guard !UserDefaults.standard.bool(forKey: repairKey) else { return }
        
        guard let restored = QuranMigrationV2.findRobustPreUpdatePosition() else {
            UserDefaults.standard.set(true, forKey: repairKey)
            UserDefaults.standard.synchronize()
            return
        }
        
        let currentFrontier = self.readFrontier
        let shouldRestore: Bool
        
        if currentFrontier < 100 && restored.frontierIndex >= 100 {
            // Eindeutiger Fehl-Reset auf Al-Fatiha!
            shouldRestore = true
        } else if currentFrontier > restored.frontierIndex + 300 {
            // Großer Sprung nach vorne (z. B. am Koran-Ende gestrandet)
            shouldRestore = true
        } else {
            shouldRestore = false
        }
        
        if shouldRestore {
            self.readFrontier = restored.frontierIndex
            UserDefaults.standard.set(restored.frontierIndex, forKey: "quranReadFrontier")
            
            let bm = QuranBookmark(verseIndex: restored.frontierIndex, delta: 0, fontSize: 30)
            self.bookmark = bm
            if let data = try? JSONEncoder().encode(bm) {
                UserDefaults.standard.set(data, forKey: bookmarkKey)
            }
            UserDefaults.standard.synchronize()
            
            self.showRestoreNotice = true
            self.restoredLocationInfo = (surah: restored.surah, ayah: restored.ayah, page: restored.page)
            print("[MIGRATION_V2] Erfolgreich wiederhergestellt auf Vers \(restored.surah):\(restored.ayah) (S. \(restored.page), Index \(restored.frontierIndex), Grund: \(restored.reason))")
        } else {
            print("[MIGRATION_V2] Keine Wiederherstellung nötig. Stand \(currentFrontier) plausibel zu historischem Stand \(restored.frontierIndex).")
        }
        
        UserDefaults.standard.set(true, forKey: repairKey)
        UserDefaults.standard.synchronize()
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
        self.khatmResetToken = UUID()
        print("[QURAN_STATE] setReadFrontier manual debug override: alt \(oldVal) -> neu \(clamped), UserDefaults = \(UserDefaults.standard.integer(forKey: "quranReadFrontier")), token = \(self.khatmResetToken)")
        NotificationCenter.default.post(name: Notification.Name("ResetQuranStartPage"), object: nil)
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

// MARK: - Robuste Migration & Reparatur V2
struct QuranMigrationV2 {
    struct RestoreResult {
        let frontierIndex: Int
        let surah: Int
        let ayah: Int
        let page: Int
        let reason: String
    }
    
    @MainActor
    static func findRobustPreUpdatePosition() -> RestoreResult? {
        // 1. HAUPTQUELLE: Jüngste Lesetage VOR dem 3.0.0-Update
        if let result = findFromRecentDailyPages() {
            return result
        }
        
        // 2. FALLBACK: Kontinuitäts-Scan auf Vers-Sets (Lücken-Toleranz)
        if let result = findFromVerseSets() {
            return result
        }
        
        // 3. LETZTER FALLBACK: quranLastReadPage oder quranHighestReadPage
        let lastPage = UserDefaults.standard.integer(forKey: "quranLastReadPage")
        let highest = UserDefaults.standard.integer(forKey: "quranHighestReadPage")
        let candidatePage = (lastPage > 0 && lastPage < 604) ? lastPage : ((highest > 0 && highest < 604) ? highest : 0)
        if candidatePage > 0 {
            let verses = QuranAPIService.shared.getVersesForPage(pageNumber: candidatePage)
            if let v = verses.first, let idx = QuranAPIService.shared.getVerseIndex(id: v.id) {
                return RestoreResult(frontierIndex: idx, surah: v.surah, ayah: v.ayah, page: candidatePage, reason: "fallbackPage(\(candidatePage))")
            }
        }
        
        return nil
    }
    
    @MainActor
    private static func findFromRecentDailyPages() -> RestoreResult? {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let pageKeys = allKeys.filter { $0.hasPrefix("quran_read_pages_") }
        guard !pageKeys.isEmpty else { return nil }
        
        var dateToPages: [(dateStr: String, pages: [Int])] = []
        for key in pageKeys {
            let dateStr = String(key.dropFirst("quran_read_pages_".count))
            if let pages = UserDefaults.standard.array(forKey: key) as? [Int], !pages.isEmpty {
                dateToPages.append((dateStr, pages))
            }
        }
        
        // Absteigend sortieren (neueste Tage zuerst)
        dateToPages.sort { $0.dateStr > $1.dateStr }
        
        // Post-Reset Tage ausschließen: Tage ab 2026-10-20, an denen nur Seiten <= 10 gelesen wurden,
        // während frühere Tage Seiten >= 20 enthalten.
        let hasEarlierHighPages = dateToPages.contains { entry in
            entry.pages.contains { $0 >= 20 }
        }
        
        var preUpdateDays: [(dateStr: String, pages: [Int])] = []
        for entry in dateToPages {
            let isPostReset = hasEarlierHighPages && entry.dateStr >= "2026-10-20" && entry.pages.allSatisfy { $0 <= 10 }
            if !isPostReset {
                preUpdateDays.append(entry)
            }
        }
        
        guard !preUpdateDays.isEmpty else { return nil }
        
        // Jüngste Lesetage betrachten (bis zu 14 aktive Tage)
        let recentDays = Array(preUpdateDays.prefix(14))
        var recentPages = Set<Int>()
        for day in recentDays {
            recentPages.formUnion(day.pages)
        }
        guard !recentPages.isEmpty else { return nil }
        
        let sortedPages = recentPages.sorted()
        
        // Cluster bilden: Seiten gruppieren, deren Abstand <= 10 ist
        var clusters: [[Int]] = []
        var currentCluster: [Int] = []
        for p in sortedPages {
            if let last = currentCluster.last, p - last > 10 {
                clusters.append(currentCluster)
                currentCluster = [p]
            } else {
                currentCluster.append(p)
            }
        }
        if !currentCluster.isEmpty {
            clusters.append(currentCluster)
        }
        
        // Das Cluster der jüngsten Lesesitzung finden (enthält Seiten des allerletzten Pre-Update-Tages)
        let latestDayPages = Set(preUpdateDays[0].pages)
        var bestCluster: [Int]? = nil
        for cluster in clusters {
            let overlap = Set(cluster).intersection(latestDayPages)
            if !overlap.isEmpty {
                if bestCluster == nil || cluster.count > (bestCluster?.count ?? 0) {
                    bestCluster = cluster
                }
            }
        }
        
        let activeCluster = bestCluster ?? clusters.last ?? sortedPages
        guard let targetPage = activeCluster.max() else { return nil }
        
        // Lesefront auf die Folgeseite bzw. Anfang der nächsten Lesestelle
        let resolvedPage = min(604, targetPage + 1)
        let verses = QuranAPIService.shared.getVersesForPage(pageNumber: resolvedPage)
        if let v = verses.first, let idx = QuranAPIService.shared.getVerseIndex(id: v.id) {
            return RestoreResult(frontierIndex: idx, surah: v.surah, ayah: v.ayah, page: resolvedPage, reason: "recentDailyPages(S.\(targetPage))")
        }
        
        return nil
    }
    
    @MainActor
    private static func findFromVerseSets() -> RestoreResult? {
        let rawData = UserDefaults.standard.data(forKey: "currentKhatmReadVerseIds") ??
                      UserDefaults.standard.data(forKey: "globalReadVerseIds")
        guard let data = rawData,
              let ids = try? JSONDecoder().decode([String].self, from: data),
              !ids.isEmpty else { return nil }
        
        var readIndices = Set<Int>()
        for id in ids {
            if let idx = QuranAPIService.shared.getVerseIndex(id: id) {
                readIndices.insert(idx)
            }
        }
        guard !readIndices.isEmpty else { return nil }
        
        var highestContinuousIndex = 0
        var consecutiveUnread = 0
        
        for idx in 0..<6236 {
            if readIndices.contains(idx) {
                highestContinuousIndex = idx
                consecutiveUnread = 0
            } else {
                consecutiveUnread += 1
                if consecutiveUnread >= 15 {
                    break
                }
            }
        }
        
        let targetIdx = highestContinuousIndex + 1
        if let v = QuranAPIService.shared.getVerseAtIndex(targetIdx) {
            return RestoreResult(frontierIndex: targetIdx, surah: v.surah, ayah: v.ayah, page: v.pageNumber, reason: "verseSetContinuity")
        }
        return nil
    }
}


