import SwiftUI
import SwiftData
import UIKit

struct QuranView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDailyRecords: [DailyRecord]
    @Query private var allSettings: [UserSettings]
    
    // Schriftgröße mit Pinch-to-Zoom, UserDefaults-persistent
    @State private var fontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 24)
    @State private var lastFontSize: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "quranFontSize") > 0
        ? UserDefaults.standard.double(forKey: "quranFontSize") : 24)
    
    @State private var navTitle: String = ""
    
    @AppStorage("globalReadVerseIds") private var globalReadVerseIdsData: Data = Data()
    @AppStorage("lastReadVerseId") private var lastReadVerseId: String = ""
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
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
    
    private var lastReadPage: Int {
        let saved = UserDefaults.standard.integer(forKey: "quranLastReadPage")
        return saved > 0 ? saved : 1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(1...604, id: \.self) { pageNum in
                                QuranPageView(
                                    pageNumber: pageNum,
                                    fontSize: fontSize,
                                    globalReadVerseIds: globalReadVerseIds,
                                    language: settings.language,
                                    onMarkVersesAsRead: { verses in
                                        markVersesAsRead(verses)
                                    },
                                    onPageRead: { pageNum in
                                        markPageAsReadToday(pageNum)
                                    },
                                    onTopVisible: { surahName in
                                        if navTitle != surahName {
                                            navTitle = surahName
                                        }
                                    }
                                )
                                .id(pageNum)
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
                    .onAppear {
                        let targetPage = lastReadPage
                        let targetVerse = lastReadVerseId
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(targetPage, anchor: .top)
                            
                            if !targetVerse.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        proxy.scrollTo(targetVerse, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(navTitle.isEmpty ? L10n.tr("tab_quran", settings.language) : navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func markVersesAsRead(_ verses: [Verse]) {
        var current = globalReadVerseIds
        var addedCount = 0
        for verse in verses {
            if !current.contains(verse.id) {
                current.insert(verse.id)
                addedCount += 1
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
    let onMarkVersesAsRead: ([Verse]) -> Void
    let onPageRead: (Int) -> Void
    var onTopVisible: ((String) -> Void)? = nil
    
    @AppStorage("lastReadVerseId") private var lastReadVerseId: String = ""
    
    @State private var verses: [Verse] = []
    @State private var isLoading = false
    @State private var hasError = false
    @State private var hasTrackedPageRead = false
    @State private var segmentHeights: [String: CGFloat] = [:]
    
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
        }
        .onAppear {
            loadPage()
        }
        .onChange(of: globalReadVerseIds, initial: true) { _, _ in
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
                    .onChange(of: minY, initial: true) { _, newValue in
                        if newValue > -300 && newValue < 400 {
                            if let firstSurah = verses.first?.surah {
                                DispatchQueue.main.async {
                                    onTopVisible?(QuranSurah.getName(firstSurah))
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
                                            Color.clear
                                                .onChange(of: minY, initial: true) { _, newValue in
                                                    // Wenn der Vers im aktiven oberen Lesebereich ist
                                                    if newValue < 150 && newValue > -50 {
                                                        if lastReadVerseId != verse.id {
                                                            lastReadVerseId = verse.id
                                                        }
                                                    }
                                                    
                                                    // Wenn der Vers oben aus der Bildfläche scrollt -> als gelesen markieren
                                                    if newValue < 100 {
                                                        if !globalReadVerseIds.contains(verse.id) {
                                                            onMarkVersesAsRead([verse])
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
                        JustifiedText(attributedText: concatenatedString(for: segment.verses))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                    }
                    .background(
                        GeometryReader { geo in
                            let h = geo.size.height
                            Color.clear
                                .onAppear {
                                    segmentHeights[segment.id] = h
                                }
                                .onChange(of: h) { _, newValue in
                                    segmentHeights[segment.id] = newValue
                                }
                        }
                    )
                }
            }
        }
    }
    
    private var pageDivider: some View {
        HStack(spacing: 16) {
            VStack { Divider().background(Color.gray.opacity(0.2)) }
            Text("\(pageNumber)")
                .font(.system(.caption2, design: .serif))
                .foregroundColor(.gray.opacity(0.6))
            VStack { Divider().background(Color.gray.opacity(0.2)) }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
        .background(
            GeometryReader { geo in
                let minY = geo.frame(in: .global).minY
                Color.clear
                    .onChange(of: minY, initial: true) { _, newValue in
                        if newValue < 100 && !verses.isEmpty && !hasTrackedPageRead {
                            markAllVersesAsRead()
                        }
                    }
            }
        )
    }
    
    private func surahHeader(_ surah: Int) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text(QuranSurah.getName(surah))
                    .font(.custom("Geeza Pro", size: fontSize * 0.75).bold())
                    .foregroundColor(.gray.opacity(0.7))
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
            .font(.custom("Geeza Pro", size: fontSize * 0.85))
            .foregroundColor(.primary.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar"))
    }
    
    private func concatenatedString(for versesList: [Verse]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = UIFont(name: "Geeza Pro", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        
        for verse in versesList {
            let isRead = globalReadVerseIds.contains(verse.id)
            let color = isRead ? UIColor.gray : UIColor.label
            
            let text = "\(verse.arabic) \u{FD3F}\(arabicNumber(verse.ayah))\u{FD3E} "
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let verseString = NSAttributedString(string: text, attributes: attributes)
            result.append(verseString)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 16
        paragraphStyle.baseWritingDirection = .rightToLeft
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        
        return result
    }
    
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

struct JustifiedText: UIViewRepresentable {
    var attributedText: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.textAlignment = .justified
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
}
