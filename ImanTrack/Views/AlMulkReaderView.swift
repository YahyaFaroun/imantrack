import SwiftUI
#if os(iOS) && !SKIP
import SwiftData
#endif

struct AlMulkReaderView: View {
    @Environment(\.dismiss) var dismiss
    #if os(iOS) && !SKIP
    @Environment(\.modelContext) var modelContext
    @Query var allDailyRecords: [DailyRecord]
    @Query var allSettings: [UserSettings]
    #endif
    
    var onComplete: (() -> Void)? = nil
    
    @State var verses: [Verse] = []
    @State var isLoading = true
    @State var hasError = false
    @State var fontSize: CGFloat = CGFloat((UserDefaults.standard.double(forKey: "quranFontSize") >= 22 && UserDefaults.standard.double(forKey: "quranFontSize") <= 42)
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 30)
    @State var lastFontSize: CGFloat = CGFloat((UserDefaults.standard.double(forKey: "quranFontSize") >= 22 && UserDefaults.standard.double(forKey: "quranFontSize") <= 42)
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 30)
    @AppStorage("quranFontType") var quranFontType: String = "uthmanic"
    @AppStorage("quranTheme") var quranTheme: String = "system"
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(Theme.islamicGreen)
                } else if hasError {
                    VStack(spacing: 12) {
                        Text("Fehler beim Laden von Sure Al-Mulk")
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
                                .font(Theme.quranFont(type: quranFontType, size: fontSize * 0.85))
                                .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity)
                                .environment(\.layoutDirection, .rightToLeft)
                                .environment(\.locale, Locale(identifier: "ar"))
                            
                            Group {
                                #if os(iOS) && !SKIP
                                JustifiedText(attributedText: concatenatedString(for: verses), theme: quranTheme)
                                #else
                                JustifiedText(attributedText: concatenatedString(arabicTexts: verses.map { $0.arabic }, ayahNumbers: verses.map { $0.ayah }), theme: quranTheme)
                                #endif
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                            .environment(\.layoutDirection, .rightToLeft)
                            
                            Button(action: {
                                onComplete?()
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
                                let clamped = min(max(newSize, 22), 42)
                                fontSize = round(clamped / 2.0) * 2.0
                            }
                            .onEnded { _ in
                                lastFontSize = fontSize
                                UserDefaults.standard.set(Double(fontSize), forKey: "quranFontSize")
                            }
                    )
                }
            }
            .navigationTitle("Sure Al-Mulk")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbarBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
                let fetched = try await QuranAPIService.shared.fetchSurah(surahNumber: 67)
                await MainActor.run {
                    self.verses = fetched
                    self.isLoading = false
                }
            } catch {
                print("Error loading Al-Mulk: \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    #if os(iOS) && !SKIP
    private func concatenatedString(for versesList: [Verse]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = Theme.quranUIFont(type: quranFontType, size: fontSize)
        let numberFont = Theme.quranUIFont(type: quranFontType, size: fontSize * 0.85)
        let color = Theme.getQuranUITextColor(for: quranTheme, systemColorScheme: colorScheme)
        
        for verse in versesList {
            let verseText = "\(verse.arabic.cleanQuranText()) "
            let numberText = "\u{FD3F}\(arabicNumber(verse.ayah))\u{FD3E} "
            
            let verseString = NSAttributedString(string: verseText, attributes: [
                .font: font,
                .foregroundColor: color,
                .ligature: 2
            ])
            let numberString = NSAttributedString(string: numberText, attributes: [
                .font: numberFont,
                .foregroundColor: color.withAlphaComponent(0.85),
                .ligature: 2
            ])
            
            result.append(verseString)
            result.append(numberString)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.baseWritingDirection = .rightToLeft
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    #else
    private func concatenatedString(arabicTexts: [String], ayahNumbers: [Int]) -> String {
        var result = ""
        for i in 0..<arabicTexts.count {
            result += "\(arabicTexts[i].cleanQuranText()) \u{FD3F}\(arabicNumber(ayahNumbers[i]))\u{FD3E} "
        }
        return result
    }
    #endif
    
    private func arabicNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}
