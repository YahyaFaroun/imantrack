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
    
    @State private var startPage: Int? = nil
    @State private var showKhatmCelebrationAnimation: Bool = false
    @State private var showGapNoticeBanner: Bool = false
    @State private var gapVerseTarget: Verse? = nil
    @State private var showKhatmConfirmAlert: Bool = false
    @State private var showManualSetPositionSheet: Bool = false

    @State private var minAllowedOffsetY: CGFloat = 0
    @State private var hasRestoredInitialPosition: Bool = false
    @State private var isUserScrolling: Bool = false
    @State private var scrollSessionID: UUID = UUID()
    @State private var uiScrollView: UIScrollView? = nil
    @State private var renderedPageMinY: [Int: CGFloat] = [:]
    @State private var renderedPageTopBounds: [Int: [String: CGFloat]] = [:]
    @State private var renderedPageBounds: [Int: [String: CGFloat]] = [:]
    @State private var lastObservedResetToken: UUID? = nil

    // MARK: - Zoom-Konstanten
    static let zoomStepSize: CGFloat = 1.0                  // 1 pt pro Stufe
    static let zoomStepMinInterval: TimeInterval = 0.15     // Höchstens 1 Stufe pro 0.15s
    static let zoomMagnificationThreshold: CGFloat = 0.04   // ~4% Spreizungsänderung für eine Stufe
    static let minFontSize: CGFloat = 22.0                  // Minimale Schriftgröße
    static let maxFontSize: CGFloat = 42.0                  // Maximale Schriftgröße

    @State private var isZooming: Bool = false
    @State private var isZoomLayoutPending: Bool = false
    @State private var lastZoomStepTime: Date = .distantPast
    @State private var referenceMagnification: CGFloat = 1.0
    @State private var zoomLayoutResetTask: Task<Void, Never>? = nil

    private var isZoomActive: Bool {
        isZooming || isZoomLayoutPending
    }

    private var isCurrentlyUserScrolling: Bool {
        if isUserScrolling { return true }
        #if os(iOS) && !SKIP
        if let sv = uiScrollView, sv.isDragging || sv.isDecelerating {
            return true
        }
        #endif
        return false
    }



    var body: some View {
        let (bodyState, bodyT0) = QuranPerf.shared.begin("2a_QuranView_body")
        defer {
            QuranPerf.shared.end("2a_QuranView_body", state: bodyState, t0: bodyT0)
        }
        return NavigationStack {
            ZStack {
                Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme).ignoresSafeArea()
                
                if !quranAPIService.isLoaded || startPage == nil {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Theme.accent)
                        Text(L10n.tr("quran_loading", settings.language))
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
                    ZStack {
                        if !hasRestoredInitialPosition {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(Theme.accent)
                                Text(L10n.tr("quran_position_loading", settings.language))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        ScrollView {
                            ZStack(alignment: .top) {
                                #if os(iOS) && !SKIP
                                DisableScrollsToTop().frame(width: 0, height: 0)
                                QuranScrollViewTracker(
                                    minAllowedOffsetY: $minAllowedOffsetY,
                                    isUserScrolling: $isUserScrolling,
                                    onScrollViewFound: { sv in
                                        self.uiScrollView = sv
                                        if !hasRestoredInitialPosition, let s = startPage, self.renderedPageTopBounds[s] != nil {
                                            restoreInitialPosition()
                                        }
                                    },
                                    onScrollEnded: {
                                        self.saveCurrentBookmark()
                                        self.progressStore.flushPendingChanges(modelContext: modelContext)
                                    }
                                )
                                .frame(width: 0, height: 0)
                                #endif
                                LazyVStack(spacing: 0) {
                                    ForEach(start...604, id: \.self) { pageNum in
                                        pageItem(for: pageNum, start: start)
                                    }
                                }
                            }
                        }
                        .id(scrollSessionID)
                        #if os(iOS)
                        .onScrollPhaseChange { oldPhase, newPhase in
                            let isUser = (newPhase == .interacting || newPhase == .decelerating)
                            if self.isUserScrolling != isUser {
                                self.isUserScrolling = isUser
                                print("[QURAN_SCROLL] onScrollPhaseChange: \(oldPhase) -> \(newPhase), isUserScrolling=\(isUser)")
                            }
                            if (oldPhase == .interacting || oldPhase == .decelerating) && newPhase == .idle {
                                self.saveCurrentBookmark()
                                self.progressStore.flushPendingChanges(modelContext: modelContext)
                            }
                        }
                        #endif
                        .opacity(hasRestoredInitialPosition ? 1.0 : 0.0)
                    }
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                handleZoomGestureChange(value: value)
                            }
                            .onEnded { _ in
                                handleZoomGestureEnded()
                            }
                    )
                    
                    gapNoticeOverlay
                }

                khatmCelebrationOverlay
                restoreNoticeOverlay

            }
            .navigationTitle(viewModel.navTitle.isEmpty ? L10n.tr("tab_quran", settings.language) : viewModel.navTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                quranToolbarContent
            }
            #endif
            .alert(L10n.tr("khatm_confirm_title", settings.language), isPresented: $showKhatmConfirmAlert) {
                Button(L10n.tr("khatm_confirm_action", settings.language), role: .destructive) {
                    triggerKhatmCompletion()
                }
                Button(L10n.tr("cancel", settings.language), role: .cancel) {}
            } message: {
                Text(L10n.tr("khatm_confirm_msg", settings.language))
            }
            .sheet(isPresented: $showManualSetPositionSheet) {
                SetQuranPositionSheet(language: settings.language)
            }
        }
        .onAppear {
            let storedUD = UserDefaults.standard.integer(forKey: "quranReadFrontier")
            let target = quranAPIService.getVerseAtIndex(progressStore.readFrontier)
            let targetStr = target != nil ? "\(target!.id) (#\(progressStore.readFrontier))" : "nil"
            let currentOffset = uiScrollView?.contentOffset.y ?? 0
            let bmStr = progressStore.bookmark != nil ? "Vers #\(progressStore.bookmark!.verseIndex) d:\(Int(progressStore.bookmark!.delta))pt" : "keines"
            print("[QURAN_STATE] onAppear: Speicher=\(progressStore.readFrontier), UserDefaults=\(storedUD), Zielvers=\(targetStr), startPage=\(startPage ?? -1), offset=\(currentOffset), Lesezeichen=\(bmStr)")
            
            if lastObservedResetToken == nil {
                lastObservedResetToken = progressStore.khatmResetToken
            } else if lastObservedResetToken != progressStore.khatmResetToken {
                lastObservedResetToken = progressStore.khatmResetToken
                resetReaderToStart()
                return
            }
            
            // Tab-Wechsel: NICHTS neu aufbauen! View bleibt exakt wie sie war.
            if !hasRestoredInitialPosition {
                initStartPageIfNeeded()
            }
        }
        .onDisappear {
            self.isUserScrolling = false
            saveCurrentBookmark()
            progressStore.flushPendingChanges(modelContext: modelContext)
            let storedUD = UserDefaults.standard.integer(forKey: "quranReadFrontier")
            let target = quranAPIService.getVerseAtIndex(progressStore.readFrontier)
            let targetStr = target != nil ? "\(target!.id) (#\(progressStore.readFrontier))" : "nil"
            let currentOffset = uiScrollView?.contentOffset.y ?? 0
            let bmStr = progressStore.bookmark != nil ? "Vers #\(progressStore.bookmark!.verseIndex) d:\(Int(progressStore.bookmark!.delta))pt" : "keines"
            print("[QURAN_STATE] onDisappear: Speicher=\(progressStore.readFrontier), UserDefaults=\(storedUD), Zielvers=\(targetStr), offset=\(currentOffset), Lesezeichen=\(bmStr)")
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if oldTab == 3 && newTab != 3 {
                saveCurrentBookmark()
                progressStore.flushPendingChanges(modelContext: modelContext)
            }
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            saveCurrentBookmark()
            progressStore.flushPendingChanges(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            saveCurrentBookmark()
            progressStore.flushPendingChanges(modelContext: modelContext)
        }
        #endif
        .onChange(of: progressStore.khatmResetToken) { _, newToken in
            if self.lastObservedResetToken != newToken {
                self.lastObservedResetToken = newToken
                resetReaderToStart()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ResetQuranStartPage"))) { _ in
            self.lastObservedResetToken = progressStore.khatmResetToken
            resetReaderToStart()
        }
    }
    
    private func resetReaderToStart() {
        print("[QURAN_STATE] resetReaderToStart: Setze Quran-Reader komplett auf S.1 / Al-Fatiha zurück")
        self.startPage = nil
        self.hasRestoredInitialPosition = false
        self.renderedPageMinY.removeAll()
        self.renderedPageTopBounds.removeAll()
        self.renderedPageBounds.removeAll()
        self.minAllowedOffsetY = 0
        self.isUserScrolling = false
        initStartPageIfNeeded(force: true)
    }
    
    private func saveCurrentBookmark() {
        guard hasRestoredInitialPosition else { return }
        let frontierIndex = progressStore.readFrontier
        guard let frontierVerse = quranAPIService.getVerseAtIndex(frontierIndex) else { return }
        let frontierPage = frontierVerse.pageNumber
        
        // Ist frontierPage gerade nicht gerendert: NICHT speichern, altes Lesezeichen behalten
        guard let pageMinY = renderedPageMinY[frontierPage],
              let topBounds = renderedPageTopBounds[frontierPage],
              let frontierTop = topBounds[frontierVerse.id] else {
            print("[QURAN_RESUME] Speichern übersprungen: frontierPage S.\(frontierPage) gerade nicht gerendert oder Bounds fehlen. Altes Lesezeichen behalten.")
            return
        }
        
        // Oberkante des sichtbaren Bereichs relativ zur Oberkante von frontierPage:
        // pageMinY ist der Abstand der Seitenoberkante von der sichtbaren Oberkante (im Scroll-Koordinatenraum)
        let sichtbareOberkanteInSeite = -pageMinY
        let delta = sichtbareOberkanteInSeite - frontierTop
        
        let bookmark = QuranBookmark(
            verseIndex: frontierIndex,
            delta: delta,
            fontSize: viewModel.fontSize
        )
        print("[QURAN_RESUME] Speichern: readFrontier=\(frontierIndex) (\(frontierVerse.surah):\(frontierVerse.ayah) auf S.\(frontierPage)), frontierTop=\(String(format: "%.1f", frontierTop))pt, sichtbareOberkante=\(String(format: "%.1f", sichtbareOberkanteInSeite))pt, delta=\(String(format: "%.1f", delta))pt (fontSize: \(bookmark.fontSize))")
        progressStore.saveBookmark(bookmark)

    }
    
    private func initStartPageIfNeeded(force: Bool = false) {
        guard quranAPIService.isLoaded else { return }
        let frontierIndex = progressStore.readFrontier
        let frontierVerse = quranAPIService.getVerseAtIndex(frontierIndex)
        let targetPage = frontierVerse?.pageNumber ?? 1
        
        if force || startPage == nil || startPage != targetPage {
            let pageChanged = (startPage != targetPage)
            self.startPage = targetPage
            if pageChanged || force {
                self.scrollSessionID = UUID()
                self.hasRestoredInitialPosition = false
                self.minAllowedOffsetY = 0
                self.isUserScrolling = false
                self.renderedPageMinY.removeAll()
                self.renderedPageTopBounds.removeAll()
                self.renderedPageBounds.removeAll()
                let isFirstVerse = (frontierIndex == 0) || (quranAPIService.getVerseAtIndex(frontierIndex - 1)?.pageNumber != targetPage)
                let topInset = (self.uiScrollView?.adjustedContentInset.top ?? 0) > 0 ? (self.uiScrollView?.adjustedContentInset.top ?? 0) : (self.uiScrollView?.safeAreaInsets.top ?? 0)
                let resetOffset = isFirstVerse ? -topInset : 0
                self.uiScrollView?.setContentOffset(CGPoint(x: 0, y: resetOffset), animated: false)
            }
            let bmStr = progressStore.bookmark != nil ? "Vers #\(progressStore.bookmark!.verseIndex) d:\(Int(progressStore.bookmark!.delta))pt" : "keines"
            print("[QURAN_VIEW] Session startPage festgelegt auf S.\(targetPage) (Lesefront: Vers #\(frontierIndex), Lesezeichen: \(bmStr), sessionID: \(self.scrollSessionID))")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if !self.hasRestoredInitialPosition {
                self.restoreInitialPosition(forceFallback: true)
            }
        }
    }
    
    private func restoreInitialPosition(forceFallback: Bool = false) {
        guard !hasRestoredInitialPosition, startPage != nil else { return }
        
        let frontierIndex = progressStore.readFrontier
        guard let frontierVerse = quranAPIService.getVerseAtIndex(frontierIndex) else { return }
        let frontierPage = frontierVerse.pageNumber
        let isFirstVerseOfPage = (frontierIndex == 0) || (quranAPIService.getVerseAtIndex(frontierIndex - 1)?.pageNumber != frontierPage)
        
        // Wir benötigen die Bounds der Startseite (= frontierPage)
        guard let topBounds = renderedPageTopBounds[frontierPage],
              let bounds = renderedPageBounds[frontierPage] else {
            if forceFallback {
                let sv = self.uiScrollView
                let topInset = (sv?.adjustedContentInset.top ?? 0) > 0 ? (sv?.adjustedContentInset.top ?? 0) : (sv?.safeAreaInsets.top ?? 0)
                let fallbackTarget = isFirstVerseOfPage ? -topInset : 0
                performScrollPositioning(
                    targetOffset: fallbackTarget,
                    rawTarget: fallbackTarget,
                    frontierTop: 0,
                    frontierPage: frontierPage,
                    isFirstVerseOfPage: isFirstVerseOfPage,
                    branch: isFirstVerseOfPage ? "Seitenanfang" : "Fallback"
                )
            }
            return
        }
        
        let sv = self.uiScrollView
        let topInset = (sv?.adjustedContentInset.top ?? 0) > 0 ? (sv?.adjustedContentInset.top ?? 0) : (sv?.safeAreaInsets.top ?? 0)
        let frontierTop = topBounds[frontierVerse.id] ?? 0
        let frontierBottom = bounds[frontierVerse.id] ?? frontierTop
        let fontLineHeight = Theme.quranUIFont(type: quranFontType, size: viewModel.fontSize).lineHeight
        
        let targetOffset: CGFloat
        let branch: String
        if isFirstVerseOfPage {
            targetOffset = -topInset
            branch = "Seitenanfang"
            let bmDelta = progressStore.bookmark?.delta ?? 0
            print("[QURAN_RESUME] Erster Vers auf S.\(frontierPage) (Vers #\(frontierIndex) \(frontierVerse.surah):\(frontierVerse.ayah)): Starte am Seitenanfang (targetOffset=\(String(format: "%.1f", targetOffset))pt, topInset=\(String(format: "%.1f", topInset))pt, gespeichertes delta=\(String(format: "%.1f", bmDelta))pt ignoriert, Sperre bei \(String(format: "%.1f", targetOffset))pt).")
        } else if let bm = progressStore.bookmark, bm.verseIndex == frontierIndex {
            let scaleFactor: CGFloat = (bm.fontSize > 0) ? (viewModel.fontSize / bm.fontSize) : 1.0
            let candidate = frontierTop + (bm.delta * scaleFactor)
            let lowerBound = max(0, frontierTop - fontLineHeight)
            let upperBound = max(lowerBound, frontierBottom)
            targetOffset = min(max(candidate, lowerBound), upperBound)
            branch = "delta"
        } else {
            targetOffset = frontierTop
            branch = "Fallback"
        }
        
        performScrollPositioning(
            targetOffset: targetOffset,
            rawTarget: targetOffset,
            frontierTop: frontierTop,
            frontierPage: frontierPage,
            isFirstVerseOfPage: isFirstVerseOfPage,
            branch: branch
        )
    }
    
    private func performScrollPositioning(
        targetOffset: CGFloat,
        rawTarget: CGFloat,
        frontierTop: CGFloat,
        frontierPage: Int,
        isFirstVerseOfPage: Bool,
        branch: String
    ) {
        guard !hasRestoredInitialPosition, let sv = self.uiScrollView, let start = startPage else { return }
        
        // Spezialfall: 1. Vers der Seite -> IMMER am natürlichen Seitenanfang (unter Nav-Bar) starten
        if isFirstVerseOfPage {
            let topInset = sv.adjustedContentInset.top > 0 ? sv.adjustedContentInset.top : sv.safeAreaInsets.top
            let startOffset = -topInset
            sv.setContentOffset(CGPoint(x: 0, y: startOffset), animated: false)
            
            DispatchQueue.main.async {
                guard !self.hasRestoredInitialPosition else { return }
                let currentTopInset = sv.adjustedContentInset.top > 0 ? sv.adjustedContentInset.top : sv.safeAreaInsets.top
                let finalTopOffset = -currentTopInset
                sv.setContentOffset(CGPoint(x: 0, y: finalTopOffset), animated: false)
                self.minAllowedOffsetY = finalTopOffset
                self.hasRestoredInitialPosition = true
                
                print("[QURAN_RESUME] Wiederherstellung (Seitenanfang S.\(frontierPage)): Inset=\(String(format: "%.1f", currentTopInset))pt, Offset=\(String(format: "%.1f", finalTopOffset))pt, minAllowedOffsetY=\(String(format: "%.1f", finalTopOffset))pt")

            }
            return
        }
        
        // 1. Positionieren
        sv.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: false)
        
        // 2. EINMAL prüfen im nächsten Runloop-Tick: Liegt die Oberkante des sichtbaren Bereichs
        // (gemessen wie beim Speichern: sichtbareOberkanteInSeite = -pageMinY) tatsächlich auf Zielposition?
        DispatchQueue.main.async {
            guard !self.hasRestoredInitialPosition else { return }
            
            let measuredPosBefore: CGFloat
            if let pMinY = self.renderedPageMinY[start] {
                measuredPosBefore = -pMinY
            } else {
                measuredPosBefore = sv.contentOffset.y
            }
            
            var finalOffset = sv.contentOffset.y
            let discrepancy = rawTarget - measuredPosBefore
            
            if abs(discrepancy) > 1.0 {
                // Bei Abweichung > 1 pt einmal ohne Animation korrigieren
                let corrected = max(0, sv.contentOffset.y + discrepancy)
                sv.setContentOffset(CGPoint(x: 0, y: corrected), animated: false)
                finalOffset = corrected
            }
            
            let measuredPosAfter = (self.renderedPageMinY[start] != nil) ? (-self.renderedPageMinY[start]!) : finalOffset
            
            // 3. Hochscroll-Sperre startet an der finalen Position
            self.minAllowedOffsetY = finalOffset
            self.hasRestoredInitialPosition = true
            
            // 4. Log [QURAN_RESUME]
            print("[QURAN_RESUME] Wiederherstellung: Ziel=\(String(format: "%.1f", rawTarget))pt, vor Korrektur=\(String(format: "%.1f", measuredPosBefore))pt, nach Korrektur=\(String(format: "%.1f", measuredPosAfter))pt, minAllowedOffsetY=\(String(format: "%.1f", finalOffset))pt")

        }
    }
    
    private func markVersesAsRead(_ verses: [Verse], maxVerseMaxYInPage: CGFloat? = nil) {
        guard hasRestoredInitialPosition else {
            print("[QURAN_GUARD] advance unterdrückt in markVersesAsRead: Startpositionierung noch nicht abgeschlossen")
            return
        }
        guard !isZoomActive else {
            print("[QURAN_ZOOM] advance unterdrückt in markVersesAsRead: Zoom/Layout aktiv")
            return
        }
        guard isCurrentlyUserScrolling else {
            print("[QURAN_GUARD] advance unterdrückt in markVersesAsRead: nicht durch Nutzer-Scrollen ausgelöst")
            return
        }
        guard let maxVerse = verses.max(by: { 
            (quranAPIService.getVerseIndex(id: $0.id) ?? -1) < (quranAPIService.getVerseIndex(id: $1.id) ?? -1) 
        }) else { return }
        
        if let maxIdx = quranAPIService.getVerseIndex(id: maxVerse.id) {
            progressStore.advance(toIndex: maxIdx + 1, modelContext: modelContext, date: solarManager.currentTrackingDate)
            
            let currentOffset = uiScrollView?.contentOffset.y ?? 0
            if currentOffset > self.minAllowedOffsetY {
                let (minYState, minYt0) = QuranPerf.shared.begin("4_update_minAllowedOffsetY")
                self.minAllowedOffsetY = currentOffset
                QuranPerf.shared.end("4_update_minAllowedOffsetY", state: minYState, t0: minYt0, extra: "\(String(format: "%.1f", currentOffset))pt")
            }
            
            if maxIdx + 1 >= 6236 {
                triggerKhatmCompletion()
            }
        }
    }
    
    // MARK: - Zoom Gesten-Steuerung
    private func handleZoomGestureChange(value: CGFloat) {
        if !isZooming {
            isZooming = true
            isZoomLayoutPending = true
            referenceMagnification = value
            zoomLayoutResetTask?.cancel()
        }
        
        let delta = value - referenceMagnification
        let now = Date()
        guard now.timeIntervalSince(lastZoomStepTime) >= QuranView.zoomStepMinInterval else {
            return
        }
        
        var step: CGFloat = 0
        if delta >= QuranView.zoomMagnificationThreshold {
            step = QuranView.zoomStepSize
        } else if delta <= -QuranView.zoomMagnificationThreshold {
            step = -QuranView.zoomStepSize
        }
        
        guard step != 0 else { return }
        
        let oldSize = viewModel.fontSize
        let targetSize = min(max(oldSize + step, QuranView.minFontSize), QuranView.maxFontSize)
        
        guard targetSize != oldSize else {
            referenceMagnification = value
            return
        }
        
        applyZoomStep(from: oldSize, to: targetSize)
        referenceMagnification = value
        lastZoomStepTime = now
    }
    
    private func applyZoomStep(from oldSize: CGFloat, to targetSize: CGFloat) {
        let currentOffset = uiScrollView?.contentOffset.y ?? 0
        let scaleRatio = targetSize / oldSize
        let newOffset = max(0, currentOffset * scaleRatio)
        
        // 1. Hochscroll-Sperre proportional skalieren
        self.minAllowedOffsetY = max(0, self.minAllowedOffsetY * scaleRatio)
        
        // 2. Schriftgröße aktualisieren
        viewModel.fontSize = targetSize
        viewModel.lastFontSize = targetSize
        
        // 3. Scroll-Offset so anpassen, dass dieselbe Textstelle oben bleibt
        uiScrollView?.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
        DispatchQueue.main.async {
            self.uiScrollView?.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
        }
        
        print("[QURAN_ZOOM] Stufe: \(String(format: "%.1f", oldSize))pt -> \(String(format: "%.1f", targetSize))pt (advance blockiert: true, Offset: \(String(format: "%.1f", currentOffset))pt -> \(String(format: "%.1f", newOffset))pt, minAllowedOffsetY: \(String(format: "%.1f", self.minAllowedOffsetY))pt)")
    }
    
    private func handleZoomGestureEnded() {
        isZooming = false
        referenceMagnification = 1.0
        UserDefaults.standard.set(Double(viewModel.fontSize), forKey: "quranFontSize")
        
        zoomLayoutResetTask?.cancel()
        zoomLayoutResetTask = Task { @MainActor in
            // 0.3s Puffer bis TextKit & SwiftUI Layout komplett abgeschlossen haben
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self.isZoomLayoutPending = false
            self.saveCurrentBookmark()
            print("[QURAN_ZOOM] Zoom-Layout abgeschlossen, advance wieder freigegeben. Lesezeichen aktualisiert (fontSize: \(viewModel.fontSize)).")
        }
    }
    
    // MARK: - Page Scroll & Bounds Handlers
    private func handlePageBoundsCalculated(pageNum: Int, boundsMap: [String: CGFloat], topBoundsMap: [String: CGFloat], start: Int) {
        self.renderedPageBounds[pageNum] = boundsMap
        self.renderedPageTopBounds[pageNum] = topBoundsMap
        if pageNum == start && !hasRestoredInitialPosition {
            restoreInitialPosition()
        }
    }
    
    private func handlePageScrollGeometry(pNum: Int, minY: CGFloat, start: Int) {
        self.renderedPageMinY[pNum] = minY
        let isStart = (pNum == start)
        let needsRestore = !hasRestoredInitialPosition
        let hasBounds = (self.renderedPageTopBounds[pNum] != nil)
        if isStart && needsRestore && hasBounds {
            restoreInitialPosition()
        }
    }
    
    private func handlePageDisappeared(pNum: Int) {
        self.renderedPageMinY.removeValue(forKey: pNum)
        self.renderedPageTopBounds.removeValue(forKey: pNum)
        self.renderedPageBounds.removeValue(forKey: pNum)
    }
    
    private func handleTopVisible(_ surahName: String) {
        if viewModel.navTitle != surahName {
            viewModel.navTitle = surahName
        }
    }
    
    @ViewBuilder
    private func pageItem(for pageNum: Int, start: Int) -> some View {
        QuranPageView(
            pageNumber: pageNum,
            fontSize: viewModel.fontSize,
            readFrontier: progressStore.readFrontier,
            isUserScrolling: isCurrentlyUserScrolling,
            hasRestoredInitialPosition: hasRestoredInitialPosition,
            isZoomActive: isZoomActive,
            language: settings.language,
            useTajweedHarakat: settings.useTajweedHarakat,
            onPageBoundsCalculated: { boundsMap, topBoundsMap in
                handlePageBoundsCalculated(pageNum: pageNum, boundsMap: boundsMap, topBoundsMap: topBoundsMap, start: start)
            },
            onPageScrollGeometryChanged: { pNum, minY in
                handlePageScrollGeometry(pNum: pNum, minY: minY, start: start)
            },
            onPageDisappeared: { pNum in
                handlePageDisappeared(pNum: pNum)
            },
            onMarkVersesAsRead: { verses, maxVerseMaxY in
                markVersesAsRead(verses, maxVerseMaxYInPage: maxVerseMaxY)
            },
            onTopVisible: { surahName in
                handleTopVisible(surahName)
            },
            onCompleteKhatm: {
                completeKhatm()
            },
            onPageScrollUpdate: { _, _ in }
        )
        .id(pageNum)
    }
    
    // MARK: - Overlays
    @ViewBuilder
    private var gapNoticeOverlay: some View {
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

    @ViewBuilder
    private var khatmCelebrationOverlay: some View {
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

    @ViewBuilder
    private var restoreNoticeOverlay: some View {
        if progressStore.showRestoreNotice, let info = progressStore.restoredLocationInfo {
            ZStack {
                Color.black.opacity(0.65).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("📖")
                        .font(.system(size: 60))
                    
                    Text(L10n.tr("quran_restore_notice_title", settings.language))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(String(format: L10n.tr("quran_restore_notice_body", settings.language), QuranSurah.getName(info.surah), info.ayah, info.page))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                progressStore.dismissRestoreNotice()
                            }
                        }) {
                            Text(L10n.tr("quran_restore_ok", settings.language))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.islamicGreen)
                                .cornerRadius(14)
                        }
                        
                        Button(action: {
                            progressStore.dismissRestoreNotice()
                            showManualSetPositionSheet = true
                        }) {
                            Text(L10n.tr("quran_set_position", settings.language))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(14)
                        }
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
            .zIndex(110)
        }
    }
    
    private func triggerKhatmCompletion() {
        guard !showKhatmCelebrationAnimation else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showKhatmCelebrationAnimation = true
        }
        progressStore.resetKhatm(modelContext: modelContext)
    }
    
    #if os(iOS)
    @ToolbarContentBuilder
    private var quranToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if progressStore.khatmCount > 0 {
                khatmBadgeView
            }
        }
    }
    
    private var khatmBadgeView: some View {
        let label = "\(progressStore.khatmCount) " + L10n.tr("quran_completed_khatmat", settings.language)
        return HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13))
                .foregroundColor(Theme.islamicGreen)
            Text("\(progressStore.khatmCount)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.islamicGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.islamicGreen.opacity(0.12))
        .cornerRadius(12)
        .accessibilityLabel(label)
    }
    #endif

    private func completeKhatm() {
        if progressStore.readFrontier < 6236 {
            if let unreadVerse = quranAPIService.getVerseAtIndex(progressStore.readFrontier) {
                gapVerseTarget = unreadVerse
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showGapNoticeBanner = true
                }
            }
        } else {
            showKhatmConfirmAlert = true
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
    let isUserScrolling: Bool
    let hasRestoredInitialPosition: Bool
    let isZoomActive: Bool
    let language: String
    let useTajweedHarakat: Bool
    var onPageBoundsCalculated: (([String: CGFloat], [String: CGFloat]) -> Void)? = nil
    var onPageHeightCalculated: ((Int, CGFloat) -> Void)? = nil
    var onPageScrollGeometryChanged: ((Int, CGFloat) -> Void)? = nil
    var onPageDisappeared: ((Int) -> Void)? = nil
    let onMarkVersesAsRead: ([Verse], CGFloat?) -> Void
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
    @State private var verseTopBoundsMap: [String: CGFloat] = [:]
    @State private var segmentVerseBoundsMap: [String: [String: CGFloat]] = [:]
    @State private var segmentVerseTopBoundsMap: [String: [String: CGFloat]] = [:]
    @State private var segmentMinYMap: [String: CGFloat] = [:]
    @State private var pageMinY: CGFloat = 0
    
    var body: some View {
        let (pState, pT0) = QuranPerf.shared.begin("2b_QuranPageView_body")
        defer {
            QuranPerf.shared.end("2b_QuranPageView_body", state: pState, t0: pT0, extra: "S.\(pageNumber)")
        }
        return VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else if hasError {
                VStack(spacing: 8) {
                    Text(String(format: L10n.tr("quran_page_load_error", language), pageNumber))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button(action: { loadPage() }) {
                        Text(L10n.tr("retry", language))
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
                #if os(iOS) && !SKIP
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.75)
                #else
                Spacer()
                    .frame(height: 500)
                #endif
            }
        }
        #if os(iOS)
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.size.height
        } action: { _, newHeight in
            if newHeight > 0 && !isLoading && !verses.isEmpty {
                onPageHeightCalculated?(pageNumber, newHeight)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.frame(in: .scrollView).minY
        } action: { _, newMinY in
            self.pageMinY = newMinY
            checkVersesScrollPosition(minY: newMinY)
            onPageScrollGeometryChanged?(pageNumber, newMinY)
        }
        #endif
        .onDisappear {
            onPageDisappeared?(pageNumber)
        }
        .onAppear {
            loadPage()
        }
        .onChange(of: pageNumber) { _, _ in
            verses = []
            verseBoundsMap = [:]
            verseTopBoundsMap = [:]
            segmentVerseBoundsMap = [:]
            segmentVerseTopBoundsMap = [:]
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
                            fontSize: fontSize,
                            theme: quranTheme,
                            onVerseBoundsCalculated: { bounds, topBounds in
                                self.segmentVerseBoundsMap[segment.id] = bounds
                                self.segmentVerseTopBoundsMap[segment.id] = topBounds
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
        let (bmState, bmT0) = QuranPerf.shared.begin("5c_updateVerseBoundsMap")
        defer {
            QuranPerf.shared.end("5c_updateVerseBoundsMap", state: bmState, t0: bmT0, extra: "S.\(pageNumber)")
        }
        var updatedMaxY: [String: CGFloat] = [:]
        var updatedMinY: [String: CGFloat] = [:]
        for (segId, relativeMap) in segmentVerseBoundsMap {
            let segMinY = segmentMinYMap[segId] ?? 0
            for (vId, relativeY) in relativeMap {
                updatedMaxY[vId] = segMinY + relativeY
            }
        }
        for (segId, relativeTopMap) in segmentVerseTopBoundsMap {
            let segMinY = segmentMinYMap[segId] ?? 0
            for (vId, relativeTopY) in relativeTopMap {
                updatedMinY[vId] = segMinY + relativeTopY
            }
        }
        self.verseBoundsMap = updatedMaxY
        self.verseTopBoundsMap = updatedMinY
        if !verses.isEmpty && updatedMaxY.count == verses.count {
            onPageBoundsCalculated?(updatedMaxY, updatedMinY)
        }
        checkVersesScrollPosition(minY: self.pageMinY)
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
        
        let fontLineHeight = Theme.quranUIFont(type: quranFontType, size: fontSize).lineHeight
        // Schwellwert: exakt 1 Zeilenhöhe unter der sichtbaren Oberkante (y = 0)
        let threshold = fontLineHeight
        
        let first5 = Array(verses.prefix(5))
        let first5Bounds = first5.compactMap { verseBoundsMap[$0.id] }
        let first5GlobalMaxY = first5Bounds.map { minY + $0 }
        print("[QURAN_DETECT] Page \(pageNumber): pageMinY=\(String(format: "%.1f", minY)), boundsCount=\(verseBoundsMap.count)/\(verses.count), first5Bounds=\(first5Bounds.map { String(format: "%.1f", $0) }), first5GlobalMaxY=\(first5GlobalMaxY.map { String(format: "%.1f", $0) }), threshold=\(String(format: "%.1f", threshold)), isUserScrolling=\(isUserScrolling), hasRestored=\(hasRestoredInitialPosition)")
        
        var readVersesOnPage: [Verse] = []
        for verse in verses {
            if let verseMaxY = verseBoundsMap[verse.id] {
                let globalVerseMaxY = minY + verseMaxY
                // Wenn globalVerseMaxY <= threshold (1 Zeilenhöhe), ist nur noch maximal 1 Zeile im sichtbaren Bereich
                if globalVerseMaxY <= threshold {
                    readVersesOnPage.append(verse)
                }
            }
        }
        
        // Auto-Complete für Seite 604: Wenn der Nutzer auf der letzten Seite bis zur Khatm-Karte heruntergescrollt hat
        if pageNumber == 604 && minY < -150 {
            if let lastVerse = verses.last, let maxIdx = QuranAPIService.shared.getVerseIndex(id: lastVerse.id) {
                if maxIdx + 1 > readFrontier && hasRestoredInitialPosition && !isZoomActive && isUserScrolling {
                    let lastVerseMaxY = verseBoundsMap[lastVerse.id]
                    onMarkVersesAsRead(verses, lastVerseMaxY)
                    return
                }
            }
        }
        
        if let maxVerse = readVersesOnPage.max(by: {
            (QuranAPIService.shared.getVerseIndex(id: $0.id) ?? -1) < (QuranAPIService.shared.getVerseIndex(id: $1.id) ?? -1)
        }) {
            if let maxIdx = QuranAPIService.shared.getVerseIndex(id: maxVerse.id) {
                if maxIdx + 1 > readFrontier {
                    guard hasRestoredInitialPosition else {
                        print("[QURAN_GUARD] advance unterdrückt: Startpositionierung noch nicht abgeschlossen (Page \(pageNumber), Ziel: \(maxVerse.surah):\(maxVerse.ayah))")
                        return
                    }
                    guard !isZoomActive else {
                        print("[QURAN_ZOOM] advance unterdrückt auf Seite \(pageNumber): Zoom/Layout aktiv (Ziel: \(maxVerse.surah):\(maxVerse.ayah))")
                        return
                    }
                    guard isUserScrolling else {
                        print("[QURAN_GUARD] advance unterdrückt: nicht durch Nutzer-Scrollen ausgelöst (Page \(pageNumber), Ziel: \(maxVerse.surah):\(maxVerse.ayah))")
                        return
                    }
                    let idxInPage = verses.firstIndex(where: { $0.id == maxVerse.id }) ?? 0
                    let prefixVerses = Array(verses[0...idxInPage])
                    let maxVerseMaxY = verseBoundsMap[maxVerse.id]
                    onMarkVersesAsRead(prefixVerses, maxVerseMaxY)
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
        let (csState, csT0) = QuranPerf.shared.begin("3_concatenatedString")
        defer {
            QuranPerf.shared.end("3_concatenatedString", state: csState, t0: csT0, extra: "S.\(pageNumber), \(versesList.count) Verse")
        }
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
    var fontSize: CGFloat = 30
    var theme: String
    var onVerseBoundsCalculated: (([String: CGFloat], [String: CGFloat]) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    class Coordinator: NSObject {
        var lastOriginalText: NSAttributedString?
        var lastModifiedText: NSAttributedString?
        var lastFontSize: CGFloat = 0
        var lastTheme: String = ""
        var lastWidth: CGFloat = 0
        var lastHasNewlineInserted: Bool = false
        var lastNewlineLocation: Int = -1
        var lastLineCharRange: NSRange? = nil
        var cachedBounds: [String: CGFloat] = [:]
        var cachedTopBounds: [String: CGFloat] = [:]
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
        let (ujState, ujT0) = QuranPerf.shared.begin("5a_JustifiedText_updateUIView")
        defer {
            QuranPerf.shared.end("5a_JustifiedText_updateUIView", state: ujState, t0: ujT0, extra: "\(verseRanges.count) Verse")
        }
        uiView.backgroundColor = Theme.getQuranUIBackgroundColor(for: theme, systemColorScheme: colorScheme)
        
        let coordinator = context.coordinator
        let currentWidth = uiView.bounds.width
        
        // HEBEL C: Prüfung auf reine Farbänderung (Text, Schriftgröße, Theme, Breite unverändert & Bounds vorhanden)
        let isSameText = (coordinator.lastOriginalText?.string == attributedText.string)
        let isSameFontSize = (coordinator.lastFontSize == fontSize)
        let isSameTheme = (coordinator.lastTheme == theme)
        let isSameWidth = (currentWidth > 0 && abs(coordinator.lastWidth - currentWidth) < 0.5)
        let hasCachedBounds = !coordinator.cachedBounds.isEmpty
        
        if isSameText && isSameFontSize && isSameTheme && isSameWidth && hasCachedBounds {
            // FAST PATH: Reine Farbänderung ohne TextKit-Neu-Layout
            let finalAttributed: NSAttributedString
            if coordinator.lastHasNewlineInserted,
               coordinator.lastNewlineLocation >= 0,
               coordinator.lastNewlineLocation <= attributedText.length {
                let mutable = NSMutableAttributedString(attributedString: attributedText)
                let centerParagraphStyle = NSMutableParagraphStyle()
                centerParagraphStyle.alignment = .center
                centerParagraphStyle.baseWritingDirection = .rightToLeft
                mutable.insert(NSAttributedString(string: "\n"), at: coordinator.lastNewlineLocation)
                if let lineRange = coordinator.lastLineCharRange,
                   lineRange.location + lineRange.length <= mutable.length {
                    mutable.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: lineRange)
                }
                finalAttributed = mutable
            } else if let lineRange = coordinator.lastLineCharRange,
                      lineRange.location + lineRange.length <= attributedText.length {
                let mutable = NSMutableAttributedString(attributedString: attributedText)
                let centerParagraphStyle = NSMutableParagraphStyle()
                centerParagraphStyle.alignment = .center
                centerParagraphStyle.baseWritingDirection = .rightToLeft
                mutable.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: lineRange)
                finalAttributed = mutable
            } else {
                finalAttributed = attributedText
            }
            
            coordinator.lastOriginalText = attributedText
            coordinator.lastModifiedText = finalAttributed
            uiView.attributedText = finalAttributed
            uiView.textAlignment = .center
            
            // KEIN ensureLayout, KEIN zweites Setzen, KEIN boundingRect, KEIN Callback!
            return
        }
        
        // FULL PATH: Neue Seite, Schriftgrößenänderung, Zoom, Drehen oder Erstinitialisierung
        coordinator.lastOriginalText = attributedText
        coordinator.lastFontSize = fontSize
        coordinator.lastTheme = theme
        coordinator.lastWidth = currentWidth
        
        uiView.attributedText = attributedText
        uiView.textAlignment = .center
        
        uiView.layoutManager.ensureLayout(for: uiView.textContainer)
        
        let layoutManager = uiView.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        guard numberOfGlyphs > 0 else {
            coordinator.lastHasNewlineInserted = false
            coordinator.lastNewlineLocation = -1
            coordinator.lastLineCharRange = nil
            coordinator.lastModifiedText = attributedText
            coordinator.cachedBounds = [:]
            coordinator.cachedTopBounds = [:]
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
                coordinator.lastHasNewlineInserted = false
                coordinator.lastNewlineLocation = -1
                coordinator.lastLineCharRange = lastLineCharRange
            } else {
                mutableAttributed.insert(NSAttributedString(string: "\n"), at: lastLineCharRange.location)
                let newLastLineRange = NSRange(location: lastLineCharRange.location + 1, length: lastLineCharRange.length)
                mutableAttributed.addAttribute(.paragraphStyle, value: centerParagraphStyle, range: newLastLineRange)
                coordinator.lastHasNewlineInserted = true
                coordinator.lastNewlineLocation = lastLineCharRange.location
                coordinator.lastLineCharRange = newLastLineRange
            }
            
            coordinator.lastModifiedText = mutableAttributed
            uiView.attributedText = mutableAttributed
        } else {
            coordinator.lastHasNewlineInserted = false
            coordinator.lastNewlineLocation = -1
            coordinator.lastLineCharRange = nil
            coordinator.lastModifiedText = attributedText
        }
        
        let (gbState, gbT0) = QuranPerf.shared.begin("5b_JustifiedText_glyphBounds")
        var boundsMap: [String: CGFloat] = [:]
        var topBoundsMap: [String: CGFloat] = [:]
        for (verseId, charRange) in verseRanges {
            if charRange.location + charRange.length <= uiView.textStorage.length {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
                let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: uiView.textContainer)
                boundsMap[verseId] = rect.maxY
                topBoundsMap[verseId] = rect.minY
            }
        }
        QuranPerf.shared.end("5b_JustifiedText_glyphBounds", state: gbState, t0: gbT0, extra: "\(boundsMap.count) Bounds")
        
        coordinator.cachedBounds = boundsMap
        coordinator.cachedTopBounds = topBoundsMap
        
        if !boundsMap.isEmpty {
            let bounds = boundsMap
            let topBounds = topBoundsMap
            DispatchQueue.main.async {
                onVerseBoundsCalculated?(bounds, topBounds)
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
    var fontSize: CGFloat = 24
    var theme: String
    
    var body: some View {
        Text(attributedText)
            .font(Theme.quranFont(type: quranFontType, size: fontSize))
            .multilineTextAlignment(.trailing)
            .environment(\.layoutDirection, .rightToLeft)
    }
}
#endif



#if os(iOS) && !SKIP
struct QuranScrollViewTracker: UIViewRepresentable {
    /// Maximale Nachrutsch-Distanz nach dem Loslassen (Faktor der sichtbaren Bildschirmhöhe)
    /// 0.5 = maximal eine halbe Bildschirmseite nachrutschen
    static let maxDecelerationPageRatio: CGFloat = 0.5

    @Binding var minAllowedOffsetY: CGFloat
    @Binding var isUserScrolling: Bool
    var onScrollViewFound: ((UIScrollView) -> Void)?
    var onScroll: ((CGFloat) -> Void)?
    var onScrollEnded: (() -> Void)? = nil
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: QuranScrollViewTracker
        weak var scrollView: UIScrollView?
        weak var originalDelegate: UIScrollViewDelegate?
        
        init(parent: QuranScrollViewTracker) {
            self.parent = parent
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            parent.isUserScrolling = true
            print("[QURAN_SCROLL] willBeginDragging -> isUserScrolling = true")
            originalDelegate?.scrollViewWillBeginDragging?(scrollView)
        }
        
        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            originalDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
            
            let proposedY = targetContentOffset.pointee.y
            let currentY = scrollView.contentOffset.y
            let visibleHeight = scrollView.bounds.size.height
            let maxDistance = visibleHeight * QuranScrollViewTracker.maxDecelerationPageRatio
            
            let maxY = currentY + maxDistance
            let minY = max(parent.minAllowedOffsetY, currentY - maxDistance)
            
            var cappedY = proposedY
            if cappedY > maxY {
                cappedY = maxY
            }
            if cappedY < minY {
                cappedY = minY
            }
            
            if abs(cappedY - proposedY) > 0.5 {
                print("[QURAN_SPEED] Nachrutschen begrenzt: \(String(format: "%.1f", proposedY))pt -> \(String(format: "%.1f", cappedY))pt (Max-Distanz: \(String(format: "%.1f", maxDistance))pt, minAllowedOffsetY: \(String(format: "%.1f", parent.minAllowedOffsetY))pt)")
                targetContentOffset.pointee.y = cappedY
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                parent.isUserScrolling = false
                print("[QURAN_SCROLL] didEndDragging (no deceleration) -> isUserScrolling = false")
                parent.onScrollEnded?()
            }
            originalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            parent.isUserScrolling = false
            print("[QURAN_SCROLL] didEndDecelerating -> isUserScrolling = false")
            parent.onScrollEnded?()
            originalDelegate?.scrollViewDidEndDecelerating?(scrollView)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let isUser = scrollView.isDragging || scrollView.isDecelerating
            if parent.isUserScrolling != isUser {
                parent.isUserScrolling = isUser
            }
            
            let minOffset = parent.minAllowedOffsetY
            if minOffset > 0 && scrollView.contentOffset.y < minOffset {
                scrollView.contentOffset.y = minOffset
            }
            parent.onScroll?(scrollView.contentOffset.y)
            originalDelegate?.scrollViewDidScroll?(scrollView)
        }
        
        override func responds(to aSelector: Selector!) -> Bool {
            if super.responds(to: aSelector) { return true }
            return originalDelegate?.responds(to: aSelector) ?? false
        }
        
        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            if let original = originalDelegate, original.responds(to: aSelector) {
                return original
            }
            return super.forwardingTarget(for: aSelector)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView() {
                context.coordinator.scrollView = scrollView
                if scrollView.delegate !== context.coordinator {
                    context.coordinator.originalDelegate = scrollView.delegate
                    scrollView.delegate = context.coordinator
                }
                onScrollViewFound?(scrollView)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }
}

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
