import Foundation

struct Verse: Codable, Identifiable, Equatable {
    let id: String // "surah:ayah" für Abwärtskompatibilität
    let apiId: Int
    let surah: Int
    let ayah: Int
    let arabic: String
    let textUthmani: String
    let pageNumber: Int
    let juzNumber: Int
    
    init(from api: APIVerse) {
        self.apiId = api.id
        self.ayah = api.verseNumber
        let qpcText = api.textQPCHafs?.trimmingCharacters(in: .whitespacesAndNewlines)
        let uthmaniText = api.textUthmani.trimmingCharacters(in: .whitespacesAndNewlines)
        self.arabic = (qpcText != nil && !qpcText!.isEmpty) ? qpcText! : uthmaniText
        self.textUthmani = uthmaniText
        self.pageNumber = api.pageNumber
        self.juzNumber = api.juzNumber
        
        // Extrahieren der Surah aus verse_key (z.B. "2:1")
        let parts = api.verseKey.components(separatedBy: ":")
        if parts.count >= 2, let s = Int(parts[0]) {
            self.surah = s
        } else {
            self.surah = 1
        }
        self.id = "\(self.surah):\(self.ayah)"
    }
    
    // Memberwise Initializer für Tests oder Cache-Kompatibilität
    init(id: String, apiId: Int, surah: Int, ayah: Int, arabic: String, textUthmani: String = "", pageNumber: Int, juzNumber: Int) {
        self.id = id
        self.apiId = apiId
        self.surah = surah
        self.ayah = ayah
        self.arabic = arabic
        self.textUthmani = textUthmani.isEmpty ? arabic : textUthmani
        self.pageNumber = pageNumber
        self.juzNumber = juzNumber
    }
}

struct APIVerse: Codable {
    let id: Int
    let verseNumber: Int
    let verseKey: String
    let textUthmani: String
    let textQPCHafs: String?
    let pageNumber: Int
    let juzNumber: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case verseNumber = "verse_number"
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
        case textQPCHafs = "text_qpc_hafs"
        case pageNumber = "page_number"
        case juzNumber = "juz_number"
    }
}

struct QuranAPIResponse: Codable {
    let verses: [APIVerse]
}
