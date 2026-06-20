import Foundation
import SwiftData

@Model
final class CustomTasbih {
    @Attribute(.unique) var id: String
    var title: String
    var arabic: String
    var transliteration: String
    var goal: Int
    var isEnabled: Bool
    var createdAt: Date
    
    init(title: String, arabic: String = "", transliteration: String = "", goal: Int = 100, isEnabled: Bool = true) {
        self.id = UUID().uuidString
        self.title = title
        self.arabic = arabic
        self.transliteration = transliteration
        self.goal = goal
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}
