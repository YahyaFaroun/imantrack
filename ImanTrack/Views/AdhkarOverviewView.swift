import SwiftUI
import SwiftData

struct AdhkarOverviewView: View {
    @Environment(\.modelContext) var modelContext
    @Query var allDailyRecords: [DailyRecord]
    @Query var settingsList: [UserSettings]
    
    @Binding var selectedTab: Int
    
    private var language: String {
        settingsList.first?.language ?? (["de", "en", "ar"].contains(Locale.current.language.languageCode?.identifier ?? "") ? (Locale.current.language.languageCode?.identifier ?? "en") : "en")
    }
    
    @StateObject var solarManager = LocationAndSolarManager.shared
    
    @AppStorage("lastActiveSessionId") var lastActiveSessionId: String = ""
    @AppStorage("lastActiveDhikrIndex") var lastActiveDhikrIndex: Int = 0
    @AppStorage("lastActiveDhikrCount") var lastActiveDhikrCount: Int = 0
    @AppStorage("isSessionActive") var isSessionActive: Bool = false
    
    @State var showAlKahfReader = false
    @State var showFajrDialog = false
    
    private var isFriday: Bool {
        solarManager.isFridayKahfVisible
    }
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    private var morningState: AdhkarState { getAdhkarState(type: .morning) }
    private var eveningState: AdhkarState { getAdhkarState(type: .evening) }
    private var sleepState: AdhkarState { getAdhkarState(type: .sleep) }
    
    private var fajrState: AdhkarState {
        let now = Date()
        let trackerDate = LocationAndSolarManager.shared.currentTrackingDate
        let dhuhr = LocationAndSolarManager.shared.getDhuhrDate(for: trackerDate) ?? trackerDate
        let fajr = LocationAndSolarManager.shared.getFajrDate(for: trackerDate) ?? trackerDate
        
        if now < fajr { return .future }
        if now < dhuhr { return .active }
        return .expired
    }
    
    @State var activeSessionType: AdhkarSessionType? = nil
    @State private var showPermissionSheet = false
    
    var body: some View {
        let (aState, aT0) = QuranPerf.shared.begin("2e_AdhkarOverviewView_body")
        defer {
            QuranPerf.shared.end("2e_AdhkarOverviewView_body", state: aState, t0: aT0)
        }
        return NavigationStack {
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
                                language: language,
                                state: sleepState
                            )
                        }
                        .disabled(sleepState == .future)

                        Button {
                            showFajrDialog = true
                        } label: {
                            AdhkarFajrCard(
                                status: todayRecord.fajrPrayerStatus,
                                language: language,
                                state: fajrState
                            )
                        }
                        .disabled(fajrState == .future)

                        Button {
                            activeSessionType = .morning
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_morning", language),
                                icon: "sunrise.fill",
                                isDone: todayRecord.morgenAdhkarDone,
                                language: language,
                                state: morningState
                            )
                        }
                        .disabled(morningState == .future)
                        
                        if solarManager.isFridayKahfVisible {
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
                        }
                        
                        Button {
                            activeSessionType = .evening
                        } label: {
                            AdhkarSessionMainCard(
                                title: L10n.tr("adhkar_evening", language),
                                icon: "moon.fill",
                                isDone: todayRecord.abendAdhkarDone,
                                language: language,
                                state: eveningState
                            )
                        }
                        .disabled(eveningState == .future)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.tr("tab_adhkar", language))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(item: $activeSessionType) { type in
                AdhkarSessionView(type: type)
            }
            #else
            .sheet(item: $activeSessionType) { type in
                AdhkarSessionView(type: type)
            }
            #endif
            .sheet(isPresented: $showAlKahfReader) {
                AlKahfReaderView()
            }
            .sheet(isPresented: $showPermissionSheet) {
                NotificationPermissionSheet()
            }
            .onChange(of: activeSessionType) { oldValue, newValue in
                if oldValue != nil && newValue == nil {
                    AdhkarReminderManager.shared.shouldPromptPermissionAfterFirstSession { shouldPrompt in
                        if shouldPrompt {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showPermissionSheet = true
                            }
                        }
                    }
                }
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

enum AdhkarState: Equatable {
    case future
    case active
    case expired
}

func getAdhkarState(type: AdhkarSessionType) -> AdhkarState {
    let now = Date()
    let solarManager = LocationAndSolarManager.shared
    let trackingDate = solarManager.currentTrackingDate
    
    let fajrCurrent = solarManager.getFajrDate(for: trackingDate) ?? trackingDate
    let dhuhrCurrent = solarManager.getDhuhrDate(for: trackingDate) ?? trackingDate
    let maghribCurrent = solarManager.getMaghribDate(for: trackingDate) ?? trackingDate
    
    let prevTrackingDate = Calendar.current.date(byAdding: .day, value: -1, to: trackingDate) ?? trackingDate
    let maghribPrev = solarManager.getMaghribDate(for: prevTrackingDate) ?? prevTrackingDate

    switch type {
    case .morning:
        if now < fajrCurrent { return .future }
        if now >= fajrCurrent && now < dhuhrCurrent { return .active }
        return .expired
        
    case .evening:
        let end = maghribCurrent.addingTimeInterval(3600)
        if now < dhuhrCurrent { return .future }
        if now >= dhuhrCurrent && now < end { return .active }
        return .expired
        
    case .sleep:
        let sleepStart = maghribPrev
        let sleepEnd = fajrCurrent.addingTimeInterval(-3600)
        
        if now < sleepStart { return .future }
        if now >= sleepStart && now < sleepEnd { return .active }
        return .expired
    }
}

struct AdhkarSessionMainCard: View {
    let title: String
    let icon: String
    let isDone: Bool
    let language: String
    var state: AdhkarState
    
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
        .opacity(state == .future ? 0.6 : 1.0)
    }
}

struct AdhkarFajrCard: View {
    let status: String
    let language: String
    var state: AdhkarState
    
    var body: some View {
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
                
                if status == "none" || state == .future {
                    Text(L10n.tr("pending", language))
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(status != "none" ? .bold : .regular)
                        .foregroundColor(status != "none" ? (status == "onTime" ? Theme.islamicGreen : .orange) : .orange)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .opacity(state == .future ? 0.6 : 1.0)
    }
}

