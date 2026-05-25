import os

# 1. Lies verses.swift
with open("/Users/princepalestine/Desktop/ImanTracker/ImanTracker/scratch/verses.swift", "r") as f:
    verses_content = f.read()

# 2. Definiere den View Code mit Lokalisierung
view_code = """
struct QuranView: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    @Query private var allSettings: [UserSettings]
    
    @StateObject private var viewModel = QuranViewModel()
    
    // FIX 2 — Schriftgröße mit Pinch-to-Zoom, UserDefaults-persistent
    @State private var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 22)
    @State private var lastFontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 22)
    
    // FIX 3 — Banner
    @State private var showInfoBanner: Bool = UserDefaults.standard.object(forKey: "quranBannerDismissed") == nil
    
    // FIX 4 — Session Tracking
    @State private var sessionReadVerses = Set<Int>()
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var todayRecord: DailyRecord {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let existing = allDailyRecords.first(where: { cal.isDate($0.date, inSameDayAs: today) }) {
            return existing
        } else {
            let newRecord = DailyRecord(date: today)
            modelContext.insert(newRecord)
            try? modelContext.save()
            return newRecord
        }
    }
    
    // Verse nach Surah gruppiert
    private var versesGroupedBySurah: [(surah: Int, verses: [(id: Int, surah: Int, ayah: Int, arabic: String)])] {
        let surahNumbers = Array(Set(quranVerses.map { $0.surah })).sorted()
        return surahNumbers.map { surahNum in
            (surah: surahNum, verses: quranVerses.filter { $0.surah == surahNum })
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // FIX 3 — Hinweis-Banner
                            if showInfoBanner {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(L10n.tr("quran_warning", settings.language))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            showInfoBanner = false
                                            UserDefaults.standard.set(true, forKey: "quranBannerDismissed")
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.05))
                            }
                            
                            // FIX 1 — Fließtext pro Surah
                            ForEach(versesGroupedBySurah, id: \\.surah) { group in
                                VStack(alignment: .center, spacing: 0) {
                                    // Surah-Header
                                    VStack(spacing: 8) {
                                        Text(getSurahName(group.surah))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Theme.islamicGreen)
                                        
                                        // Basmala (für Al-Baqara, nicht Al-Fatiha)
                                        if group.surah != 1 {
                                            Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ")
                                                .font(.custom("Geeza Pro", size: fontSize))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .environment(\\.layoutDirection, .rightToLeft)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 16)
                                    
                                    ForEach(group.verses, id: \\.id) { verse in
                                        let isRead = viewModel.readVerses.contains(verse.id)
                                        let isLastRead = viewModel.lastReadVerseIndex == verse.id
                                        
                                        VStack(spacing: 8) {
                                            if isLastRead {
                                                Text(L10n.tr("last_read", settings.language))
                                                    .font(.caption)
                                                    .foregroundColor(Theme.islamicGreen)
                                                    .padding(.top, 4)
                                            }
                                            
                                            Text("\\(verse.arabic.trimmingCharacters(in: .whitespacesAndNewlines)) ﴾\\(arabicNumber(verse.ayah))﴿")
                                                .font(.custom("Geeza Pro", size: fontSize))
                                                .environment(\\.layoutDirection, .rightToLeft)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.white)
                                                .flipsForRightToLeftLayoutDirection(false)
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(isRead ? Color(red: 0.16, green: 0.16, blue: 0.16) : Color.clear)
                                                .background(
                                                    GeometryReader { geo -> Color in
                                                        let frame = geo.frame(in: .global)
                                                        let screenHeight = UIScreen.main.bounds.height
                                                        if frame.maxY < 0 || frame.minY > screenHeight {
                                                            // verse is off screen
                                                            DispatchQueue.main.async {
                                                                markAsRead(verse.id)
                                                            }
                                                        }
                                                        return Color.clear
                                                    }
                                                )
                                                .id(verse.id)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                            }
                        }
                        .environment(\\.layoutDirection, .rightToLeft)
                    }
                    .onAppear {
                        if viewModel.lastReadVerseIndex > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    proxy.scrollTo(viewModel.lastReadVerseIndex, anchor: .top)
                                }
                            }
                        }
                    }
                }
                // FIX 2 — Pinch-to-Zoom
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newSize = lastFontSize * value
                            fontSize = min(max(newSize, 16), 40)
                        }
                        .onEnded { _ in
                            lastFontSize = fontSize
                            UserDefaults.standard.set(Double(fontSize), forKey: "quranFontSize")
                        }
                )
            }
            .navigationTitle(L10n.tr("tab_quran", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func markAsRead(_ index: Int) {
        guard !viewModel.readVerses.contains(index) else { return }
        viewModel.markAsRead(index)
        
        let record = todayRecord
        if viewModel.readVerses.count % 15 == 0 {
            record.quranPagesRead += 1
            try? modelContext.save()
        }
    }

    private func getSurahName(_ surah: Int) -> String {
        switch surah {
        case 1: return "سورة الفاتحة"
        case 2: return "سورة البقرة"
        default: return "سورة"
        }
    }
    
    private func arabicNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: NSNumber(value: num)) ?? "\\(num)"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
"""

# 3. Definiere den Anfangscode (QuranViewModel)
viewModel_code = """import SwiftUI
import Combine
import SwiftData

class QuranViewModel: ObservableObject {
    @Published var readVerses: Set<Int> = []
    @Published var lastReadVerseIndex: Int = 0
    
    init() {
        self.lastReadVerseIndex = UserDefaults.standard.integer(forKey: "lastReadVerseIndex")
        if let data = UserDefaults.standard.data(forKey: "readVersesData"),
           let array = try? JSONDecoder().decode([Int].self, from: data) {
            self.readVerses = Set(array)
        } else {
            self.readVerses = []
        }
        loadQuranFromJSON()
    }
    
    func markAsRead(_ index: Int) {
        guard !readVerses.contains(index) else { return }
        readVerses.insert(index)
        if index > lastReadVerseIndex {
            lastReadVerseIndex = index
        }
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        UserDefaults.standard.set(lastReadVerseIndex, forKey: "lastReadVerseIndex")
        if let data = try? JSONEncoder().encode(Array(readVerses)) {
            UserDefaults.standard.set(data, forKey: "readVersesData")
        }
    }
    
    func loadQuranFromJSON() {
        guard let url = Bundle.main.url(
            forResource: "quran_arabic",
            withExtension: "json"
        ) else {
            return
        }
        _ = url
    }
}

"""

# 4. Schreibe alles in QuranView.swift zusammen
with open("/Users/princepalestine/Desktop/ImanTracker/ImanTracker/ImanTracker/Views/QuranView.swift", "w") as f:
    f.write(viewModel_code)
    f.write(verses_content)
    f.write("\n\n")
    f.write(view_code)

print("QuranView.swift wurde erfolgreich neu generiert und lokalisiert!")
