import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allDailyRecords: [DailyRecord]
    
    @Binding var selectedTab: Int
    @State private var showSettings = false
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    func formattedDate(for lang: String) -> String {
        let formatter = DateFormatter()
        switch lang.lowercased() {
        case "ar":
            formatter.locale = Locale(identifier: "ar_SA")
            formatter.dateFormat = "EEEE, d MMMM"
        case "en":
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE, MMMM d"
        default:
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "EEEE, d. MMMM"
        }
        return formatter.string(from: solarManager.currentTrackingDate)
    }
    
    var body: some View {
        let lang = settings.language
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.top, 20)
                            
                            Text(formattedDate(for: lang))
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        // Result Card 1: Koran
                        ResultCard(title: L10n.tr("tab_quran", lang), systemImage: "book.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(format: L10n.tr("quran_pages_read_goal", lang), todayRecord.quranPagesRead, max(1, settings.quranDailyGoal)))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                ProgressView(value: min(Double(todayRecord.quranPagesRead) / Double(max(1, settings.quranDailyGoal)), 1.0))
                                    .tint(Theme.islamicGreen)
                                
                                Text("\(todayRecord.quranVersesRead) Verse gelesen")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onTapGesture {
                            selectedTab = 3
                        }
                        
                        // Result Card 2: Adhkar
                        ResultCard(title: L10n.tr("tab_adhkar", lang), systemImage: "doc.plaintext.fill") {
                            VStack(spacing: 12) {
                                AdhkarResultRow(title: L10n.tr("adhkar_morning", lang), isDone: todayRecord.morgenAdhkarDone, time: todayRecord.morgenAdhkarTime)
                                AdhkarResultRow(title: L10n.tr("adhkar_evening", lang), isDone: todayRecord.abendAdhkarDone, time: todayRecord.abendAdhkarTime)
                                AdhkarResultRow(title: L10n.tr("adhkar_sleep", lang), isDone: todayRecord.schlafAdhkarDone, time: todayRecord.schlafAdhkarTime)
                                if Calendar.current.component(.weekday, from: solarManager.currentTrackingDate) == 6 {
                                    AdhkarResultRow(title: L10n.tr("surah_alkahf", lang), isDone: todayRecord.surahAlKahfDone, time: todayRecord.surahAlKahfTime)
                                }
                            }
                        }
                        .onTapGesture {
                            selectedTab = 1
                        }
                        
                        // Result Card 3: Tasbih
                        ResultCard(title: L10n.tr("tab_tasbih", lang), systemImage: "circle.grid.3x3.fill") {
                            VStack(spacing: 10) {
                                if settings.istighfarEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_istighfar", lang), count: todayRecord.totalIstighfarCount, goal: settings.istighfarGoal)
                                }
                                if settings.salawatEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_salawat", lang), count: todayRecord.totalSalawatCount, goal: settings.salawatGoal)
                                }
                                if settings.subhanAllahEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_subhanallah", lang), count: todayRecord.subhanAllahCount, goal: settings.subhanAllahGoal)
                                }
                                if settings.alhamdulillahEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_alhamdulillah", lang), count: todayRecord.alhamdulillahCount, goal: settings.alhamdulillahGoal)
                                }
                                if settings.allahuAkbarEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_lahawla", lang), count: todayRecord.allahuAkbarCount, goal: settings.allahuAkbarGoal)
                                }
                            }
                        }
                        .onTapGesture {
                            selectedTab = 0
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct ResultCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(Theme.islamicGreen)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct AdhkarResultRow: View {
    let title: String
    let isDone: Bool
    let time: Date?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            if isDone {
                if let time = time {
                    Text(time, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text("✓")
                    .foregroundColor(Theme.islamicGreen)
                    .fontWeight(.bold)
            } else {
                Text("○")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct TasbihResultRow: View {
    let title: String
    let count: Int
    let goal: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(count) / \(goal)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            ProgressView(value: min(Double(count) / Double(max(1, goal)), 1.0))
                .tint(Theme.islamicGreen)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
    }
}
