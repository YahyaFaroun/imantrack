import os

with open("scratch/verses.swift", "r") as f:
    verses_array = f.read()

quran_view_code = f"""import SwiftUI
import Combine
import SwiftData

class QuranViewModel: ObservableObject {{
    @Published var lastReadVerseIndex: Int {{
        didSet {{
            UserDefaults.standard.set(lastReadVerseIndex, forKey: "lastReadVerseIndex")
        }}
    }}
    
    @Published var readVerses: Set<Int> {{
        didSet {{
            if let data = try? JSONEncoder().encode(Array(readVerses)) {{
                UserDefaults.standard.set(data, forKey: "readVersesData")
            }}
        }}
    }}
    
    init() {{
        self.lastReadVerseIndex = UserDefaults.standard.integer(forKey: "lastReadVerseIndex")
        if let data = UserDefaults.standard.data(forKey: "readVersesData"),
           let array = try? JSONDecoder().decode([Int].self, from: data) {{
            self.readVerses = Set(array)
        }} else {{
            self.readVerses = []
        }}
    }}
    
    func markAsRead(_ index: Int) -> Bool {{
        if !readVerses.contains(index) {{
            readVerses.insert(index)
            lastReadVerseIndex = max(lastReadVerseIndex, index)
            return true
        }}
        return false
    }}
}}

// TODO: Load full Quran from JSON bundle
{verses_array}

struct QuranView: View {{
    @Environment(\\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    
    @StateObject private var viewModel = QuranViewModel()
    
    private var todayRecord: DailyRecord {{
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let existing = allDailyRecords.first(where: {{ cal.isDate($0.date, inSameDayAs: today) }}) {{
            return existing
        }} else {{
            let newRecord = DailyRecord(date: today)
            modelContext.insert(newRecord)
            try? modelContext.save()
            return newRecord
        }}
    }}
    
    var body: some View {{
        NavigationStack {{
            ZStack {{
                Theme.background.ignoresSafeArea()
                
                ScrollViewReader {{ proxy in
                    ScrollView {{
                        LazyVStack(spacing: 0) {{
                            ForEach(quranVerses, id: \\.id) {{ verse in
                                let isRead = viewModel.readVerses.contains(verse.id)
                                
                                VStack(spacing: 0) {{
                                    // Section Headers
                                    if verse.ayah == 1 {{
                                        VStack(spacing: 12) {{
                                            Text(getSurahName(verse.surah))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.islamicGreen)
                                            
                                            if verse.surah != 1 {{
                                                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                                    .font(.custom("KFGQPCUthmanicHafs", size: 24))
                                                    .foregroundColor(.white)
                                            }}
                                        }}
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(Theme.background)
                                    }}
                                    
                                    // Verse Content
                                    VStack(alignment: .trailing, spacing: 8) {{
                                        HStack(alignment: .top) {{
                                            if verse.id == viewModel.lastReadVerseIndex {{
                                                Text("Zuletzt gelesen - آخر قراءة")
                                                    .font(.caption2)
                                                    .foregroundColor(Theme.islamicGreen)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Theme.islamicGreen.opacity(0.2))
                                                    .cornerRadius(4)
                                                Spacer()
                                            }}
                                            
                                            // Flowing Arabic text with verse marker inline
                                            Text("\\(verse.arabic) ﴾\\(arabicNumber(verse.ayah))﴿")
                                                .font(.custom("KFGQPCUthmanicHafs", size: 22))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.trailing)
                                                .environment(\\.layoutDirection, .rightToLeft)
                                        }}
                                    }}
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .background(isRead ? Color(hex: "#2A2A2A") : Theme.background)
                                    .onDisappear {{
                                        markAsRead(verse.id)
                                    }}
                                }}
                                .id(verse.id)
                            }}
                        }}
                    }}
                    .onAppear {{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {{
                            proxy.scrollTo(viewModel.lastReadVerseIndex, anchor: .top)
                        }}
                    }}
                }}
            }}
            .navigationTitle("Koran - القرآن")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }}
    }}
    
    private func markAsRead(_ index: Int) {{
        if viewModel.markAsRead(index) {{
            let record = todayRecord
            // Count 15 verses as 1 page roughly
            if viewModel.readVerses.count % 15 == 0 {{
                record.quranPagesRead += 1
                try? modelContext.save()
            }}
        }}
    }}
    
    private func getSurahName(_ surah: Int) -> String {{
        switch surah {{
        case 1: return "سورة الفاتحة"
        case 2: return "سورة البقرة"
        default: return "سورة"
        }}
    }}
    
    private func arabicNumber(_ num: Int) -> String {{
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: NSNumber(value: num)) ?? "\\(num)"
    }}
}}

extension Color {{
    init(hex: String) {{
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {{
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }}

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }}
}}
"""

with open("ImanTracker/Views/QuranView.swift", "w") as f:
    f.write(quran_view_code)
