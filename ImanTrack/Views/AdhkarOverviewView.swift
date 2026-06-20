import SwiftUI
import SwiftData

struct AdhkarOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    @Query private var settingsList: [UserSettings]
    
    @Binding var selectedTab: Int
    
    private var language: String {
        settingsList.first?.language ?? (["de", "en", "ar"].contains(Locale.current.language.languageCode?.identifier ?? "") ? (Locale.current.language.languageCode?.identifier ?? "en") : "en")
    }
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    @AppStorage("lastActiveSessionId") private var lastActiveSessionId: String = ""
    @AppStorage("lastActiveDhikrIndex") private var lastActiveDhikrIndex: Int = 0
    @AppStorage("lastActiveDhikrCount") private var lastActiveDhikrCount: Int = 0
    @AppStorage("isSessionActive") private var isSessionActive: Bool = false
    
    @State private var showAlKahfReader = false
    @State private var showFajrDialog = false
    
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
                            activeSessionType = .sleep
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_sleep", language),
                                icon: "bed.double.fill",
                                isDone: todayRecord.schlafAdhkarDone,
                                language: language
                            )
                        }

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
                        
                        AdhkarFajrCard(
                            status: todayRecord.fajrPrayerStatus,
                            language: language
                        ) {
                            showFajrDialog = true
                        }
                        
                        Button {
                            showAlKahfReader = true
                        } label: {
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
                                        .multilineTextAlignment(.leading)
                                    
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
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                        }
                        .disabled(!isFriday)
                        .opacity(isFriday ? 1.0 : 0.6)
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
            .sheet(isPresented: $showAlKahfReader) {
                AlKahfReaderView()
            }
            .alert(L10n.tr("fajr_option_title", language), isPresented: $showFajrDialog) {
                Button(L10n.tr("fajr_option_ontime", language)) {
                    todayRecord.fajrPrayerStatus = "onTime"
                    todayRecord.isFajrPrayed = true
                    try? modelContext.save()
                }
                Button(L10n.tr("fajr_option_late", language)) {
                    todayRecord.fajrPrayerStatus = "late"
                    todayRecord.isFajrPrayed = true
                    try? modelContext.save()
                }
                Button(L10n.tr("cancel", language), role: .cancel) {}
            }
            .onAppear {
                if isSessionActive, !lastActiveSessionId.isEmpty {
                    if lastActiveSessionId == "sleep" {
                        activeSessionType = .sleep
                    } else if lastActiveSessionId == "morning" {
                        activeSessionType = .morning
                    } else if lastActiveSessionId == "evening" {
                        activeSessionType = .evening
                    }
                }
            }
        }
    }
}

enum AdhkarSessionType: Identifiable {
    case sleep, morning, evening
    var id: Self { self }
    var idStr: String {
        switch self {
        case .sleep: return "sleep"
        case .morning: return "morning"
        case .evening: return "evening"
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

struct AdhkarFajrCard: View {
    let status: String
    let language: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.islamicGreen.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image("sujud_icon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(Theme.islamicGreen)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("fajr_prayer", language))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let statusText: String = {
                        switch status {
                        case "onTime": return L10n.tr("fajr_status_ontime", language)
                        case "late": return L10n.tr("fajr_status_late", language)
                        default: return L10n.tr("fajr_status_none", language)
                        }
                    }()
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(status != "none" ? .bold : .regular)
                        .foregroundColor(status != "none" ? (status == "onTime" ? Theme.islamicGreen : .orange) : .gray)
                }
                Spacer()
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

