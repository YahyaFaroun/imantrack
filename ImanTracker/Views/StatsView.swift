import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \DailyRecord.date, order: .forward) private var allDailyRecords: [DailyRecord]
    @Query private var allSettings: [UserSettings]
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.language == "ar" ? "ar_SA" : (settings.language == "en" ? "en_US" : "de_DE"))
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }
    
    private func localizedMonthName(forAbbreviation abbr: String) -> String {
        switch settings.language {
        case "en":
            switch abbr {
            case "Feb": return "Feb"
            case "Mär": return "Mar"
            case "Apr": return "Apr"
            default: return abbr
            }
        case "ar":
            switch abbr {
            case "Feb": return "فبراير"
            case "Mär": return "مارس"
            case "Apr": return "أبريل"
            default: return abbr
            }
        default: // de
            switch abbr {
            case "Feb": return "Feb"
            case "Mär": return "Mär"
            case "Apr": return "Apr"
            default: return abbr
            }
        }
    }
    
    private func localizedWeekName(_ week: String) -> String {
        guard settings.language == "ar" else { return week }
        switch week {
        case "W1": return "أسبوع ١"
        case "W2": return "أسبوع ٢"
        case "W3": return "أسبوع ٣"
        case "W4": return "أسبوع ٤"
        default: return week
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Month Picker Header (mock)
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(currentMonthString)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        // 1. Koran
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.tr("koran_sec", settings.language))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            let calendar = Calendar.current
                            let currentMonthRecords = allDailyRecords.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
                            let pagesThisMonth = currentMonthRecords.map { $0.quranPagesRead }.reduce(0, +)
                            let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
                            let monthlyGoal = max(1, settings.quranDailyGoal) * daysInMonth
                            
                            let totalQuranPagesAllTime = allDailyRecords.map { $0.quranPagesRead }.reduce(0, +)
                            let quranPercentage = (Double(totalQuranPagesAllTime) / 604.0) * 100.0
                            
                            HStack {
                                Text(String(format: L10n.tr("stats_this_month_pages", settings.language), pagesThisMonth, monthlyGoal))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(String(format: "%.1f", quranPercentage))% \(L10n.tr("koran_sec", settings.language))")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.islamicGreen)
                                    .fontWeight(.bold)
                            }
                            
                            Chart {
                                ForEach(allDailyRecords) { record in
                                    BarMark(
                                        x: .value("Day", record.date, unit: .day),
                                        y: .value("Pages", record.quranPagesRead)
                                    )
                                    .foregroundStyle(Theme.islamicGreen.gradient)
                                    .cornerRadius(4)
                                }
                            }
                            .frame(height: 120)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.day(), centered: true)
                                }
                            }
                            
                            Text(String(format: L10n.tr("stats_avg_pages", settings.language), Double(allDailyRecords.map { $0.quranPagesRead }.reduce(0, +)) / Double(max(1, allDailyRecords.count))))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // 2. Adhkar
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.tr("tab_adhkar", settings.language))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            let morningCount = allDailyRecords.filter { $0.morgenAdhkarDone }.count
                            let eveningCount = allDailyRecords.filter { $0.abendAdhkarDone }.count
                            let sleepCount = allDailyRecords.filter { $0.schlafAdhkarDone }.count
                            let totalDays = max(1, allDailyRecords.count)
                            
                            let fridayRecords = allDailyRecords.filter { record in
                                Calendar.current.component(.weekday, from: record.date) == 6
                            }
                            let alKahfCount = fridayRecords.filter { $0.surahAlKahfDone }.count
                            let totalFridays = fridayRecords.count
                            let isFridayToday = Calendar.current.component(.weekday, from: LocationAndSolarManager.shared.currentTrackingDate) == 6
                            let showAlKahf = totalFridays > 0 || isFridayToday
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                adhkarStatRing(title: L10n.tr("adhkar_morning", settings.language), count: morningCount, total: totalDays)
                                adhkarStatRing(title: L10n.tr("adhkar_evening", settings.language), count: eveningCount, total: totalDays)
                                adhkarStatRing(title: L10n.tr("adhkar_sleep", settings.language), count: sleepCount, total: totalDays)
                                if showAlKahf {
                                    adhkarStatRing(title: L10n.tr("surah_alkahf", settings.language), count: alKahfCount, total: max(1, totalFridays))
                                }
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // 3. Tasbih
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.tr("tasbih_sec", settings.language))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            let istighfarTotal = allDailyRecords.map { $0.istighfarCount }.reduce(0, +)
                            let salawatTotal = allDailyRecords.map { $0.salawatCount }.reduce(0, +)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Istighfar – \(String(format: L10n.tr("stats_total", settings.language), istighfarTotal))")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(String(format: L10n.tr("stats_avg_dhikr", settings.language), istighfarTotal / max(1, allDailyRecords.count)))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Salawat – \(String(format: L10n.tr("stats_total", settings.language), salawatTotal))")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(String(format: L10n.tr("stats_avg_dhikr", settings.language), salawatTotal / max(1, allDailyRecords.count)))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Mini Bar Chart 4 weeks (mock)
                            Chart {
                                BarMark(x: .value("Week", localizedWeekName("W1")), y: .value("Count", 700))
                                BarMark(x: .value("Week", localizedWeekName("W2")), y: .value("Count", 850))
                                BarMark(x: .value("Week", localizedWeekName("W3")), y: .value("Count", 600))
                                BarMark(x: .value("Week", localizedWeekName("W4")), y: .value("Count", 950))
                            }
                            .foregroundStyle(Color.blue.gradient)
                            .frame(height: 80)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // 3-Month Comparison (mock)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.tr("stats_comparison", settings.language))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                            
                            Chart {
                                BarMark(x: .value("Month", localizedMonthName(forAbbreviation: "Feb")), y: .value("Quran", 120))
                                BarMark(x: .value("Month", localizedMonthName(forAbbreviation: "Mär")), y: .value("Quran", 150))
                                BarMark(x: .value("Month", localizedMonthName(forAbbreviation: "Apr")), y: .value("Quran", 142))
                            }
                            .foregroundStyle(Theme.islamicGreen.gradient)
                            .frame(height: 100)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
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
    
    private func adhkarStatRing(title: String, count: Int, total: Int) -> some View {
        let progress = min(Double(count) / Double(total), 1.0)
        return VStack {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(Theme.islamicGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(count) \(settings.language == "ar" ? "أيام" : (settings.language == "en" ? "days" : "Tage"))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(settings.language == "ar" ? "من \(total) يوم" : (settings.language == "en" ? "of \(total) days" : "von \(total) Tagen"))
                .font(.caption2)
                .foregroundColor(.gray)
            if count >= total && total > 0 {
                Text("✓")
                    .font(.caption)
                    .foregroundColor(Theme.islamicGreen)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
