import SwiftUI
import SwiftData

struct AlKahfReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    
    @State private var verses: [Verse] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 24)
    @State private var lastFontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 24)
    @AppStorage("quranFontType") private var quranFontType: String = "uthmanic"
    @AppStorage("quranTheme") private var quranTheme: String = "system"
    @Environment(\.colorScheme) var colorScheme
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(Theme.islamicGreen)
                } else if hasError {
                    VStack(spacing: 12) {
                        Text("Fehler beim Laden von Sure Al-Kahf")
                            .foregroundColor(.secondary)
                        Button("Erneut versuchen") {
                            loadSurah()
                        }
                        .tint(Theme.islamicGreen)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Basmala
                            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                .font(Theme.uthmaniFont(size: fontSize * 0.85))
                                .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity)
                                .environment(\.layoutDirection, .rightToLeft)
                                .environment(\.locale, Locale(identifier: "ar"))
                            
                            // Attributed Text
                            JustifiedText(attributedText: concatenatedString(for: verses), theme: quranTheme)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                                .environment(\.layoutDirection, .rightToLeft)
                            
                            Button(action: {
                                todayRecord.surahAlKahfDone = true
                                todayRecord.surahAlKahfTime = Date()
                                try? modelContext.save()
                                dismiss()
                            }) {
                                Text("Als gelesen markieren")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.islamicGreen)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 50)
                            }
                        }
                    }
                    .simultaneousGesture(
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
            }
            .navigationTitle("Sure Al-Kahf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme))
                }
            }
            .onAppear {
                loadSurah()
            }
        }
    }
    
    private func loadSurah() {
        isLoading = true
        hasError = false
        Task {
            do {
                let fetched = try await QuranAPIService.shared.fetchSurah(surahNumber: 18)
                await MainActor.run {
                    self.verses = fetched
                    self.isLoading = false
                }
            } catch {
                print("Error loading Al-Kahf: \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func concatenatedString(for versesList: [Verse]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = Theme.uthmaniUIFont(size: fontSize)
        
        for verse in versesList {
            let text = "\(verse.arabic.cleanQuranText()) \u{FD3F}\(arabicNumber(verse.ayah))\u{FD3E} "
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: Theme.getQuranUITextColor(for: quranTheme, systemColorScheme: colorScheme),
                .ligature: 2
            ]
            let verseString = NSAttributedString(string: text, attributes: attributes)
            result.append(verseString)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.baseWritingDirection = .rightToLeft
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
    private func arabicNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}
