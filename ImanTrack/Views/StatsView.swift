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



struct StatsView: View {
    @Query(sort: \DailyRecord.date, order: .forward) private var allDailyRecords: [DailyRecord]
    @Query private var allSettings: [UserSettings]
    
    @State private var selectedPeriod: PeriodFilter = .week
    @State private var selectedDhikrType: TasbihCategory = .istighfar
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var currentPeriodString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.language)
        
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "w"
            let weekNum = formatter.string(from: solarManager.currentTrackingDate)
            return String(format: L10n.tr("calendar_week", settings.language), weekNum)
        case .month:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: solarManager.currentTrackingDate)
        }
    }
    
    private var daysSinceStart: Int {
        let calendar = Calendar.current
        guard let firstRecord = allDailyRecords.min(by: { $0.date < $1.date }) else { return 1 }
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstRecord.date), to: calendar.startOfDay(for: solarManager.currentTrackingDate))
        return max(1, (components.day ?? 0) + 1)
    }
    
    private var headerSummaryView: some View {
        let currentRecords = filteredRecordsForCurrentPeriod
        let daysGoalReached = currentRecords.filter { $0.quranPagesRead >= settings.quranDailyGoal }.count
        
        return VStack(spacing: 4) {
            Text(String(format: L10n.tr("today_day_counter", settings.language), "\(daysSinceStart)"))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Theme.islamicGreen)
            
            Text(String(format: L10n.tr("stats_days_goal_reached", settings.language), daysGoalReached))
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
    
    private var filteredRecordsForCurrentPeriod: [DailyRecord] {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            guard let monday = calendar.date(from: components) else { return [] }
            
            return allDailyRecords.filter { record in
                if let diff = calendar.dateComponents([.day], from: monday, to: record.date).day {
                    return diff >= 0 && diff < 7
                }
                return false
            }
            
        case .month:
            let currentYear = calendar.component(.year, from: now)
            return allDailyRecords.filter { record in
                return calendar.component(.year, from: record.date) == currentYear
            }
        }
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
    
    private var totalDaysInPeriod: Int {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        switch selectedPeriod {
        case .week: return 7
        case .month: return calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        }
    }
    
    private var totalFridaysInPeriod: Int {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        var start = solarManager.currentTrackingDate
        var count = 0
        
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            if let monday = calendar.date(from: components) { start = monday; count = 7 }
        case .month:
            var components = calendar.dateComponents([.year], from: now)
            components.month = 1; components.day = 1
            if let firstOfYear = calendar.date(from: components) {
                start = firstOfYear
                let isLeapYear = (components.year! % 4 == 0 && components.year! % 100 != 0) || (components.year! % 400 == 0)
                count = isLeapYear ? 366 : 365
            }
        }
        
        var fridays = 0
        for i in 0..<count {
            if let d = calendar.date(byAdding: .day, value: i, to: start), calendar.component(.weekday, from: d) == 6 {
                fridays += 1
            }
        }
        return max(1, fridays)
    }
    
    private var currentQuranGoalValue: Double {
        switch selectedPeriod {
        case .week: return Double(max(1, settings.quranDailyGoal))
        case .month: return Double(max(1, settings.quranDailyGoal * 30))
        }
    }
    
    private var currentTasbihGoalValue: Double {
        let dailyGoal = Double(max(1, selectedDhikrType.getGoal(from: settings)))
        switch selectedPeriod {
        case .week, .month: return dailyGoal

        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(PeriodFilter.allCases) { period in
                                Text(period.localizedName(for: settings.language)).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        VStack(spacing: 2) {
                            Text(currentPeriodString)
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
        }
    }
    
    // MARK: - Subviews
    
    private var quranCardView: some View {
        let dataPoints = chartDataPoints(for: { Double($0.quranPagesRead) })
        let hasNoData = dataPoints.allSatisfy { $0.value == 0 }
        let trend = computeTrend(for: { Double($0.quranPagesRead) })
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .foregroundColor(Theme.islamicGreen)
                    .font(.title2)
                Text(L10n.tr("koran_sec", settings.language))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            trendRow(for: trend)
            
            if hasNoData {
                emptyStateView
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        BarMark(
                            x: .value("Day", point.label),
                            y: .value("Pages", point.value)
                        )
                        .foregroundStyle(progressColor(percentage: point.value / currentQuranGoalValue).gradient)
                        .cornerRadius(4)
                        .annotation(position: .top, alignment: .center) {
                            if point.value > 0 {
                                Text("\(Int(point.value))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(progressColor(percentage: point.value / currentQuranGoalValue))
                            }
                        }
                    }
                    
                    RuleMark(
                        y: .value("Goal", currentQuranGoalValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .trailing) {
                        Text(L10n.tr("stats_goal", settings.language) + ": \(Int(currentQuranGoalValue))")
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
            
            let khatmCount = UserDefaults.standard.integer(forKey: "quranKhatmCount")
            if khatmCount > 0 {
                Divider()
                    .background(Color.gray.opacity(0.2))
                HStack {
                    Text(L10n.tr("stats_khatm_count", settings.language))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(khatmCount)")
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
        let currentRecords = filteredRecordsForCurrentPeriod
        let morningCount = currentRecords.filter { $0.morgenAdhkarDone }.count
        let eveningCount = currentRecords.filter { $0.abendAdhkarDone }.count
        let sleepCount = currentRecords.filter { $0.schlafAdhkarDone }.count
        let fridaysCount = currentRecords.filter { record in
            Calendar.current.component(.weekday, from: record.date) == 6 && record.surahAlKahfDone
        }.count
        let fajrCount = currentRecords.filter { $0.fajrPrayerStatus == "onTime" || $0.fajrPrayerStatus == "late" || $0.isFajrPrayed }.count
        
        return VStack(alignment: .leading, spacing: 16) {
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
                    count: sleepCount,
                    total: totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_morning", settings.language),
                    count: morningCount,
                    total: totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_evening", settings.language),
                    count: eveningCount,
                    total: totalDaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("surah_alkahf", settings.language),
                    count: fridaysCount,
                    total: totalFridaysInPeriod
                )
                
                adhkarStatRing(
                    title: L10n.tr("fajr_prayer", settings.language),
                    count: fajrCount,
                    total: totalDaysInPeriod
                )
            }
            
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var tasbihCardView: some View {
        let trend = computeTrend(for: { record in
            TasbihCategory.allCases.map { $0.getValue(from: record) }.reduce(0, +)
        })
        
        return VStack(alignment: .leading, spacing: 16) {
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
                trendRow(for: trend)
            }
            
            VStack(spacing: 20) {
                ForEach(TasbihCategory.allCases) { type in
                    tasbihRow(for: type)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func tasbihRow(for type: TasbihCategory) -> some View {
        let currentRecords = filteredRecordsForCurrentPeriod
        let totalCount = currentRecords.map { type.getValue(from: $0) }.reduce(0, +)
        
        let dailyGoal = Double(max(1, type.getGoal(from: settings)))
        let periodGoal: Double
        switch selectedPeriod {
        case .week: periodGoal = dailyGoal * 7
        case .month: periodGoal = dailyGoal * Double(totalDaysInPeriod)

        }
        
        let safeGoal = max(1, periodGoal)
        let progress = min(totalCount / safeGoal, 1.0)
        let percentage = Int(round(progress * 100))
        let pColor = progressColor(percentage: progress)
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(type.shortLocalizedName(for: settings.language))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(pColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(pColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        .animation(.easeOut, value: progress)
                }
            }
            .frame(height: 6)
            
            Text("\(Int(totalCount))/\(Int(safeGoal))")
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
