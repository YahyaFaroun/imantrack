import SwiftUI
import SwiftData
import Charts

enum PeriodFilter: String, CaseIterable, Identifiable {
    case week = "Woche"
    case month = "Monat"
    
    var id: String { self.rawValue }
    
    func localizedName(for lang: String) -> String {
        switch self {
        case .week: return L10n.tr("period_week", lang)
        case .month: return L10n.tr("period_month", lang)
        }
    }
}

extension TasbihCategory: Identifiable {
    public var id: String { self.rawValue }
    
    func localizedName(for lang: String) -> String {
        switch self {
        case .istighfar: return L10n.tr("tasbih_type_istighfar", lang)
        case .salawat: return L10n.tr("tasbih_type_salawat", lang)
        case .subhanAllah: return L10n.tr("tasbih_type_subhanallah", lang)
        case .alhamdulillah: return L10n.tr("tasbih_type_alhamdulillah", lang)
        case .allahuAkbar: return L10n.tr("tasbih_type_lahawla", lang)
        case .laIlahaIllallah: return L10n.tr("tasbih_type_lailahaillallah", lang)
        }
    }
    
    func shortLocalizedName(for lang: String) -> String {
        let title = self.localizedName(for: lang)
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
    
    func getValue(from record: DailyRecord) -> Double {
        switch self {
        case .istighfar: return Double(record.totalIstighfarCount)
        case .salawat: return Double(record.totalSalawatCount)
        case .subhanAllah: return Double(record.subhanAllahCount)
        case .alhamdulillah: return Double(record.alhamdulillahCount)
        case .allahuAkbar: return Double(record.allahuAkbarCount)
        case .laIlahaIllallah: return Double(record.laIlahaIllallahCount)
        }
    }
    
    func getGoal(from settings: UserSettings) -> Int {
        switch self {
        case .istighfar: return settings.istighfarGoal
        case .salawat: return settings.salawatGoal
        case .subhanAllah: return settings.subhanAllahGoal
        case .alhamdulillah: return settings.alhamdulillahGoal
        case .allahuAkbar: return settings.allahuAkbarGoal
        case .laIlahaIllallah: return settings.laIlahaIllallahGoal
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let date: Date?
    let value: Double
}

enum TrendDirection {
    case up, down, flat
}

struct TrendInfo {
    let percentage: Int
    let direction: TrendDirection
}



struct TasbihRowData: Identifiable {
    var id: String { type.rawValue }
    let type: TasbihCategory
    let totalCount: Double
    let safeGoal: Double
    let progress: Double
    let percentage: Int
    let pColor: Color
}

struct ComputedStats {
    var periodString: String = ""
    var daysSinceStart: Int = 1
    var daysGoalReached: Int = 0
    
    // Koran
    var quranPoints: [ChartDataPoint] = []
    var quranHasNoData: Bool = true
    var quranTrend: TrendInfo? = nil
    var currentQuranGoalValue: Double = 1.0
    var khatmCount: Int = 0
    
    // Adhkar
    var morningCount: Int = 0
    var eveningCount: Int = 0
    var sleepCount: Int = 0
    var fridaysCount: Int = 0
    var fajrCount: Int = 0
    var totalDaysInPeriod: Int = 7
    var totalFridaysInPeriod: Int = 1
    
    // Tasbih
    var tasbihTrend: TrendInfo? = nil
    var tasbihRows: [TasbihRowData] = []
}

struct StatsView: View {
    @Binding var selectedTab: Int
    @Query(sort: \DailyRecord.date, order: .forward) private var allDailyRecords: [DailyRecord]
    @Query private var allSettings: [UserSettings]
    
    @State private var selectedPeriod: PeriodFilter = .week
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    @State private var computedData = ComputedStats()
    @State private var isDirty: Bool = true
    @State private var hasComputedOnce: Bool = false
    
    init(selectedTab: Binding<Int> = .constant(4)) {
        self._selectedTab = selectedTab
    }
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var headerSummaryView: some View {
        VStack(spacing: 4) {
            Text(String(format: L10n.tr("today_day_counter", settings.language), "\(computedData.daysSinceStart)"))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Theme.islamicGreen)
            
            Text(String(format: L10n.tr("stats_days_goal_reached", settings.language), computedData.daysGoalReached))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }
    
    private func hasData(in period: DateInterval) -> Bool {
        return allDailyRecords.contains { record in
            record.date >= period.start && record.date < period.end
        }
    }
    
    private func firstTrackingMonth(in year: Int) -> Int? {
        let calendar = Calendar.current
        let recordsInYear = allDailyRecords.filter { calendar.component(.year, from: $0.date) == year }
        guard let earliest = recordsInYear.min(by: { $0.date < $1.date }) else { return nil }
        return calendar.component(.month, from: earliest.date)
    }

    private func computeTrend(for valueExtractor: @escaping (DailyRecord) -> Double) -> TrendInfo? {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        
        var currentStart: Date
        var currentEnd: Date
        var previousStart: Date
        var previousEnd: Date
        
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            guard let monday = calendar.date(from: components),
                  let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday),
                  let prevMonday = calendar.date(byAdding: .day, value: -7, to: monday) else { return nil }
            currentStart = monday; currentEnd = nextMonday
            previousStart = prevMonday; previousEnd = monday
            
        case .month:
            var components = calendar.dateComponents([.year], from: now)
            components.month = 1; components.day = 1
            guard let firstOfYear = calendar.date(from: components),
                  let nextYear = calendar.date(byAdding: .year, value: 1, to: firstOfYear),
                  let prevYear = calendar.date(byAdding: .year, value: -1, to: firstOfYear) else { return nil }
            currentStart = firstOfYear; currentEnd = nextYear
            previousStart = prevYear; previousEnd = firstOfYear
        }
        
        let previousInterval = DateInterval(start: previousStart, end: previousEnd)
        guard hasData(in: previousInterval) else { return nil }

        let currentRecords = allDailyRecords.filter { $0.date >= currentStart && $0.date < currentEnd }
        let prevRecords = allDailyRecords.filter { $0.date >= previousStart && $0.date < previousEnd }
        
        let currentTotal = currentRecords.map(valueExtractor).reduce(0.0, +)
        let prevTotal = prevRecords.map(valueExtractor).reduce(0.0, +)
        
        if prevTotal == 0 { return nil }
        
        let diff = currentTotal - prevTotal
        let percentage = (diff / prevTotal) * 100
        let intPercentage = Int(round(percentage))
        
        let direction: TrendDirection
        if intPercentage > 0 { direction = .up }
        else if intPercentage < 0 { direction = .down }
        else { direction = .flat }
        
        return TrendInfo(percentage: abs(intPercentage), direction: direction)
    }
    
    private func trendRow(for trend: TrendInfo?) -> some View {
        guard let trend = trend else { return AnyView(EmptyView()) }
        let color: Color
        let icon: String
        let sign: String
        switch trend.direction {
        case .up:
            color = Theme.islamicGreen
            icon = "arrow.up"
            sign = "+"
        case .down:
            color = .orange
            icon = "arrow.down"
            sign = "-"
        case .flat:
            color = .gray
            icon = "equal"
            sign = "±"
        }
        let periodStr: String
        switch selectedPeriod {
        case .week: periodStr = L10n.tr("stats_prev_week", settings.language)
        case .month: periodStr = L10n.tr("stats_prev_year", settings.language)
        }
        return AnyView(
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text("\(sign)\(trend.percentage)% vs. \(periodStr)")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
        )
    }
    
    private func chartDataPoints(for valueExtractor: @escaping (DailyRecord) -> Double) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            guard let monday = calendar.date(from: components) else { return [] }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: settings.language)
            
            var points: [ChartDataPoint] = []
            for i in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: i, to: monday) else { continue }
                let record = allDailyRecords.first { calendar.isDate($0.date, inSameDayAs: dayDate) }
                let value = record.map(valueExtractor) ?? 0.0
                formatter.dateFormat = "E"
                points.append(ChartDataPoint(label: formatter.string(from: dayDate), date: dayDate, value: value))
            }
            return points
            
        case .month:
            let currentYear = calendar.component(.year, from: now)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: settings.language)
            let monthSymbols = formatter.shortMonthSymbols ?? ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
            
            let startMonth = firstTrackingMonth(in: currentYear) ?? 1
            
            var points: [ChartDataPoint] = []
            for month in startMonth...12 {
                let monthRecords = allDailyRecords.filter { record in
                    calendar.component(.year, from: record.date) == currentYear && calendar.component(.month, from: record.date) == month
                }
                let totalValue = monthRecords.map(valueExtractor).reduce(0.0, +)
                var components = DateComponents()
                components.year = currentYear; components.month = month; components.day = 1
                let monthDate = calendar.date(from: components)
                points.append(ChartDataPoint(label: monthSymbols[month - 1], date: monthDate, value: totalValue))
            }
            return points
        }
    }
    
    private func recomputeData() {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        let lang = settings.language

        // 1. Period String
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang)
        let periodStr: String
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "w"
            let weekNum = formatter.string(from: now)
            periodStr = String(format: L10n.tr("calendar_week", lang), weekNum)
        case .month:
            formatter.dateFormat = "yyyy"
            periodStr = formatter.string(from: now)
        }

        // 2. Days since start
        let daysSince: Int
        if let firstRecord = allDailyRecords.min(by: { $0.date < $1.date }) {
            let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstRecord.date), to: calendar.startOfDay(for: now))
            daysSince = max(1, (components.day ?? 0) + 1)
        } else {
            daysSince = 1
        }

        // 3. Filtered records for current period
        let currentRecords: [DailyRecord]
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            if let monday = calendar.date(from: components) {
                currentRecords = allDailyRecords.filter { record in
                    if let diff = calendar.dateComponents([.day], from: monday, to: record.date).day {
                        return diff >= 0 && diff < 7
                    }
                    return false
                }
            } else {
                currentRecords = []
            }
        case .month:
            let currentYear = calendar.component(.year, from: now)
            currentRecords = allDailyRecords.filter { record in
                calendar.component(.year, from: record.date) == currentYear
            }
        }

        // 4. Days goal reached
        let daysGoal = currentRecords.filter { $0.quranPagesRead >= settings.quranDailyGoal }.count

        // 5. Quran Goal Value & Points & Trend
        let quranGoalVal: Double
        switch selectedPeriod {
        case .week: quranGoalVal = Double(max(1, settings.quranDailyGoal))
        case .month: quranGoalVal = Double(max(1, settings.quranDailyGoal * 30))
        }

        let qPoints = chartDataPoints(for: { Double($0.quranPagesRead) })
        let qNoData = qPoints.allSatisfy { $0.value == 0 }
        let qTrend = computeTrend(for: { Double($0.quranPagesRead) })
        let khatm = UserDefaults.standard.integer(forKey: "quranKhatmCount")

        // 6. Adhkar
        let mCount = currentRecords.filter { $0.morgenAdhkarDone }.count
        let eCount = currentRecords.filter { $0.abendAdhkarDone }.count
        let sCount = currentRecords.filter { $0.schlafAdhkarDone }.count
        let frCount = currentRecords.filter { record in
            calendar.component(.weekday, from: record.date) == 6 && record.surahAlKahfDone
        }.count
        let fCount = currentRecords.filter { $0.fajrPrayerStatus == "onTime" || $0.fajrPrayerStatus == "late" || $0.isFajrPrayed }.count

        let totalDays: Int
        switch selectedPeriod {
        case .week: totalDays = 7
        case .month: totalDays = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        }

        var fridaysStart = now
        var fridaysCountTotal = 0
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            if let monday = calendar.date(from: components) { fridaysStart = monday; fridaysCountTotal = 7 }
        case .month:
            var components = calendar.dateComponents([.year], from: now)
            components.month = 1; components.day = 1
            if let firstOfYear = calendar.date(from: components) {
                fridaysStart = firstOfYear
                let isLeapYear = (components.year! % 4 == 0 && components.year! % 100 != 0) || (components.year! % 400 == 0)
                fridaysCountTotal = isLeapYear ? 366 : 365
            }
        }
        var fridays = 0
        for i in 0..<fridaysCountTotal {
            if let d = calendar.date(byAdding: .day, value: i, to: fridaysStart), calendar.component(.weekday, from: d) == 6 {
                fridays += 1
            }
        }
        let totalFridays = max(1, fridays)

        // 7. Tasbih
        let tTrend = computeTrend(for: { record in
            TasbihCategory.allCases.map { $0.getValue(from: record) }.reduce(0, +)
        })

        var tRows: [TasbihRowData] = []
        for type in TasbihCategory.allCases {
            let totalCount = currentRecords.map { type.getValue(from: $0) }.reduce(0, +)
            let periodGoal: Double
            if type == .salawat && settings.salawatFridayGoalEnabled {
                let normalDays = max(0, totalDays - totalFridays)
                periodGoal = Double(normalDays * settings.salawatGoal + totalFridays * settings.salawatFridayGoal)
            } else {
                let dailyGoal = Double(max(1, type.getGoal(from: settings)))
                switch selectedPeriod {
                case .week: periodGoal = dailyGoal * 7
                case .month: periodGoal = dailyGoal * Double(totalDays)
                }
            }
            let safeGoal = max(1, periodGoal)
            let progress = min(totalCount / safeGoal, 1.0)
            let percentage = Int(round(progress * 100))
            let pColor = progressColor(percentage: progress)
            tRows.append(TasbihRowData(type: type, totalCount: totalCount, safeGoal: safeGoal, progress: progress, percentage: percentage, pColor: pColor))
        }

        self.computedData = ComputedStats(
            periodString: periodStr,
            daysSinceStart: daysSince,
            daysGoalReached: daysGoal,
            quranPoints: qPoints,
            quranHasNoData: qNoData,
            quranTrend: qTrend,
            currentQuranGoalValue: quranGoalVal,
            khatmCount: khatm,
            morningCount: mCount,
            eveningCount: eCount,
            sleepCount: sCount,
            fridaysCount: frCount,
            fajrCount: fCount,
            totalDaysInPeriod: totalDays,
            totalFridaysInPeriod: totalFridays,
            tasbihTrend: tTrend,
            tasbihRows: tRows
        )
        self.isDirty = false
        self.hasComputedOnce = true
    }
    
    var body: some View {
        let (sState, sT0) = QuranPerf.shared.begin("2d_StatsView_body")
        defer {
            QuranPerf.shared.end("2d_StatsView_body", state: sState, t0: sT0)
        }
        return NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Picker(L10n.tr("stats_period_picker", settings.language), selection: $selectedPeriod) {
                            ForEach(PeriodFilter.allCases) { period in
                                Text(period.localizedName(for: settings.language)).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        VStack(spacing: 2) {
                            Text(computedData.periodString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            headerSummaryView
                        }
                        
                        quranCardView
                        adhkarCardView
                        tasbihCardView
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.tr("tab_stats", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                if selectedTab == 4 && (isDirty || !hasComputedOnce) {
                    recomputeData()
                }
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                if newTab == 4 && (isDirty || !hasComputedOnce) {
                    recomputeData()
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                recomputeData()
            }
            .onChange(of: allDailyRecords) { _, _ in
                if selectedTab == 4 {
                    recomputeData()
                } else {
                    isDirty = true
                }
            }
            .onChange(of: allSettings) { _, _ in
                if selectedTab == 4 {
                    recomputeData()
                } else {
                    isDirty = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var quranCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .foregroundColor(Theme.islamicGreen)
                    .font(.title2)
                Text(L10n.tr("koran_sec", settings.language))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            trendRow(for: computedData.quranTrend)
            
            if computedData.quranHasNoData {
                emptyStateView
            } else {
                Chart {
                    ForEach(computedData.quranPoints) { point in
                        BarMark(
                            x: .value("Day", point.label),
                            y: .value("Pages", point.value)
                        )
                        .foregroundStyle(progressColor(percentage: point.value / computedData.currentQuranGoalValue).gradient)
                        .cornerRadius(4)
                        .annotation(position: .top, alignment: .center) {
                            if point.value > 0 {
                                Text("\(Int(point.value))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(progressColor(percentage: point.value / computedData.currentQuranGoalValue))
                            }
                        }
                    }
                    
                    RuleMark(
                        y: .value("Goal", computedData.currentQuranGoalValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .trailing) {
                        Text(L10n.tr("stats_goal", settings.language) + ": \(Int(computedData.currentQuranGoalValue))")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .offset(y: -4)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartYAxis(.hidden)
                .animation(.spring(), value: selectedPeriod)
            }
            
            if computedData.khatmCount > 0 {
                Divider()
                    .background(Color.gray.opacity(0.2))
                HStack {
                    Text(L10n.tr("stats_khatm_count", settings.language))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(computedData.khatmCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.islamicGreen)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var adhkarCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(Theme.islamicGreen)
                    .font(.title2)
                Text(L10n.tr("tab_adhkar", settings.language))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                adhkarStatRing(
                    title: L10n.tr("adhkar_sleep", settings.language),
                    count: computedData.sleepCount,
                    total: computedData.totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_morning", settings.language),
                    count: computedData.morningCount,
                    total: computedData.totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_evening", settings.language),
                    count: computedData.eveningCount,
                    total: computedData.totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("surah_alkahf", settings.language),
                    count: computedData.fridaysCount,
                    total: computedData.totalFridaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("fajr_prayer", settings.language),
                    count: computedData.fajrCount,
                    total: computedData.totalDaysInPeriod
                )
            }
            
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var tasbihCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(Theme.islamicGreen)
                        .font(.title2)
                    Text(L10n.tr("tasbih_sec", settings.language))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                trendRow(for: computedData.tasbihTrend)
            }
            
            VStack(spacing: 20) {
                ForEach(computedData.tasbihRows) { row in
                    tasbihRowView(for: row)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func tasbihRowView(for row: TasbihRowData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.type.shortLocalizedName(for: settings.language))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(row.percentage)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(row.pColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(row.pColor)
                        .frame(width: geometry.size.width * CGFloat(row.progress), height: 6)
                        .animation(.easeOut, value: row.progress)
                }
            }
            .frame(height: 6)
            
            Text("\(Int(row.totalCount))/\(Int(row.safeGoal))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text(L10n.tr("stats_no_data", settings.language))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private func adhkarStatRing(title: String, count: Int, total: Int) -> some View {
        let safeTotal = max(1, total)
        let progress = min(Double(count) / Double(safeTotal), 1.0)
        let pColor = progressColor(percentage: progress)
        
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(pColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                
                Text("\(count)/\(safeTotal)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
