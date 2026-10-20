import SwiftUI
import SwiftData

struct FAQItem: Identifiable, Codable {
    var id: String { question }
    let question: String
    let answer: String
}

private struct RawFAQSection: Codable {
    let title: String
    let icon: String
    let iconColor: String
    let items: [FAQItem]
}

private struct RawFAQLanguageData: Codable {
    let navTitle: String
    let bannerTitle: String
    let bannerDesc: String
    let sections: [RawFAQSection]
}

struct FAQSection: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let iconColor: Color
    let items: [FAQItem]
}

struct FAQView: View {
    @Query private var settingsList: [UserSettings]
    @State private var expandedItems: Set<String> = []
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    private var localizedData: (navTitle: String, bannerTitle: String, bannerDesc: String, sections: [FAQSection]) {
        FAQLanguageData.getData(for: language)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.islamicGreen)
                    
                    Text(localizedData.bannerTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(localizedData.bannerDesc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                
                // Kategorien mit FAQ-Items
                ForEach(localizedData.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Kategorie Header
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .foregroundColor(section.iconColor)
                                .font(.headline)
                            
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Fragen-Liste
                        VStack(spacing: 10) {
                            ForEach(section.items) { item in
                                FAQCardView(
                                    item: item,
                                    isExpanded: expandedItems.contains(item.id),
                                    onToggle: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            if expandedItems.contains(item.id) {
                                                expandedItems.remove(item.id)
                                            } else {
                                                expandedItems.insert(item.id)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle(localizedData.navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Eine klickbare FAQ-Karte für jede Frage
struct FAQCardView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(item.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .padding(.top, 2)
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Localized FAQ Data Loader
struct FAQLanguageData {
    private static let cachedData: [String: RawFAQLanguageData] = loadFAQData()
    
    private static func loadFAQData() -> [String: RawFAQLanguageData] {
        guard let url = Bundle.main.url(forResource: "FAQ", withExtension: "json") ??
                        Bundle(for: BundleToken.self).url(forResource: "FAQ", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: RawFAQLanguageData].self, from: data)) ?? [:]
    }
    
    static func getData(for lang: String) -> (navTitle: String, bannerTitle: String, bannerDesc: String, sections: [FAQSection]) {
        // Fallback-Kette: gewählte Sprache -> Englisch ("en") -> Deutsch ("de")
        let raw = cachedData[lang] ?? cachedData["en"] ?? cachedData["de"]
        guard let raw = raw else {
            return ("FAQ & Help", "FAQ", "", [])
        }
        
        let sections = raw.sections.map { s in
            FAQSection(
                title: s.title,
                icon: s.icon,
                iconColor: colorForName(s.iconColor),
                items: s.items
            )
        }
        
        return (raw.navTitle, raw.bannerTitle, raw.bannerDesc, sections)
    }
    
    private static func colorForName(_ name: String) -> Color {
        switch name {
        case "islamicGreen":
            return Theme.islamicGreen
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "blue":
            return .blue
        case "indigo":
            return .indigo
        default:
            return Theme.islamicGreen
        }
    }
}

private final class BundleToken {}
