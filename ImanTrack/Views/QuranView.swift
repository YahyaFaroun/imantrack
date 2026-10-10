import SwiftUI
import SwiftData
import Combine

class QuranViewModel: ObservableObject {
    // Load stored font size safely; fallback to 30 pt if no valid value exists or if < 22 pt.
    private static func storedFontSize() -> CGFloat {
        let size = UserDefaults.standard.double(forKey: "quranFontSize")
        return (size >= 22 && size <= 42) ? CGFloat(size) : 30
    }
    @Published var fontSize: CGFloat = storedFontSize()
    @Published var lastFontSize: CGFloat = storedFontSize()
    @Published var navTitle: String = ""
    @Published var hasScrolledToLastRead: Bool = false
    
    init() {
        UserDefaults.standard.set(false, forKey: "quranHasRestoredInitialPosition")
    }
}

struct QuranView: View {
    @ObservedObject var viewModel: QuranViewModel
    @Binding var selectedTab: Int

    @Environment(\.modelContext) var modelContext
    @Query var allDailyRecords: [DailyRecord]
    @Query var allSettings: [UserSettings]
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var progressStore = QuranProgressStore.shared
    @StateObject private var quranAPIService = QuranAPIService.shared

    @AppStorage("quranTheme") var quranTheme: String = "system"
    @AppStorage("quranFontType") var quranFontType: String = "uthmanic"
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @StateObject var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    @State private var startPage: Int? = nil
    @State private var showKhatmCelebrationAnimation: Bool = false
    @State private var showGapNoticeBanner: Bool = false
    @State private var gapVerseTarget: Verse? = nil

    #if DEBUG
    @State private var debugTopPage: Int = 1
    @State private var debugTopPageGrayCount: Int = 0
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme).ignoresSafeArea()
                
                if !quranAPIService.isLoaded || startPage == nil {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Theme.accent)
                        Text("Quran wird geladen...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        initStartPageIfNeeded()
                    }
                    .onChange(of: quranAPIService.isLoaded) { _, loaded in
                        if loaded {
                            initStartPageIfNeeded()
                        }
                    }
                } else if let start = startPage {
                    ScrollView {
                        #if os(iOS) && !SKIP
                        DisableScrollsToTop().frame(width: 0, height: 0)
                        #endif
                        LazyVStack(spacing: 0) {
                            ForEach(start...604, id: \.self) { pageNum in
                                QuranPageView(
                                    pageNumber: pageNum,
                                    fontSize: viewModel.fontSize,
                                    readFrontier: progressStore.readFrontier,
                                    language: settings.language,
                                    useTajweedHarakat: settings.useTajweedHarakat,
                                    onMarkVersesAsRead: { verses in
                                        markVersesAsRead(verses)
                                    },
                                    onTopVisible: { surahName in
                                        if viewModel.navTitle != surahName {
                                            viewModel.navTitle = surahName
                                        }
                                    },
                                    onCompleteKhatm: {
                                        completeKhatm()
                                    },
                                    onPageScrollUpdate: { pageNum, grayCount in
                                        #if DEBUG
                                        self.debugTopPage = pageNum
                                        self.debugTopPageGrayCount = grayCount
                                        #endif
                                    }
                                )
                                .id(pageNum)
                            }
                        }
                    }
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newSize = viewModel.lastFontSize * value
                                let clamped = min(max(newSize, 22), 42)
                                viewModel.fontSize = round(clamped / 2.0) * 2.0
                            }
                            .onEnded { _ in
                                viewModel.lastFontSize = viewModel.fontSize
                                UserDefaults.standard.set(Double(viewModel.fontSize), forKey: "quranFontSize")
                            }
                    )
                    
                    if showGapNoticeBanner {
                        ZStack {
                            Color.black.opacity(0.65).ignoresSafeArea()
                            
                            VStack(spacing: 20) {
                                Text("📖")
                                    .font(.system(size: 64))
                                
                                Text(L10n.tr("khatm_gap_title", settings.language))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text(L10n.tr("khatm_gap_desc", settings.language))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        showGapNoticeBanner = false
                                    }
                                }) {
                                    Text(L10n.tr("done", settings.language))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Theme.islamicGreen)
                                        .cornerRadius(14)
                                }
                                .padding(.top, 8)
                            }
                            .padding(28)
                            .background(Theme.cardBackground)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .zIndex(100)
                    }
                }

                if showKhatmCelebrationAnimation {
                    ZStack {
                        Color.black.opacity(0.65).ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            Text("🎉")
                                .font(.system(size: 64))
                            
                            Text("ما شاء الله")
                                .font(Theme.quranFont(type: quranFontType, size: 36))
                                .foregroundColor(Theme.islamicGreen)
                            
                            Text(L10n.tr("khatm_title", settings.language))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text(L10n.tr("khatm_desc", settings.language))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showKhatmCelebrationAnimation = false
                                }
                            }) {
                                Text(L10n.tr("done", settings.language))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.islamicGreen)
                                    .cornerRadius(14)
                            }
                            .padding(.top, 8)
                        }
                        .padding(28)
                        .background(Theme.cardBackground)
                        .cornerRadius(28)
                        .padding(.horizontal, 30)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(100)
                }
                
                #if DEBUG
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            let unreadVerse = quranAPIService.getVerseAtIndex(progressStore.readFrontier)
                            let frontierStr = unreadVerse != nil ? "\(unreadVerse!.surah):\(unreadVerse!.ayah) · #\(progressStore.readFrontier)" : "Ende (#\(progressStore.readFrontier))"
                            let unreadPage = unreadVerse?.pageNumber ?? 1
                            
                            Text("Lesefront: \(frontierStr)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                            
                            Text("Nächste Seite: S. \(unreadPage) | Top S. \(debugTopPage): \(debugTopPageGrayCount) grau")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
                .allowsHitTesting(false)
                .zIndex(95)
                #endif
            }
            .navigationTitle(viewModel.navTitle.isEmpty ? L10n.tr("tab_quran", settings.language) : viewModel.navTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
        .onAppear {
            initStartPageIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ResetQuranStartPage"))) { _ in
            self.startPage = nil
            initStartPageIfNeeded()
        }
    }
    
    private func initStartPageIfNeeded() {
        guard quranAPIService.isLoaded, startPage == nil else { return }
        let unreadVerse = quranAPIService.getVerseAtIndex(progressStore.readFrontier)
        let page = unreadVerse?.pageNumber ?? 1
        self.startPage = page
        print("[QURAN_VIEW] Session startPage fixed to: \(page) for readFrontier: \(progressStore.readFrontier)")
    }
    
    private func markVersesAsRead(_ verses: [Verse]) {
        guard let maxVerse = verses.max(by: { 
            (quranAPIService.getVerseIndex(id: $0.id) ?? -1) < (quranAPIService.getVerseIndex(id: $1.id) ?? -1) 
        }) else { return }
        
        if let maxIdx = quranAPIService.getVerseIndex(id: maxVerse.id) {
            progressStore.advance(toIndex: maxIdx + 1, modelContext: modelContext, date: solarManager.currentTrackingDate)
        }
    }
    
    private func completeKhatm() {
        if progressStore.readFrontier < 6236 {
            if let unreadVerse = quranAPIService.getVerseAtIndex(progressStore.readFrontier) {
                gapVerseTarget = unreadVerse
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showGapNoticeBanner = true
                }
            }
        } else {
            progressStore.resetKhatm(modelContext: modelContext)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showKhatmCelebrationAnimation = true
            }
        }
    }
}

// Hilfsstruktur für Suren-Segmente innerhalb einer Seite
struct SurahSegment: Identifiable {
    var id: String { "\(surah):\(verses.first?.ayah ?? 0)" }
    let surah: Int
    let verses: [Verse]
}

struct QuranPageView: View {
    let pageNumber: Int
    let fontSize: CGFloat
    let readFrontier: Int
    let language: String
    let useTajweedHarakat: Bool
    let onMarkVersesAsRead: ([Verse]) -> Void
    var onTopVisible: ((String) -> Void)? = nil
    var onCompleteKhatm: (() -> Void)? = nil
    var onPageScrollUpdate: ((Int, Int) -> Void)? = nil
    
    @AppStorage("quranTheme") var quranTheme: String = "system"
    @AppStorage("quranFontType") var quranFontType: String = "uthmanic"
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var verses: [Verse] = []
    @State var isLoading = false
    @State var hasError = false
    @State private var verseBoundsMap: [String: CGFloat] = [:]
    @State private var segmentVerseBoundsMap: [String: [String: CGFloat]] = [:]
    @State private var segmentMinYMap: [String: CGFloat] = [:]
    @State private var pageMinY: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else if hasError {
                VStack(spacing: 8) {
                    Text("Fehler beim Laden von Seite \(pageNumber)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button(action: { loadPage() }) {
                        Text("Erneut versuchen")
                            .font(.caption.bold())
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Theme.accent, lineWidth: 1))
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                pageContent
            }
            
            pageDivider
            
            if pageNumber == 604 {
                khatmCompletionCard
            }
        }
        #if os(iOS)
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.frame(in: .scrollView).minY
        } action: { _, newMinY in
            self.pageMinY = newMinY
            checkVersesScrollPosition(minY: newMinY)
        }
        #endif
        .onAppear {
            loadPage()
        }
        .onChange(of: pageNumber) { _, _ in
            verses = []
            verseBoundsMap = [:]
            segmentVerseBoundsMap = [:]
            segmentMinYMap = [:]
            loadPage()
        }
    }
    
    private var pageContent: some View {
        VStack(spacing: 0) {
            ForEach(surahSegments, id: \.id) { segment in
                VStack(spacing: 0) {
                    if segment.verses.first?.ayah == 1 {
                        surahHeader(segment.surah)
                        if segment.surah != 1 && segment.surah != 9 {
                            basmalaView
                        }
                    }
                    
                    let (attributedText, verseRanges) = concatenatedString(for: segment.verses)
                    
                    Group {
                        #if os(iOS) && !SKIP
                        JustifiedText(
                            attributedText: attributedText,
                            verseRanges: verseRanges,
                            theme: quranTheme,
                            onVerseBoundsCalculated: { bounds in
                                self.segmentVerseBoundsMap[segment.id] = bounds
                                self.updateVerseBoundsMap()
                            }
                        )
                        .onGeometryChange(for: CGFloat.self) { geo in
                            geo.frame(in: .named("QuranPage_\(pageNumber)")).minY
                        } action: { _, newMinY in
                            self.segmentMinYMap[segment.id] = newMinY
                            self.updateVerseBoundsMap()
                        }
                        #else
                        JustifiedText(attributedText: concatenatedString(arabicTexts: segment.verses.map { $0.arabic }, ayahNumbers: segment.verses.map { $0.ayah }), theme: quranTheme)
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .environment(\.layoutDirection, .rightToLeft)
                }
            }
        }
        .coordinateSpace(name: "QuranPage_\(pageNumber)")
    }
    
    private func updateVerseBoundsMap() {
        var updated: [String: CGFloat] = [:]
        for (segId, relativeMap) in segmentVerseBoundsMap {
            let segMinY = segmentMinYMap[segId] ?? 0
            for (vId, relativeY) in relativeMap {
                updated[vId] = segMinY + relativeY
            }
        }
        self.verseBoundsMap = updated
    }
    
    private var pageDivider: some View {
        HStack(spacing: 16) {
            VStack { Divider().background(Color.gray.opacity(0.3)) }
            Text("\(pageNumber)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.8))
            VStack { Divider().background(Color.gray.opacity(0.3)) }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
    }
    
    private var khatmCompletionCard: some View {
        VStack(spacing: 16) {
            Text("الحمد لله")
                .font(Theme.quranFont(type: quranFontType, size: fontSize * 1.1))
                .foregroundColor(Theme.islamicGreen)
            
            Text(L10n.tr("khatm_title", language))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme))
            
            Text(L10n.tr("khatm_desc", language))
                .font(.subheadline)
                .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button(action: {
                onCompleteKhatm?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(L10n.tr("khatm_button_complete", language))
                        .fontWeight(.bold)
                }
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Theme.islamicGreen, Theme.islamicGreen.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: Theme.islamicGreen.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.islamicGreen.opacity(0.4), lineWidth: 2)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 40)
    }
    
    private func checkVersesScrollPosition(minY: CGFloat) {
        guard !verses.isEmpty else { return }
        
        // Guard: Wait until ALL verse bounds on this page are calculated before detecting read position
        guard verseBoundsMap.count == verses.count else {
            print("[QURAN_DETECT] Page \(pageNumber): bounds incomplete (\(verseBoundsMap.count)/\(verses.count)), skipping detection.")
            return
        }
        
        guard minY < 600 else { return }
        
        let topInset: CGFloat = {
            #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow.safeAreaInsets.top
            }
            #endif
            return 47.0
        }()
        let threshold = topInset + 44.0 + 15.0 // navbar height (44) + 15pt offset buffer
        
        let first5 = Array(verses.prefix(5))
        let first5Bounds = first5.compactMap { verseBoundsMap[$0.id] }
        let first5GlobalMaxY = first5Bounds.map { minY + $0 }
        print("[QURAN_DETECT] Page \(pageNumber): pageMinY=\(String(format: "%.1f", minY)), boundsCount=\(verseBoundsMap.count)/\(verses.count), first5Bounds=\(first5Bounds.map { String(format: "%.1f", $0) }), first5GlobalMaxY=\(first5GlobalMaxY.map { String(format: "%.1f", $0) }), threshold=\(String(format: "%.1f", threshold))")
        
        var readVersesOnPage: [Verse] = []
        for verse in verses {
            if let verseMaxY = verseBoundsMap[verse.id] {
                let globalVerseMaxY = minY + verseMaxY
                if globalVerseMaxY <= threshold {
                    readVersesOnPage.append(verse)
                }
            }
        }
        
        if let maxVerse = readVersesOnPage.max(by: {
            (QuranAPIService.shared.getVerseIndex(id: $0.id) ?? -1) < (QuranAPIService.shared.getVerseIndex(id: $1.id) ?? -1)
        }) {
            if let maxIdx = QuranAPIService.shared.getVerseIndex(id: maxVerse.id) {
                if maxIdx + 1 > readFrontier {
                    let idxInPage = verses.firstIndex(where: { $0.id == maxVerse.id }) ?? 0
                    let prefixVerses = Array(verses[0...idxInPage])
                    onMarkVersesAsRead(prefixVerses)
                }
            }
        }
        
        if let firstSurah = verses.first?.surah, minY > -300 && minY < 400 {
            let grayCount = verses.filter { (QuranAPIService.shared.getVerseIndex(id: $0.id) ?? -1) < readFrontier }.count
            DispatchQueue.main.async {
                onTopVisible?(QuranSurah.getName(firstSurah))
                onPageScrollUpdate?(pageNumber, grayCount)
            }
        }
    }
    
    private func surahHeader(_ surah: Int) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text(QuranSurah.getName(surah))
                    .font(Theme.surahNameFont(size: fontSize * 0.75))
                    .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.7))
                    .tracking(2)
            }
            Spacer()
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private var basmalaView: some View {
        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
            .font(Theme.quranFont(type: quranFontType, size: fontSize * 0.85))
            .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme).opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar"))
    }
    
    #if os(iOS) && !SKIP
    private func concatenatedString(for versesList: [Verse]) -> (NSAttributedString, [String: NSRange]) {
        let result = NSMutableAttributedString()
        var ranges: [String: NSRange] = [:]
        let font = Theme.quranUIFont(type: quranFontType, size: fontSize)
        let numberFont = Theme.quranUIFont(type: quranFontType, size: fontSize * 0.85)
        
        for verse in versesList {
            let location = result.length
            let verseIndex = QuranAPIService.shared.getVerseIndex(id: verse.id) ?? 0
            let isRead = verseIndex < readFrontier
            let defaultColor = Theme.getQuranUITextColor(for: quranTheme, systemColorScheme: colorScheme)
            let color = isRead ? UIColor.gray : defaultColor
            
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
            
            let length = result.length - location
            ranges[verse.id] = NSRange(location: location, length: length)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.baseWritingDirection = .rightToLeft
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return (result, ranges)
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
    
    private var surahSegments: [SurahSegment] {
        var segments: [SurahSegment] = []
        for verse in verses {
            if let last = segments.last, last.surah == verse.surah {
                var updatedVerses = last.verses
                updatedVerses.append(verse)
                segments[segments.count - 1] = SurahSegment(surah: last.surah, verses: updatedVerses)
            } else {
                segments.append(SurahSegment(surah: verse.surah, verses: [verse]))
            }
        }
        return segments
    }
    
    private func loadPage() {
        guard verses.isEmpty && !isLoading else { return }
        
        let offlineVerses = QuranAPIService.shared.getVersesForPage(pageNumber: pageNumber)
        if !offlineVerses.isEmpty {
            self.verses = offlineVerses
            self.isLoading = false
            self.hasError = false
            return
        }
        
        isLoading = true
        hasError = false
        Task {
            do {
                let fetched = try await QuranAPIService.shared.fetchPage(pageNumber: pageNumber)
                await MainActor.run {
                    self.verses = fetched
                    self.isLoading = false
                }
            } catch {
                print("Fehler beim Laden von Seite \(pageNumber): \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
}

// Hilfsstruktur für die 114 Suren
struct QuranSurah {
    static let namesArabic: [String] = [
        "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
        "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
        "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
        "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
        "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
        "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
        "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
        "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
        "التكوير", "الإنفطار", "المطففين", "الإنشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
        "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
        "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
        "المسد", "الإخلاص", "الفلق", "الناس"
    ]
    
    static func getName(_ surahNumber: Int) -> String {
        guard surahNumber >= 1 && surahNumber <= 114 else {
            return "سورة \(surahNumber)"
        }
        return "سورة \(namesArabic[surahNumber - 1])"
    }
}

#if os(iOS) && !SKIP
struct JustifiedText: UIViewRepresentable {
    var attributedText: NSAttributedString
    var verseRanges: [String: NSRange] = [:]
    var theme: String
    var onVerseBoundsCalculated: (([String: CGFloat]) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    class Coordinator: NSObject {
        var lastOriginalText: NSAttributedString?
        var lastModifiedText: NSAttributedString?
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = Theme.getQuranUIBackgroundColor(for: theme, systemColorScheme: colorScheme)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.backgroundColor = Theme.getQuranUIBackgroundColor(for: theme, systemColorScheme: colorScheme)
        
        context.coordinator.lastOriginalText = attributedText
        uiView.attributedText = attributedText
        uiView.textAlignment = .center
        
        uiView.layoutManager.ensureLayout(for: uiView.textContainer)
        
        let layoutManager = uiView.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        guard numberOfGlyphs > 0 else {
            context.coordinator.lastModifiedText = attributedText
            return
        }
        
        var lineRange = NSRange(location: 0, length: 0)
        layoutManager.lineFragmentRect(forGlyphAt: numberOfGlyphs - 1, effectiveRange: &lineRange, withoutAdditionalLayout: true)
        let lastLineCharRange = layoutManager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
        
        if lastLineCharRange.location > 0 && lastLineCharRange.length > 0 {
            let originalString = attributedText.string
            let nsString = originalString as NSString
            let prevCharIndex = lastLineCharRange.location - 1
            let prevChar = nsString.character(at: prevCharIndex)
            
            let mutableAttributed = NSMutableAttributedString(attributedString: attributedText)
            let centerParagraphStyle = NSMutableParagraphStyle()
            centerParagraphStyle.alignment = .center
            centerParagraphStyle.baseWritingDirection = .rightToLeft
            
            if prevChar == 10 { // '\n'
                mutableAttributed.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: lastLineCharRange)
            } else {
                mutableAttributed.insert(NSAttributedString(string: "\n"), at: lastLineCharRange.location)
                let newLastLineRange = NSRange(location: lastLineCharRange.location + 1, length: lastLineCharRange.length)
                mutableAttributed.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: newLastLineRange)
            }
            
            context.coordinator.lastModifiedText = mutableAttributed
            uiView.attributedText = mutableAttributed
        } else {
            context.coordinator.lastModifiedText = attributedText
        }
        
        var boundsMap: [String: CGFloat] = [:]
        for (verseId, charRange) in verseRanges {
            if charRange.location + charRange.length <= uiView.textStorage.length {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
                let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: uiView.textContainer)
                boundsMap[verseId] = rect.maxY
            }
        }
        if !boundsMap.isEmpty {
            let bounds = boundsMap
            DispatchQueue.main.async {
                onVerseBoundsCalculated?(bounds)
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
}
#else
struct JustifiedText: View {
    var attributedText: String
    var theme: String
    
    var body: some View {
        Text(attributedText)
            .font(Theme.quranFont(type: quranFontType, size: 24))
            .multilineTextAlignment(.trailing)
            .environment(\.layoutDirection, .rightToLeft)
    }
}
#endif



#if os(iOS) && !SKIP
struct DisableScrollsToTop: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView() {
                scrollView.scrollsToTop = false
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension UIView {
    fileprivate func enclosingScrollView() -> UIScrollView? {
        var current: UIResponder? = self
        while let c = current {
            if let scrollView = c as? UIScrollView {
                return scrollView
            }
            current = c.next
        }
        return nil
    }
}
#endif
