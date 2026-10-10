import Foundation
import UIKit
import Combine

class QuranAPIService: ObservableObject {
    static let shared = QuranAPIService()
    
    @Published private(set) var isLoaded: Bool = false
    
    private var allVerses: [Verse]? = nil
    private var pageToVersesMap: [Int: [Verse]] = [:]
    private var verseByIdMap: [String: Verse] = [:]
    private var verseIndexMap: [String: Int] = [:]
    private var pageToVerseIdsMap: [Int: Set<String>] = [:]
    private var pageLastVerseIndexMap: [Int: Int] = [:]
    
    init() {
        // Starte das Laden im Hintergrund beim Erstellen des Singletons
        preloadDataAsync()
    }
    
    func preloadDataAsync() {
        guard !isLoaded else { return }
        Task.detached(priority: .userInitiated) {
            self.loadOfflineDataSync()
        }
    }
    
    // Asynchronous method to keep compatibility with existing code
    func fetchPage(pageNumber: Int) async throws -> [Verse] {
        if allVerses == nil {
            try await loadOfflineData()
        }
        return getVersesForPage(pageNumber: pageNumber)
    }
    
    func getVersesForPage(pageNumber: Int) -> [Verse] {
        loadOfflineDataSync()
        return pageToVersesMap[pageNumber] ?? []
    }
    
    func isPageFullyRead(pageNumber: Int, readVerseIds: Set<String>) -> Bool {
        loadOfflineDataSync()
        guard let verseIds = pageToVerseIdsMap[pageNumber], !verseIds.isEmpty else { return false }
        return verseIds.isSubset(of: readVerseIds)
    }

    func isPageFullyRead(pageNumber: Int, readFrontier: Int) -> Bool {
        loadOfflineDataSync()
        guard let lastIdx = pageLastVerseIndexMap[pageNumber] else { return false }
        return readFrontier > lastIdx
    }
    
    func fetchSurah(surahNumber: Int) async throws -> [Verse] {
        if allVerses == nil {
            try await loadOfflineData()
        }
        guard let verses = allVerses else { throw URLError(.cannotDecodeRawData) }
        return verses.filter { $0.surah == surahNumber }.sorted { $0.ayah < $1.ayah }
    }
    
    private func loadOfflineDataSync() {
        guard allVerses == nil, let asset = NSDataAsset(name: "quran_offline") else { return }
        if let apiVerses = try? JSONDecoder().decode([APIVerse].self, from: asset.data) {
            let verses = apiVerses.map { Verse(from: $0) }
            self.allVerses = verses
            buildCaches(verses: verses)
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        }
    }
    
    private func buildCaches(verses: [Verse]) {
        var pageMap: [Int: [Verse]] = [:]
        var byIdMap: [String: Verse] = [:]
        var idxMap: [String: Int] = [:]
        var pageIdsMap: [Int: Set<String>] = [:]
        var lastIdxMap: [Int: Int] = [:]
        
        for (index, verse) in verses.enumerated() {
            pageMap[verse.pageNumber, default: []].append(verse)
            byIdMap[verse.id] = verse
            idxMap[verse.id] = index
            pageIdsMap[verse.pageNumber, default: []].insert(verse.id)
            lastIdxMap[verse.pageNumber] = index
        }
        
        self.pageToVersesMap = pageMap
        self.verseByIdMap = byIdMap
        self.verseIndexMap = idxMap
        self.pageToVerseIdsMap = pageIdsMap
        self.pageLastVerseIndexMap = lastIdxMap
    }
    
    func getVerse(id: String) -> Verse? {
        loadOfflineDataSync()
        return verseByIdMap[id]
    }

    func getVerseIndex(id: String) -> Int? {
        loadOfflineDataSync()
        return verseIndexMap[id]
    }

    func getVerseIndex(surah: Int, ayah: Int) -> Int? {
        loadOfflineDataSync()
        guard let verses = allVerses else { return nil }
        return verses.firstIndex(where: { $0.surah == surah && $0.ayah == ayah })
    }

    func getVerseCount(surah: Int) -> Int {
        loadOfflineDataSync()
        guard let verses = allVerses else { return 1 }
        return verses.filter { $0.surah == surah }.count
    }

    func getVerseAtIndex(_ index: Int) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses, index >= 0 && index < verses.count else { return nil }
        return verses[index]
    }

    func totalVerseCount() -> Int {
        loadOfflineDataSync()
        return allVerses?.count ?? 6236
    }

    func getAllVerses() -> [Verse] {
        loadOfflineDataSync()
        return allVerses ?? []
    }

    func isLastVerseOfPage(verseIndex: Int) -> Bool {
        loadOfflineDataSync()
        guard let verse = getVerseAtIndex(verseIndex),
              let lastIdx = pageLastVerseIndexMap[verse.pageNumber] else { return false }
        return verseIndex == lastIdx
    }
    
    func getNextVerse(after verseId: String) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses, !verseId.isEmpty, let currentIndex = verseIndexMap[verseId] else { return nil }
        let nextIndex = currentIndex + 1
        if nextIndex < verses.count {
            return verses[nextIndex]
        }
        return nil
    }
    
    func getPreviousVerse(before verseId: String) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses, !verseId.isEmpty, let currentIndex = verseIndexMap[verseId] else { return nil }
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            return verses[prevIndex]
        }
        return nil
    }
    

    func findFirstUnreadVerse(readFrontier: Int) -> Verse? {
        return getVerseAtIndex(readFrontier)
    }

    func getAllVerseIdsUpTo(verseId: String) -> [String] {
        loadOfflineDataSync()
        guard let verses = allVerses, let idx = verseIndexMap[verseId] else { return [verseId] }
        return Array(verses[0...idx].map { $0.id })
    }

    func isVerseAfter(verseA: String, verseB: String) -> Bool {
        if verseB.isEmpty { return true }
        if verseA == verseB { return false }
        loadOfflineDataSync()
        guard let idxA = verseIndexMap[verseA], let idxB = verseIndexMap[verseB] else { return false }
        return idxA > idxB
    }

    private func loadOfflineData() async throws {
        guard let asset = NSDataAsset(name: "quran_offline") else {
            print("Error: Could not find quran_offline dataset in Assets")
            throw URLError(.fileDoesNotExist)
        }
        
        let apiVerses = try JSONDecoder().decode([APIVerse].self, from: asset.data)
        let verses = apiVerses.map { Verse(from: $0) }
        self.allVerses = verses
        buildCaches(verses: verses)
        DispatchQueue.main.async {
            self.isLoaded = true
        }
    }
}
