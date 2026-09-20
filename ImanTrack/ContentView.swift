import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var settings: [UserSettings]
    @State var selectedTab = 2 // 2 is Heute (0-indexed)
    @StateObject private var quranViewModel = QuranViewModel()

    #if os(iOS) && !SKIP
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor(Theme.islamicGreen)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.islamicGreen)]
        appearance.stackedLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    #endif

    private var tabSelectionBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab && newValue == 3 {
                    NotificationCenter.default.post(name: Notification.Name("QuranTabRetapped"), object: nil)
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        let isDark = settings.first?.isDarkMode ?? true
        let language: String = {
            if let lang = settings.first?.language {
                return lang
            }
            let locale = Locale.current.language.languageCode?.identifier ?? "en"
            return ["de", "en", "ar"].contains(locale) ? locale : "en"
        }()
        
        let isRTL = ["ar", "ur", "fa", "ps", "ku", "he"].contains(language)
        
        TabView(selection: tabSelectionBinding) {
            TasbihView()
                .tabItem {
                    Label(L10n.tr("tab_tasbih", language), systemImage: "circle.hexagongrid.fill")
                }
                .tag(0)
            
            AdhkarOverviewView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.tr("tab_adhkar", language), systemImage: "book.closed.fill")
                }
                .tag(1)
            
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.tr("tab_today", language), systemImage: "house.fill")
                }
                .tag(2)
            
            QuranView(viewModel: quranViewModel)
                .tabItem {
                    Label(L10n.tr("tab_quran", language), systemImage: "book.fill")
                }
                .tag(3)
            
            StatsView()
                .tabItem {
                    Label(L10n.tr("tab_stats", language), systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(Theme.islamicGreen)
        .preferredColorScheme(isDark ? .dark : .light)
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        .onAppear {
            LocationAndSolarManager.shared.requestAuthorization()
            if settings.isEmpty {
                let defaultSettings = UserSettings()
                modelContext.insert(defaultSettings)
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
}
