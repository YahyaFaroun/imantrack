import SwiftUI
import SwiftData

struct AdhkarOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    @Query private var settingsList: [UserSettings]
    
    @Binding var selectedTab: Int
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    @AppStorage("lastActiveSessionId") private var lastActiveSessionId: String = ""
    @AppStorage("lastActiveDhikrIndex") private var lastActiveDhikrIndex: Int = 0
    @AppStorage("lastActiveDhikrCount") private var lastActiveDhikrCount: Int = 0
    @AppStorage("isSessionActive") private var isSessionActive: Bool = false
    
    private var isFriday: Bool {
        let cal = Calendar.current
        let today = solarManager.currentTrackingDate
        let weekday = cal.component(.weekday, from: today)
        return weekday == 6 // Freitag = 6
    }
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    @State private var activeSessionType: AdhkarSessionType? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Button {
                            activeSessionType = .morning
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_morning", language),
                                icon: "sunrise.fill",
                                isDone: todayRecord.morgenAdhkarDone,
                                language: language
                            )
                        }
                        
                        Button {
                            activeSessionType = .evening
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_evening", language),
                                icon: "moon.fill",
                                isDone: todayRecord.abendAdhkarDone,
                                language: language
                            )
                        }
                        
                        Button {
                            activeSessionType = .sleep
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_sleep", language),
                                icon: "bed.double.fill",
                                isDone: todayRecord.schlafAdhkarDone,
                                language: language
                            )
                        }
                        
                        if isFriday {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.islamicGreen.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "book.closed.fill")
                                            .font(.title2)
                                            .foregroundColor(Theme.islamicGreen)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.tr("surah_alkahf", language))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(L10n.tr("surah_alkahf_desc", language))
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                        
                                        if todayRecord.surahAlKahfDone {
                                            Text(L10n.tr("today_done", language))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.islamicGreen)
                                        } else {
                                            Text(L10n.tr("pending", language))
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        todayRecord.surahAlKahfDone.toggle()
                                        if todayRecord.surahAlKahfDone {
                                            todayRecord.surahAlKahfTime = Date()
                                        } else {
                                            todayRecord.surahAlKahfTime = nil
                                        }
                                        try? modelContext.save()
                                    } label: {
                                        Image(systemName: todayRecord.surahAlKahfDone ? "checkmark.circle.fill" : "circle")
                                            .font(.title)
                                            .foregroundColor(todayRecord.surahAlKahfDone ? Theme.islamicGreen : .gray)
                                    }
                                }
                                
                                Button {
                                    UserDefaults.standard.set(293, forKey: "quranLastReadPage")
                                    selectedTab = 3
                                } label: {
                                    HStack {
                                        Image(systemName: "book.fill")
                                        Text(L10n.tr("read_now", language))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Theme.islamicGreen.opacity(0.15))
                                    .foregroundColor(Theme.islamicGreen)
                                    .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.tr("tab_adhkar", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(item: $activeSessionType) { type in
                AdhkarSessionView(type: type)
            }
            .onAppear {
                if isSessionActive, !lastActiveSessionId.isEmpty {
                    if lastActiveSessionId == "morning" {
                        activeSessionType = .morning
                    } else if lastActiveSessionId == "evening" {
                        activeSessionType = .evening
                    } else if lastActiveSessionId == "sleep" {
                        activeSessionType = .sleep
                    }
                }
            }
        }
    }
}

enum AdhkarSessionType: Identifiable {
    case morning, evening, sleep
    var id: Self { self }
    var idStr: String {
        switch self {
        case .morning: return "morning"
        case .evening: return "evening"
        case .sleep: return "sleep"
        }
    }
}

struct AdhkarSessionMainCard: View {
    let title: String
    let icon: String
    let isDone: Bool
    let language: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.islamicGreen.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Theme.islamicGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if isDone {
                    Text(L10n.tr("today_done", language))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.islamicGreen)
                } else {
                    Text(L10n.tr("pending", language))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}

