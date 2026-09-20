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
}

struct QuranView: View {
    @ObservedObject var viewModel: QuranViewModel

    @Environment(\.modelContext) var modelContext
    @Query var allDailyRecords: [DailyRecord]
    @Query var allSettings: [UserSettings]
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("globalReadVerseIds") var globalReadVerseIdsData: Data = Data()
    @AppStorage("lastReadVerseId") var lastReadVerseId: String = ""
    @AppStorage("quranTheme") var quranTheme: String = "system"
    @AppStorage("quranFontType") var quranFontType: String = "uthmanic"
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @StateObject var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    private var globalReadVerseIds: Set<String> {
        get {
            guard let array = try? JSONDecoder().decode([String].self, from: globalReadVerseIdsData) else { return [] }
            return Set(array)
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(Array(newValue)) {
                globalReadVerseIdsData = data
            }
        }
    }
    
    @State private var hasDoneInitialRestore: Bool = false
    @State private var showKhatmCelebrationAnimation: Bool = false
    
    private var lastReadPage: Int {
        let saved = UserDefaults.standard.integer(forKey: "quranLastReadPage")
        return saved > 0 ? saved : 1
    }
    
    private var lastReadTarget: (page: Int, verseId: String?) {
        let lastPage = lastReadPage
        let lastVerse = lastReadVerseId
        if !lastVerse.isEmpty {
            return (lastPage, lastVerse)
        }
        return (lastPage, nil)
    }

    private var firstUnreadTarget: (page: Int, verseId: String?) {
        if let unreadVerse = QuranAPIService.shared.findFirstUnreadVerse(globalReadVerseIds: globalReadVerseIds) {
            return (unreadVerse.pageNumber, unreadVerse.id)
        }
        let lastVerse = lastReadVerseId
        if !lastVerse.isEmpty {
            if let currentVerse = QuranAPIService.shared.getVerse(id: lastVerse) {
                return (currentVerse.pageNumber, currentVerse.id)
            }
        }
        return (lastReadPage, nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme).ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        #if os(iOS) && !SKIP
                        DisableScrollsToTop().frame(width: 0, height: 0)
                        #endif
                        LazyVStack(spacing: 0) {
                            ForEach(1...604, id: \.self) { pageNum in
                                QuranPageView(
                                    pageNumber: pageNum,
                                    fontSize: viewModel.fontSize,
                                    globalReadVerseIds: globalReadVerseIds,
                                    language: settings.language,
                                    useTajweedHarakat: settings.useTajweedHarakat,
                                    onMarkVersesAsRead: { verses in
                                        markVersesAsRead(verses)
                                    },
                                    onPageRead: { pageNum in
                                        markPageAsReadToday(pageNum)
                                    },
                                    onTopVisible: { surahName in
                                        if viewModel.navTitle != surahName {
                                            viewModel.navTitle = surahName
                                        }
                                    },
                                    onCompleteKhatm: {
                                        completeKhatm(proxy: proxy)
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
                    .onAppear {
                        if !hasDoneInitialRestore {
                            hasDoneInitialRestore = true
                            restorePosition(proxy: proxy)
                        } else {
                            UserDefaults.standard.set(true, forKey: "quranHasRestoredInitialPosition")
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("QuranTabRetapped"))) { _ in
                        scrollToUnreadTarget(proxy: proxy)
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
            }
            .navigationTitle(viewModel.navTitle.isEmpty ? L10n.tr("tab_quran", settings.language) : viewModel.navTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbarBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }
    
    private func restorePosition(proxy: ScrollViewProxy) {
        UserDefaults.standard.set(false, forKey: "quranHasRestoredInitialPosition")
        let target = lastReadTarget
        let targetPage = target.page
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo(targetPage, anchor: .top)
            if let vId = target.verseId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(vId, anchor: UnitPoint(x: 0.5, y: 0.15))
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UserDefaults.standard.set(true, forKey: "quranHasRestoredInitialPosition")
            }
        }
    }

    private func scrollToUnreadTarget(proxy: ScrollViewProxy) {
        UserDefaults.standard.set(false, forKey: "quranHasRestoredInitialPosition")
        let target = firstUnreadTarget
        let targetPage = target.page
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo(targetPage, anchor: .top)
            if let vId = target.verseId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(vId, anchor: UnitPoint(x: 0.5, y: 0.15))
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UserDefaults.standard.set(true, forKey: "quranHasRestoredInitialPosition")
            }
        }
    }
    
    private func markVersesAsRead(_ verses: [Verse]) {
        var current = globalReadVerseIds
        var addedCount = 0
        var maxPageNumber = 0
        
        for verse in verses {
            if !current.contains(verse.id) {
                current.insert(verse.id)
                addedCount += 1
            }
            if verse.pageNumber > maxPageNumber {
                maxPageNumber = verse.pageNumber
            }
        }
        
        if maxPageNumber > 0 {
            let highest = UserDefaults.standard.integer(forKey: "quranHighestReadPage")
            if maxPageNumber > highest {
                UserDefaults.standard.set(maxPageNumber, forKey: "quranHighestReadPage")
            }
        }
        
        if addedCount > 0 {
            globalReadVerseIds = current
            
            // Tagesfortschritt erhöhen
            let record = todayRecord
            record.quranVersesRead += addedCount
            try? modelContext.save()
        }
    }
    
    private func markPageAsReadToday(_ page: Int) {
        let record = todayRecord
        let dateKey = record.dateString
        let userDefaultsKey = "quran_read_pages_\(dateKey)"
        
        var readPages = UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int] ?? []
        if !readPages.contains(page) {
            readPages.append(page)
            UserDefaults.standard.set(readPages, forKey: userDefaultsKey)
            
            record.quranPagesRead = readPages.count
            try? modelContext.save()
        }
    }
    
    private func completeKhatm(proxy: ScrollViewProxy) {
        let currentKhatm = UserDefaults.standard.integer(forKey: "quranKhatmCount")
        UserDefaults.standard.set(currentKhatm + 1, forKey: "quranKhatmCount")
        
        globalReadVerseIds = Set<String>()
        lastReadVerseId = ""
        UserDefaults.standard.set(1, forKey: "quranLastReadPage")
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showKhatmCelebrationAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo(1, anchor: .top)
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
    let globalReadVerseIds: Set<String>
    let language: String
    let useTajweedHarakat: Bool
    let onMarkVersesAsRead: ([Verse]) -> Void
    let onPageRead: (Int) -> Void
    var onTopVisible: ((String) -> Void)? = nil
    var onCompleteKhatm: (() -> Void)? = nil
    
    @AppStorage("lastReadVerseId") var lastReadVerseId: String = ""
    @AppStorage("quranTheme") var quranTheme: String = "system"
    @AppStorage("quranFontType") var quranFontType: String = "uthmanic"
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var verses: [Verse] = []
    @State var isLoading = false
    @State var hasError = false
    @State var hasTrackedPageRead = false
    @State var segmentHeights: [String: CGFloat] = [:]
    
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
            
            // Edler Seitenteiler am Ende jeder Seite
            pageDivider
            
            if pageNumber == 604 {
                khatmCompletionCard
            }
        }
        .onAppear {
            loadPage()
        }
        .onChange(of: pageNumber) { _, _ in
            verses = []
            hasTrackedPageRead = false
            segmentHeights = [:]
            loadPage()
        }
        .onChange(of: globalReadVerseIds) { _, _ in
            checkAllVersesRead()
        }
        .onChange(of: verses) { _, _ in
            checkAllVersesRead()
        }
    }
    
    private var pageContent: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                let minY = geo.frame(in: .global).minY
                Color.clear
                    .onChange(of: minY) { _, newValue in
                        if newValue > -300 && newValue < 400 {
                            if let firstSurah = verses.first?.surah {
                                DispatchQueue.main.async {
                                    onTopVisible?(QuranSurah.getName(firstSurah))
                                    if UserDefaults.standard.bool(forKey: "quranHasRestoredInitialPosition") {
                                        UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
                                        let currentHighest = UserDefaults.standard.integer(forKey: "quranHighestReadPage")
                                        if pageNumber > currentHighest {
                                            UserDefaults.standard.set(pageNumber, forKey: "quranHighestReadPage")
                                        }
                                    }
                                }
                            }
                        }
                    }
            }.frame(height: 0)
            
            // 1. Unsichtbare Tracking-Schicht im Hintergrund
            VStack(spacing: 0) {
                ForEach(surahSegments, id: \.id) { segment in
                    if let segmentHeight = segmentHeights[segment.id] {
                        let versesList = segment.verses
                        let totalLength = CGFloat(versesList.map { $0.arabic.count }.reduce(0, +))
                        
                        VStack(spacing: 0) {
                            ForEach(versesList, id: \.id) { verse in
                                let verseLength = CGFloat(verse.arabic.count)
                                let propHeight = totalLength > 0 ? (verseLength / totalLength) * segmentHeight : 0
                                
                                Color.clear
                                    .frame(height: propHeight)
                                    .id(verse.id)
                                    .background(
                                        GeometryReader { verseGeo in
                                            let minY = verseGeo.frame(in: .global).minY
                                            let maxY = verseGeo.frame(in: .global).maxY
                                            Color.clear
                                                .onChange(of: minY) { _, newValue in
                                                    // Wenn der Vers im aktiven oberen Lesebereich ist
                                                    if newValue < 150 && newValue > -50 {
                                                        if lastReadVerseId != verse.id {
                                                            DispatchQueue.main.async {
                                                                lastReadVerseId = verse.id
                                                                if UserDefaults.standard.bool(forKey: "quranHasRestoredInitialPosition") {
                                                                    UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                .onChange(of: maxY) { oldValue, newValue in
                                                    let delta = abs(newValue - oldValue)
                                                    // Nur bei normalem Lesetempo (kein schnelles Swipen/Runter-Scrollen) als gelesen markieren
                                                    if delta <= 30 && newValue < 120 {
                                                        if !globalReadVerseIds.contains(verse.id) && UserDefaults.standard.bool(forKey: "quranHasRestoredInitialPosition") {
                                                            let idx = versesList.firstIndex(where: { $0.id == verse.id }) ?? 0
                                                            let prefixVerses = Array(versesList[0...idx])
                                                            DispatchQueue.main.async {
                                                                onMarkVersesAsRead(prefixVerses)
                                                                if UserDefaults.standard.bool(forKey: "quranHasRestoredInitialPosition") {
                                                                    UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                        }
                                    )
                            }
                        }
                        .frame(height: segmentHeight)
                    } else {
                        Color.clear
                            .frame(height: 1)
                    }
                }
            }
            .opacity(0)
            
            // 2. Vordergrund-Schicht
            VStack(spacing: 0) {
                ForEach(surahSegments, id: \.id) { segment in
                    VStack(spacing: 0) {
                        // Surenheader rendern, falls die Sure auf dieser Seite neu beginnt (erster Vers ist Ayah 1)
                        if segment.verses.first?.ayah == 1 {
                            surahHeader(segment.surah)
                            
                            // Basmala rendern (außer bei Sure 1 und Sure 9)
                            if segment.surah != 1 && segment.surah != 9 {
                                basmalaView
                            }
                        }
                        
                        // Der Fließtext der Sure für diese Seite
                        Group {
                            #if os(iOS) && !SKIP
                            JustifiedText(attributedText: concatenatedString(for: segment.verses), theme: quranTheme)
                            #else
                            JustifiedText(attributedText: concatenatedString(arabicTexts: segment.verses.map { $0.arabic }, ayahNumbers: segment.verses.map { $0.ayah }), theme: quranTheme)
                            #endif
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .environment(\.layoutDirection, .rightToLeft)
                    }
                    .background(
                        GeometryReader { geo in
                            let h = geo.size.height
                            Color.clear
                                .onAppear {
                                    if segmentHeights[segment.id] != h {
                                        segmentHeights[segment.id] = h
                                    }
                                }
                                .onChange(of: h) { _, newValue in
                                    if segmentHeights[segment.id] != newValue {
                                        DispatchQueue.main.async {
                                            segmentHeights[segment.id] = newValue
                                        }
                                    }
                                }
                        }
                    )
                }
            }
        }
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
        .background(
            GeometryReader { geo in
                let minY = geo.frame(in: .global).minY
                Color.clear
                    .onChange(of: minY) { oldValue, newValue in
                        let delta = abs(newValue - oldValue)
                        if delta <= 30 && newValue < 100 && !verses.isEmpty && !hasTrackedPageRead && UserDefaults.standard.bool(forKey: "quranHasRestoredInitialPosition") {
                            DispatchQueue.main.async {
                                markAllVersesAsRead()
                            }
                        }
                    }
            }
        )
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
    private func concatenatedString(for versesList: [Verse]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = Theme.quranUIFont(type: quranFontType, size: fontSize)
        let numberFont = Theme.quranUIFont(type: quranFontType, size: fontSize * 0.85)
        
        for verse in versesList {
            let isRead = globalReadVerseIds.contains(verse.id)
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
        isLoading = true
        hasError = false
        Task {
            do {
                let fetched = try await QuranAPIService.shared.fetchPage(pageNumber: pageNumber)
                await MainActor.run {
                    self.verses = fetched
                    self.isLoading = false
                    
                    let allAlreadyRead = !fetched.isEmpty && fetched.allSatisfy { globalReadVerseIds.contains($0.id) }
                    if allAlreadyRead {
                        self.hasTrackedPageRead = true
                    }
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
    
    private func markAllVersesAsRead() {
        guard !verses.isEmpty else { return }
        let unread = verses.filter { !globalReadVerseIds.contains($0.id) }
        if !unread.isEmpty {
            onMarkVersesAsRead(unread)
            UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
        }
        if !hasTrackedPageRead {
            hasTrackedPageRead = true
            onPageRead(pageNumber)
            UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
        }
    }
    
    private func checkAllVersesRead() {
        guard !verses.isEmpty else { return }
        let allRead = verses.allSatisfy { globalReadVerseIds.contains($0.id) }
        if allRead && !hasTrackedPageRead {
            hasTrackedPageRead = true
            onPageRead(pageNumber)
            UserDefaults.standard.set(pageNumber, forKey: "quranLastReadPage")
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
    var theme: String
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
        if let lastOriginal = context.coordinator.lastOriginalText,
           lastOriginal.isEqual(to: attributedText),
           let lastModified = context.coordinator.lastModifiedText {
            if uiView.attributedText.string == lastModified.string {
                return
            }
        }
        
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
        } else if lastLineCharRange.location == 0 && lastLineCharRange.length > 0 {
            let mutableAttributed = NSMutableAttributedString(attributedString: attributedText)
            let centerParagraphStyle = NSMutableParagraphStyle()
            centerParagraphStyle.alignment = .center
            centerParagraphStyle.baseWritingDirection = .rightToLeft
            
            mutableAttributed.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: NSRange(location: 0, length: mutableAttributed.length))
            
            context.coordinator.lastModifiedText = mutableAttributed
            uiView.attributedText = mutableAttributed
        } else {
            context.coordinator.lastModifiedText = attributedText
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
