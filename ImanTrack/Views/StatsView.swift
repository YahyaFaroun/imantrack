import SwiftUI
import SwiftData
import Charts

enum PeriodFilter: String, CaseIterable, Identifiable {
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"
    
    var id: String { self.rawValue }
    
    func localizedName(for lang: String) -> String {
        switch lang {
        case "en":
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            }
        case "ar":
            switch self {
            case .week: return "أسبوع"
            case .month: return "شهر"
            case .year: return "سنة"
            }
        default:
            switch self {
            case .week: return "Woche"
            case .month: return "Monat"
            case .year: return "Jahr"
            }
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
        formatter.locale = Locale(identifier: settings.language == "ar" ? "ar_SA" : (settings.language == "en" ? "en_US" : "de_DE"))
        
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "w"
            let weekNum = formatter.string(from: solarManager.currentTrackingDate)
            if settings.language == "de" {
                return "Kalenderwoche \(weekNum)"
            } else if settings.language == "ar" {
                return "الأسبوع \(weekNum)"
            } else {
                return "Week \(weekNum)"
            }
        case .month:
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: solarManager.currentTrackingDate)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: solarManager.currentTrackingDate)
        }
    }
    
    private func chartDataPoints(for valueExtractor: @escaping (DailyRecord) -> Double) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        
        switch selectedPeriod {
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2 // Montag
            guard let monday = calendar.date(from: components) else { return [] }
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: settings.language == "ar" ? "ar_SA" : (settings.language == "en" ? "en_US" : "de_DE"))
            
            var points: [ChartDataPoint] = []
            for i in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: i, to: monday) else { continue }
                let record = allDailyRecords.first { calendar.isDate($0.date, inSameDayAs: dayDate) }
                let value = record.map(valueExtractor) ?? 0.0
                
                formatter.dateFormat = "E"
                let label = formatter.string(from: dayDate)
                points.append(ChartDataPoint(label: label, date: dayDate, value: value))
            }
            return points
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let firstOfMonth = calendar.date(from: components) else { return [] }
            
            let range = calendar.range(of: .day, in: .month, for: now)
            let numberOfDays = range?.count ?? 30
            
            var points: [ChartDataPoint] = []
            for day in 1...numberOfDays {
                guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
                let record = allDailyRecords.first { calendar.isDate($0.date, inSameDayAs: dayDate) }
                let value = record.map(valueExtractor) ?? 0.0
                
                points.append(ChartDataPoint(label: "\(day)", date: dayDate, value: value))
            }
            return points
            
        case .year:
            let currentYear = calendar.component(.year, from: now)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: settings.language == "ar" ? "ar_SA" : (settings.language == "en" ? "en_US" : "de_DE"))
            let monthSymbols = formatter.shortMonthSymbols ?? ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
            
            var points: [ChartDataPoint] = []
            for month in 1...12 {
                let monthRecords = allDailyRecords.filter { record in
                    let yearOfRecord = calendar.component(.year, from: record.date)
                    let monthOfRecord = calendar.component(.month, from: record.date)
                    return yearOfRecord == currentYear && monthOfRecord == month
                }
                
                let totalValue = monthRecords.map(valueExtractor).reduce(0.0, +)
                let label = monthSymbols[month - 1]
                
                var components = DateComponents()
                components.year = currentYear
                components.month = month
                components.day = 1
                let monthDate = calendar.date(from: components)
                
                points.append(ChartDataPoint(label: label, date: monthDate, value: totalValue))
            }
            return points
        }
    }
    
    private var filteredRecordsForAdhkar: [DailyRecord] {
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
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let firstOfMonth = calendar.date(from: components) else { return [] }
            let range = calendar.range(of: .day, in: .month, for: now)
            let numberOfDays = range?.count ?? 30
            
            return allDailyRecords.filter { record in
                if let diff = calendar.dateComponents([.day], from: firstOfMonth, to: record.date).day {
                    return diff >= 0 && diff < numberOfDays
                }
                return false
            }
            
        case .year:
            let currentYear = calendar.component(.year, from: now)
            return allDailyRecords.filter { record in
                return calendar.component(.year, from: record.date) == currentYear
            }
        }
    }
    
    private var totalDaysInPeriod: Int {
        let calendar = Calendar.current
        let now = solarManager.currentTrackingDate
        switch selectedPeriod {
        case .week:
            return 7
        case .month:
            let range = calendar.range(of: .day, in: .month, for: now)
            return range?.count ?? 30
        case .year:
            let year = calendar.component(.year, from: now)
            let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            return isLeapYear ? 366 : 365
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
            guard let monday = calendar.date(from: components) else { return 1 }
            start = monday
            count = 7
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let firstOfMonth = calendar.date(from: components) else { return 4 }
            start = firstOfMonth
            let range = calendar.range(of: .day, in: .month, for: now)
            count = range?.count ?? 30
        case .year:
            var components = calendar.dateComponents([.year], from: now)
            components.month = 1
            components.day = 1
            guard let firstOfYear = calendar.date(from: components) else { return 52 }
            start = firstOfYear
            let isLeapYear = (components.year! % 4 == 0 && components.year! % 100 != 0) || (components.year! % 400 == 0)
            count = isLeapYear ? 366 : 365
        }
        
        var fridays = 0
        for i in 0..<count {
            if let d = calendar.date(byAdding: .day, value: i, to: start) {
                if calendar.component(.weekday, from: d) == 6 {
                    fridays += 1
                }
            }
        }
        return max(1, fridays)
    }
    
    private var currentQuranGoalValue: Double {
        switch selectedPeriod {
        case .week, .month:
            return Double(settings.quranDailyGoal)
        case .year:
            return Double(settings.quranDailyGoal * 30)
        }
    }
    
    private var currentTasbihGoalValue: Double {
        let dailyGoal = Double(selectedDhikrType.getGoal(from: settings))
        switch selectedPeriod {
        case .week, .month:
            return dailyGoal
        case .year:
            return dailyGoal * 30
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Global Period Picker
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(PeriodFilter.allCases) { period in
                                Text(period.localizedName(for: settings.language)).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Current Date Header
                        Text(currentPeriodString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        // 1. Quran Section
                        quranCardView
                        
                        // 2. Adhkar Section
                        adhkarCardView
                        
                        // 3. Tasbih Section
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
        let totalPages = dataPoints.map { $0.value }.reduce(0, +)
        let hasNoData = dataPoints.allSatisfy { $0.value == 0 }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("koran_sec", settings.language))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(settings.language == "de" ? "Gesamt gelesene Seiten: \(Int(totalPages))" : (settings.language == "ar" ? "إجمالي الصفحات المقروءة: \(Int(totalPages))" : "Total pages read: \(Int(totalPages))"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "book.fill")
                    .foregroundColor(Theme.islamicGreen)
                    .font(.title2)
            }
            
            if hasNoData {
                emptyStateView
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        BarMark(
                            x: .value("Day", point.label),
                            y: .value("Pages", point.value)
                        )
                        .foregroundStyle(Theme.islamicGreen.gradient)
                        .cornerRadius(4)
                    }
                    
                    RuleMark(
                        y: .value("Goal", currentQuranGoalValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text(settings.language == "de" ? "Ziel" : (settings.language == "ar" ? "الهدف" : "Goal"))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .background(Theme.cardBackground.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0))
                }
                .chartYAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                }
                .animation(.spring(), value: selectedPeriod)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var adhkarCardView: some View {
        let morningCount = filteredRecordsForAdhkar.filter { $0.morgenAdhkarDone }.count
        let eveningCount = filteredRecordsForAdhkar.filter { $0.abendAdhkarDone }.count
        let sleepCount = filteredRecordsForAdhkar.filter { $0.schlafAdhkarDone }.count
        
        let fridaysCount = filteredRecordsForAdhkar.filter { record in
            let calendar = Calendar.current
            return calendar.component(.weekday, from: record.date) == 6 && record.surahAlKahfDone
        }.count
        
        let fajrCount = filteredRecordsForAdhkar.filter { $0.fajrPrayerStatus == "onTime" || $0.fajrPrayerStatus == "late" || $0.isFajrPrayed }.count
        
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr("tab_adhkar", settings.language))
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                adhkarStatRing(
                    title: L10n.tr("adhkar_sleep", settings.language),
                    count: sleepCount,
                    total: totalDaysInPeriod,
                    color: .indigo
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_morning", settings.language),
                    count: morningCount,
                    total: totalDaysInPeriod,
                    color: Theme.islamicGreen
                )
                
                adhkarStatRing(
                    title: L10n.tr("adhkar_evening", settings.language),
                    count: eveningCount,
                    total: totalDaysInPeriod,
                    color: .orange
                )
                
                adhkarStatRing(
                    title: L10n.tr("surah_alkahf", settings.language),
                    count: fridaysCount,
                    total: totalFridaysInPeriod,
                    color: .blue
                )
                
                adhkarStatRing(
                    title: L10n.tr("fajr_prayer", settings.language),
                    count: fajrCount,
                    total: totalDaysInPeriod,
                    color: .teal
                )
            }
            
            if totalDaysInPeriod > 0 {
                let fajrOnTimeCount = filteredRecordsForAdhkar.filter { $0.fajrPrayerStatus == "onTime" }.count
                let fajrLateCount = filteredRecordsForAdhkar.filter { $0.fajrPrayerStatus == "late" }.count
                
                HStack {
                    Spacer()
                    Text("Fajr: \(fajrOnTimeCount)x \(L10n.tr("fajr_status_ontime", settings.language)) • \(fajrLateCount)x \(L10n.tr("fajr_status_late", settings.language))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var tasbihCardView: some View {
        let dataPoints = chartDataPoints(for: { selectedDhikrType.getValue(from: $0) })
        let totalCount = dataPoints.map { $0.value }.reduce(0, +)
        let hasNoData = dataPoints.allSatisfy { $0.value == 0 }
        
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("tasbih_sec", settings.language))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(settings.language == "de" ? "Gesamt: \(Int(totalCount))" : (settings.language == "ar" ? "المجموع: \(Int(totalCount))" : "Total: \(Int(totalCount))"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "hands.sparkles.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                // Horizontal Scroll Pill Picker for Dhikr categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TasbihCategory.allCases) { type in
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    selectedDhikrType = type
                                }
                            }) {
                                Text(type.localizedName(for: settings.language))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedDhikrType == type ? Color.blue : Theme.background)
                                    .foregroundColor(selectedDhikrType == type ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if hasNoData {
                emptyStateView
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        BarMark(
                            x: .value("Day", point.label),
                            y: .value("Count", point.value)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    
                    RuleMark(
                        y: .value("Goal", currentTasbihGoalValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text(settings.language == "de" ? "Ziel" : (settings.language == "ar" ? "الهدف" : "Goal"))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .background(Theme.cardBackground.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0))
                }
                .chartYAxis {
                    AxisMarks(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                }
                .animation(.spring(), value: selectedPeriod)
                .animation(.easeInOut, value: selectedDhikrType)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text(settings.language == "de" ? "Noch keine Daten für diesen Zeitraum" : (settings.language == "ar" ? "لا توجد بيانات لهذه الفترة" : "No data available for this period"))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    private func adhkarStatRing(title: String, count: Int, total: Int, color: Color) -> some View {
        let progress = total > 0 ? min(Double(count) / Double(total), 1.0) : 0.0
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text(settings.language == "ar" ? "من \(total)" : (settings.language == "en" ? "of \(total)" : "von \(total)"))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
