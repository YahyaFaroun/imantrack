import Foundation
import UIKit

class QuranAPIService {
    static let shared = QuranAPIService()
    
    private var allVerses: [Verse]? = nil
    
    // Asynchronous method to keep compatibility with existing code
    func fetchPage(pageNumber: Int) async throws -> [Verse] {
        // Load data on first request
        if allVerses == nil {
            try await loadOfflineData()
        }
        
        guard let verses = allVerses else {
            throw URLError(.cannotDecodeRawData)
        }
        
        // Return verses for the requested page
        return verses.filter { $0.pageNumber == pageNumber }
    }
    
    func fetchSurah(surahNumber: Int) async throws -> [Verse] {
        if allVerses == nil {
            try await loadOfflineData()
        }
        
        guard let verses = allVerses else {
            throw URLError(.cannotDecodeRawData)
        }
        
        return verses.filter { $0.surah == surahNumber }.sorted { $0.ayah < $1.ayah }
    }
    
    private func loadOfflineDataSync() {
        guard allVerses == nil, let asset = NSDataAsset(name: "quran_offline") else { return }
        if let apiVerses = try? JSONDecoder().decode([APIVerse].self, from: asset.data) {
            self.allVerses = apiVerses.map { Verse(from: $0) }
        }
    }
    
    func getVerse(id: String) -> Verse? {
        loadOfflineDataSync()
        return allVerses?.first { $0.id == id }
    }
    
    func getNextVerse(after verseId: String) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses, !verseId.isEmpty else { return nil }
        if let currentIndex = verses.firstIndex(where: { $0.id == verseId }) {
            let nextIndex = currentIndex + 1
            if nextIndex < verses.count {
                return verses[nextIndex]
            }
        }
        return nil
    }
    
    func getPreviousVerse(before verseId: String) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses, !verseId.isEmpty else { return nil }
        if let currentIndex = verses.firstIndex(where: { $0.id == verseId }) {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                return verses[prevIndex]
            }
        }
        return nil
    }
    
    func findFirstUnreadVerse(globalReadVerseIds: Set<String>) -> Verse? {
        loadOfflineDataSync()
        guard let verses = allVerses else { return nil }
        return verses.first { !globalReadVerseIds.contains($0.id) }
    }

    private func loadOfflineData() async throws {
        // Load the dataset from Assets Catalog
        guard let asset = NSDataAsset(name: "quran_offline") else {
            print("Error: Could not find quran_offline dataset in Assets")
            throw URLError(.fileDoesNotExist)
        }
        
        let apiVerses = try JSONDecoder().decode([APIVerse].self, from: asset.data)
        self.allVerses = apiVerses.map { Verse(from: $0) }
    }
}
