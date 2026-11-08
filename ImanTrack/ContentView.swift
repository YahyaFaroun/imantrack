import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var settings: [UserSettings]
    @State var selectedTab = 2 // 2 is Heute (0-indexed)
    @StateObject private var quranViewModel = QuranViewModel()
    @StateObject private var solarManager = LocationAndSolarManager.shared

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
        
        ZStack(alignment: .top) {
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
                
                QuranView(viewModel: quranViewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label(L10n.tr("tab_quran", language), systemImage: "book.fill")
                    }
                    .tag(3)
                
                StatsView(selectedTab: $selectedTab)
                    .tabItem {
                        Label(L10n.tr("tab_stats", language), systemImage: "chart.bar.fill")
                    }
                    .tag(4)
            }
            .tint(Theme.islamicGreen)
            
            // App-weites 5-Minuten-Warnungs Pop-up (für alle Tabs außer Heute, da Heute es inline hat)
            if solarManager.showFiveMinuteWarning && selectedTab != 2 {
                MaghribFiveMinuteWarningBanner(language: language) {
                    solarManager.dismissFiveMinuteWarning()
                }
                .padding(.top, 45)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
            
            // App-weiter Tages-Reset Toast (für alle Tabs außer Heute)
            if solarManager.showDayResetToast && selectedTab != 2 {
                VStack {
                    Spacer()
                    MaghribDayResetToast(language: language)
                        .padding(.bottom, 65)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(101)
            }
        }
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
