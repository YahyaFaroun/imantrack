import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [UserSettings]
    @State private var selectedTab = 2 // 2 is Heute (0-indexed)

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

    var body: some View {
        let isDark = settings.first?.isDarkMode ?? true
        let language = settings.first?.language ?? "de"
        
        TabView(selection: $selectedTab) {
            TasbihView()
                .tabItem {
                    Label(L10n.tr("tab_tasbih", language), systemImage: "circle.grid.3x3.fill")
                }
                .tag(0)
            
            AdhkarOverviewView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.tr("tab_adhkar", language), systemImage: "doc.plaintext.fill")
                }
                .tag(1)
            
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.tr("tab_today", language), systemImage: "house.fill")
                }
                .tag(2)
            
            QuranView()
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
        .environment(\.layoutDirection, language == "ar" ? .rightToLeft : .leftToRight)
        .onAppear {
            LocationAndSolarManager.shared.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
