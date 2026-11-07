import SwiftUI
import SwiftData

func progressColor(percentage: Double) -> Color {
    return percentage >= 1.0 ? Theme.islamicGreen : .gray
}

enum TodayPrayerType: String, CaseIterable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
    
    var id: String { rawValue }
    
    func localizedName(lang: String) -> String {
        switch self {
        case .fajr: return L10n.tr("prayer_short_fajr", lang)
        case .sunrise: return L10n.tr("prayer_short_sunrise", lang)
        case .dhuhr: return L10n.tr("prayer_short_dhuhr", lang)
        case .asr: return L10n.tr("prayer_short_asr", lang)
        case .maghrib: return L10n.tr("prayer_short_maghrib", lang)
        case .isha: return L10n.tr("prayer_short_isha", lang)
        }
    }
}

struct TodayPrayerItem: Identifiable {
    let type: TodayPrayerType
    let date: Date?
    var id: String { type.rawValue }
}

struct NextPrayerData {
    let type: TodayPrayerType
    let date: Date
}

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
    
    func formattedHijriDateTransliterated(for date: Date, lang: String = "de") -> String {
        let cal = Calendar(identifier: .islamicUmmAlQura)
        let weekday = cal.component(.weekday, from: date)
        let day = cal.component(.day, from: date)
        let month = cal.component(.month, from: date)
        let year = cal.component(.year, from: date)
        
        if lang.lowercased() == "ar" {
            let weekdaysAr = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
            let monthsAr = [
                "محرم", "صفر", "ربيع الأول", "ربيع الثاني",
                "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
                "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
            ]
            let dayName = (weekday >= 1 && weekday <= 7) ? weekdaysAr[weekday - 1] : ""
            let monthName = (month >= 1 && month <= 12) ? monthsAr[month - 1] : ""
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "ar")
            let dayAr = formatter.string(from: NSNumber(value: day)) ?? "\(day)"
            let yearAr = formatter.string(from: NSNumber(value: year)) ?? "\(year)"
            return "\(dayName)، \(dayAr) \(monthName) \(yearAr) هـ"
        } else if lang.lowercased() == "de" {
            let weekdaysDe = ["Ahad", "Ithnayn", "Thulatha", "Arba'a", "Chamis", "Jumu'ah", "Sabt"]
            let monthsDe = [
                "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
                "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
                "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
            ]
            let dayName = (weekday >= 1 && weekday <= 7) ? weekdaysDe[weekday - 1] : ""
            let monthName = (month >= 1 && month <= 12) ? monthsDe[month - 1] : ""
            return "\(dayName), \(day). \(monthName) \(year) n.H."
        } else {
            let weekdaysEn = ["Al-Ahad", "Al-Ithnayn", "Al-Thulatha", "Al-Arba'a", "Al-Khamis", "Al-Jumu'ah", "Al-Sabt"]
            let monthsEn = [
                "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
                "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
            ]
            let dayName = (weekday >= 1 && weekday <= 7) ? weekdaysEn[weekday - 1] : ""
            let monthName = (month >= 1 && month <= 12) ? monthsEn[month - 1] : ""
            return "\(dayName), \(day). \(monthName) \(year) AH"
        }
    }
    
    func formattedDate(for lang: String) -> String {
        return solarManager.formattedDisplayDate(for: solarManager.currentTrackingDate, language: lang)
    }
    
    private static let prayerTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    private var canCalculatePrayerTimes: Bool {
        solarManager.hasLocationPermission && (solarManager.lastLocation != nil || UserDefaults.standard.double(forKey: "last_latitude") != 0.0)
    }
    
    private func resolveNextPrayer(at now: Date) -> NextPrayerData? {
        let todayFajr = solarManager.getFajrDate(for: now)
        let todayDhuhr = solarManager.getDhuhrDate(for: now)
        let todayAsr = solarManager.getAsrDate(for: now)
        let todayMaghrib = solarManager.getMaghribDate(for: now)
        let todayIsha = solarManager.getIshaDate(for: now)
        
        let prayerQueue: [(TodayPrayerType, Date?)] = [
            (.fajr, todayFajr),
            (.dhuhr, todayDhuhr),
            (.asr, todayAsr),
            (.maghrib, todayMaghrib),
            (.isha, todayIsha)
        ]
        
        for (type, date) in prayerQueue {
            if let date = date, date > now {
                return NextPrayerData(type: type, date: date)
            }
        }
        
        // Nach Isha ist das nächste Gebet das Fajr des folgenden Kalendertags. Berechne dafür die Fajr-Zeit von morgen.
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        if let tomorrowFajr = solarManager.getFajrDate(for: tomorrow) {
            return NextPrayerData(type: .fajr, date: tomorrowFajr)
        }
        
        return nil
    }
    
    private func getTodayPrayerItems(for date: Date) -> [TodayPrayerItem] {
        return [
            TodayPrayerItem(type: .fajr, date: solarManager.getFajrDate(for: date)),
            TodayPrayerItem(type: .sunrise, date: solarManager.getSunriseDate(for: date)),
            TodayPrayerItem(type: .dhuhr, date: solarManager.getDhuhrDate(for: date)),
            TodayPrayerItem(type: .asr, date: solarManager.getAsrDate(for: date)),
            TodayPrayerItem(type: .maghrib, date: solarManager.getMaghribDate(for: date)),
            TodayPrayerItem(type: .isha, date: solarManager.getIshaDate(for: date))
        ]
    }
    
    private func countdownString(to targetDate: Date, from now: Date) -> String {
        let diff = max(0, Int(targetDate.timeIntervalSince(now)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    @ViewBuilder
    private func headerView(lang: String) -> some View {
        if canCalculatePrayerTimes {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = context.date
                let nextPrayer = resolveNextPrayer(at: now)
                let todayPrayers = getTodayPrayerItems(for: now)
                
                VStack(spacing: 8) {
                    // Block 1: Countdown-Zeile „Fajr in 02:17:46“
                    if let next = nextPrayer {
                        let isRTL = ["ar", "ur", "fa"].contains(lang.lowercased())
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(next.type.localizedName(lang: lang))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.islamicGreen)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(L10n.tr("prayer_countdown_in", lang))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            Text(countdownString(to: next.date, from: now))
                                .font(.system(size: 24, weight: .bold))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Block 2: Kompakte Zeile mit allen 6 Gebetszeiten
                    HStack(spacing: 0) {
                        ForEach(todayPrayers) { prayer in
                            let isNext = (nextPrayer?.type == prayer.type)
                            VStack(spacing: 3) {
                                Text(prayer.type.localizedName(lang: lang))
                                    .font(.system(size: 11, weight: isNext ? .bold : .regular))
                                    .foregroundColor(isNext ? Theme.islamicGreen : .gray)
                                    .lineLimit(1)
                                
                                Text(prayer.date != nil ? Self.prayerTimeFormatter.string(from: prayer.date!) : "--:--")
                                    .font(.system(size: 13, weight: isNext ? .bold : .medium))
                                    .foregroundColor(isNext ? Theme.islamicGreen : .primary)
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Block 3: Datumszeilen (unverändert)
                    VStack(spacing: 4) {
                        Text(formattedHijriDateTransliterated(for: solarManager.currentTrackingDate, lang: lang))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.islamicGreen)
                        
                        Text(formattedDate(for: lang))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                // Hinweis ohne Standortfreigabe
                Button(action: {
                    solarManager.requestAuthorization()
                }) {
                    Text(L10n.tr("enable_location_prayer_times", lang))
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                
                // Datumszeilen (unverändert)
                VStack(spacing: 4) {
                    Text(formattedHijriDateTransliterated(for: solarManager.currentTrackingDate, lang: lang))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                    
                    Text(formattedDate(for: lang))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    var body: some View {
        let (tState, tT0) = QuranPerf.shared.begin("2c_TodayView_body")
        defer {
            QuranPerf.shared.end("2c_TodayView_body", state: tState, t0: tT0)
        }
        let lang = settings.language
        return NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 5-Minuten-Warnung Pop-up
                        if solarManager.showFiveMinuteWarning {
                            MaghribFiveMinuteWarningBanner(language: lang) {
                                solarManager.dismissFiveMinuteWarning()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // 1-Minute Countdown Regler & Banner
                        if let sec = solarManager.maghribCountdownSeconds {
                            MaghribCountdownBanner(seconds: sec, language: lang)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Header
                        headerView(lang: lang)
                        
                        // Prominente Fajr-Check-Karte (nur Anzeige, Klick führt zum Adhkar-Tab)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                selectedTab = 1
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image("sujud_icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Theme.islamicGreen)
                                    
                                    Text(L10n.tr("fajr_prayer", lang))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    let status = todayRecord.fajrPrayerStatus
                                    let isPrayed = status != "none"
                                    let isOnTime = status == "onTime"
                                    
                                    if isPrayed {
                                        Text("✓")
                                            .foregroundColor(isOnTime ? Theme.islamicGreen : .orange)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("○")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                let statusText: String = {
                                    switch todayRecord.fajrPrayerStatus {
                                    case "onTime": return L10n.tr("fajr_status_ontime", lang)
                                    case "late": return L10n.tr("fajr_status_late", lang)
                                    default: return L10n.tr("fajr_status_none", lang)
                                    }
                                }()
                                Text(statusText)
                                    .font(.subheadline)
                                    .foregroundColor(todayRecord.fajrPrayerStatus != "none" ? (todayRecord.fajrPrayerStatus == "onTime" ? Theme.islamicGreen : .orange) : .gray)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Result Card 1: Koran
                        ResultCard(title: L10n.tr("tab_quran", lang), systemImage: "book.fill") {
                            let goal = max(1, settings.quranDailyGoal)
                            let percentage = min(1.0, Double(todayRecord.quranPagesRead) / Double(goal))
                            let displayPercent = Int(percentage * 100)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(L10n.tr("daily_goal_title", lang))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(displayPercent)%")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(progressColor(percentage: percentage))
                                }
                                
                                ProgressView(value: percentage)
                                    .tint(Theme.islamicGreen)
                                
                                Text("\(todayRecord.quranPagesRead)/\(goal) \(L10n.tr("pages", lang)) · \(todayRecord.quranVersesRead) \(L10n.tr("verses", lang))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onTapGesture {
                            selectedTab = 3
                        }
                        
                        // Result Card 2: Adhkar
                        ResultCard(title: L10n.tr("tab_adhkar", lang), systemImage: "book.closed.fill") {
                            VStack(spacing: 12) {
                                AdhkarResultRow(title: L10n.tr("adhkar_sleep", lang), isDone: todayRecord.schlafAdhkarDone, time: todayRecord.schlafAdhkarTime)
                                AdhkarResultRow(title: L10n.tr("adhkar_morning", lang), isDone: todayRecord.morgenAdhkarDone, time: todayRecord.morgenAdhkarTime)
                                if solarManager.isFridayKahfVisible {
                                    AdhkarResultRow(title: L10n.tr("surah_alkahf", lang), isDone: todayRecord.surahAlKahfDone, time: todayRecord.surahAlKahfTime)
                                }
                                AdhkarResultRow(title: L10n.tr("adhkar_evening", lang), isDone: todayRecord.abendAdhkarDone, time: todayRecord.abendAdhkarTime)
                            }
                        }
                        .onTapGesture {
                            selectedTab = 1
                        }
                        
                        // Result Card 3: Tasbih
                        ResultCard(title: L10n.tr("tab_tasbih", lang), systemImage: "circle.hexagongrid.fill") {
                            VStack(spacing: 10) {
                                if settings.istighfarEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_istighfar", lang), count: todayRecord.totalIstighfarCount, goal: settings.istighfarGoal)
                                }
                                if settings.salawatEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_salawat", lang), count: todayRecord.totalSalawatCount, goal: settings.effectiveSalawatGoal(for: todayRecord.date))
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
                                if settings.laIlahaIllallahEnabled {
                                    TasbihResultRow(title: L10n.tr("tasbih_type_lailahaillallah", lang), count: todayRecord.laIlahaIllallahCount, goal: settings.laIlahaIllallahGoal)
                                }
                            }
                        }
                        .onTapGesture {
                            selectedTab = 0
                        }
                    }
                    .padding()
                }
                
                if solarManager.showDayResetToast {
                    VStack {
                        Spacer()
                        MaghribDayResetToast(language: lang)
                            .padding(.bottom, 25)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                    .font(.headline)
                    .frame(width: 20, height: 20, alignment: .center)
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
                .foregroundColor(.primary)
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
    
    private var shortTitle: String {
        let lower = title.lowercased()
        if lower.contains("istighfar") || lower.contains("vergebung") || lower.contains("forgiveness") { return "Istighfar" }
        if lower.contains("salawat") || lower.contains("segne") || lower.contains("bless") { return "Salawat" }
        if lower.contains("subhan allahi wa bihamdihi") { return "Subhanallahi wa bihamdihi" }
        if lower.contains("subhan allah") && !lower.contains("wa bihamdihi") { return "Subhanallah" }
        if lower.contains("alhamdulillah") { return "Alhamdulillah" }
        if lower.contains("allahu akbar") { return "Allahu Akbar" }
        if lower.contains("la ilaha") { return "La ilaha illallah" }
        if lower.contains("hawla") { return "La hawla" }
        return title
    }
    
    var body: some View {
        let safeGoal = max(1, goal)
        let percentage = min(1.0, Double(count) / Double(safeGoal))
        let displayPercent = Int(percentage * 100)
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(shortTitle)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(displayPercent)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor(percentage: percentage))
            }
            ProgressView(value: percentage)
                .tint(Theme.islamicGreen)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            
            Text("\(count)/\(safeGoal)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
