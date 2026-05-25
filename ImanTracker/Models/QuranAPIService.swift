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
    
    private func loadOfflineData() async throws {
        // Load the dataset from Assets.xcassets
        guard let dataAsset = NSDataAsset(name: "quran_offline") else {
            print("Error: Could not find quran_offline dataset in Assets")
            throw URLError(.fileDoesNotExist)
        }
        
        let apiVerses = try JSONDecoder().decode([APIVerse].self, from: dataAsset.data)
        self.allVerses = apiVerses.map { Verse(from: $0) }
    }
}
