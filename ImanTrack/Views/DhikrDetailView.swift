import SwiftUI
import SwiftData

struct DhikrDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Query var allSettings: [UserSettings]
    @Query var allDailyRecords: [DailyRecord]
    
    let type: DhikrType?
    let customTasbih: CustomTasbih?
    let titleAr: String
    let titleDe: String
    let transliteration: String
    
    init(type: DhikrType, titleAr: String, titleDe: String, transliteration: String) {
        self.type = type
        self.customTasbih = nil
        self.titleAr = titleAr
        self.titleDe = titleDe
        self.transliteration = transliteration
    }
    
    init(customTasbih: CustomTasbih) {
        self.type = nil
        self.customTasbih = customTasbih
        self.titleAr = customTasbih.arabic.isEmpty ? customTasbih.title : customTasbih.arabic
        self.titleDe = customTasbih.title
        self.transliteration = customTasbih.transliteration
    }
    
    @State var selectedIndex: Int = 0
    
    enum CounterState { case idle, running, paused }
    @State var counterState: CounterState = .idle
    @State var sessionCount = 0
    @State var autoTimer: Timer? = nil
    
    @State var showMashaAllah = false
    @State var showResetToast = false
    @State var isPulsing = false
    @State var flashGreen = false
    @State var flashOpacity: Double = 1.0
    @State var flashToken = 0
    @State private var lastIncrementTime: Double = 0
    
    @State var showStopSessionSheet = false
    @State var showManualAddAlert = false
    @State var manualAddAmount = ""
    @State private var lastManualAddAmount = 0
    @State private var showMaghribCountdownToast = false
    @State var showInfoSheet = false
    @State private var speedUpdateToken = 0
    @FocusState var isTextFieldFocused: Bool
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @StateObject var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    private var activeIstighfarCases: [IstighfarForm] {
        IstighfarForm.allCases
    }
    
    private var activeSalawatCases: [SalawatForm] {
        SalawatForm.allCases
    }
    
    private var currentGoal: Int {
        if let custom = customTasbih { return custom.goal }
        guard let type = type else { return 100 }
        switch type {
        case .istighfar: return settings.istighfarGoal
        case .salawat: return settings.effectiveSalawatGoal(for: todayRecord.date)
        case .subhanAllah: return settings.subhanAllahGoal
        case .alhamdulillah: return settings.alhamdulillahGoal
        case .allahuAkbar: return settings.allahuAkbarGoal
        case .laIlahaIllallah: return settings.laIlahaIllallahGoal
        }
    }
    
    private var isFridaySalawatGoalActive: Bool {
        type == .salawat && settings.salawatFridayGoalEnabled && settings.isIslamicFriday(for: todayRecord.date)
    }
    
    private var currentTempo: Int {
        if let _ = customTasbih { return 60 }
        guard let type = type else { return 60 }
        let rawVal: Int
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { return baseTempo }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: rawVal = settings.istighfarKurzBpm == 0 ? baseTempo : settings.istighfarKurzBpm
            case .extended: rawVal = settings.istighfarExtendedBpm == 0 ? baseTempo : settings.istighfarExtendedBpm
            case .gewaltig: rawVal = settings.istighfarGewaltigBpm == 0 ? baseTempo : settings.istighfarGewaltigBpm
            case .yunus: rawVal = settings.istighfarYunusBpm == 0 ? baseTempo : settings.istighfarYunusBpm
            case .lang: rawVal = settings.istighfarLangBpm == 0 ? baseTempo : settings.istighfarLangBpm
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { return baseTempo }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .waSallim: rawVal = settings.salawatWaSallimBpm == 0 ? baseTempo : settings.salawatWaSallimBpm
            case .kurz: rawVal = settings.salawatKurzBpm == 0 ? baseTempo : settings.salawatKurzBpm
            case .lang: rawVal = settings.salawatLangBpm == 0 ? baseTempo : settings.salawatLangBpm
            }
        case .subhanAllah: rawVal = settings.subhanAllahPerMinute == 0 ? baseTempo : settings.subhanAllahPerMinute
        case .alhamdulillah: rawVal = settings.alhamdulillahPerMinute == 0 ? baseTempo : settings.alhamdulillahPerMinute
        case .allahuAkbar: rawVal = settings.allahuAkbarPerMinute == 0 ? baseTempo : settings.allahuAkbarPerMinute
        case .laIlahaIllallah: rawVal = settings.laIlahaIllallahPerMinute == 0 ? baseTempo : settings.laIlahaIllallahPerMinute
        }
        return max(40, rawVal)
    }
    
    private var pageCount: Int {
        if let _ = customTasbih { return 1 }
        guard let type = type else { return 1 }
        switch type {
        case .istighfar: return activeIstighfarCases.count
        case .salawat: return activeSalawatCases.count
        default: return 1
        }
    }
    
    private var localizedTitle: String {
        if let custom = customTasbih { return custom.title }
        guard let type = type else { return "" }
        switch type {
        case .istighfar: return L10n.tr("tasbih_type_istighfar", settings.language)
        case .salawat: return L10n.tr("tasbih_type_salawat", settings.language)
        case .subhanAllah: return "SubhanAllah"
        case .alhamdulillah: return "Alhamdulillah"
        case .allahuAkbar: return "La hawla..."
        case .laIlahaIllallah: return L10n.tr("tasbih_type_lailahaillallah", settings.language)
        }
    }
    
    private func titleArFor(_ index: Int) -> String {
        if let custom = customTasbih { return custom.arabic.isEmpty ? custom.title : custom.arabic }
        guard let type = type else { return titleAr }
        switch type {
        case .istighfar:
            guard index < activeIstighfarCases.count else { return "" }
            return activeIstighfarCases[index].arabic
        case .salawat:
            guard index < activeSalawatCases.count else { return "" }
            return activeSalawatCases[index].arabic
        default: return titleAr
        }
    }
    
    private func titleDeFor(_ index: Int) -> String {
        if let custom = customTasbih { return custom.title }
        guard let type = type else { return titleDe }
        switch type {
        case .istighfar:
            guard index < activeIstighfarCases.count else { return "" }
            return activeIstighfarCases[index].displayName(for: settings.language)
        case .salawat:
            guard index < activeSalawatCases.count else { return "" }
            return activeSalawatCases[index].displayName(for: settings.language)
        case .subhanAllah:
            return L10n.tr("tasbih_subhanallah_trans", settings.language)
        case .alhamdulillah:
            return L10n.tr("tasbih_alhamdulillah_trans", settings.language)
        case .allahuAkbar:
            return L10n.tr("tasbih_lahawla_trans", settings.language)
        case .laIlahaIllallah:
            return L10n.tr("tasbih_lailahaillallah_trans", settings.language)
        }
    }
    
    private var currentTranslation: String {
        titleDeFor(selectedIndex)
    }
    
    private func transliterationFor(_ index: Int) -> String {
        if let custom = customTasbih { return custom.transliteration }
        guard let type = type else { return transliteration }
        switch type {
        case .istighfar:
            guard index < activeIstighfarCases.count else { return "" }
            return activeIstighfarCases[index].subtitle(for: settings.language)
        case .salawat:
            guard index < activeSalawatCases.count else { return "" }
            return activeSalawatCases[index].subtitle(for: settings.language)
        default: return transliteration
        }
    }
    
    struct TasbihIntervals {
        let langsam: Double
        let normal: Double
        let schnell: Double
    }
    
    private var presetTasbihIntervals: TasbihIntervals? {
        guard let type = type else { return nil }
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { return nil }
            switch activeIstighfarCases[selectedIndex] {
            case .kurz: return TasbihIntervals(langsam: 1.08, normal: 0.67, schnell: 0.42)
            case .extended: return TasbihIntervals(langsam: 1.51, normal: 1.15, schnell: 0.88)
            case .gewaltig: return TasbihIntervals(langsam: 4.95, normal: 4.47, schnell: 4.04)
            case .yunus: return TasbihIntervals(langsam: 4.00, normal: 3.44, schnell: 2.96)
            case .lang: return TasbihIntervals(langsam: 13.45, normal: 11.88, schnell: 10.49)
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { return nil }
            switch activeSalawatCases[selectedIndex] {
            case .waSallim: return TasbihIntervals(langsam: 2.20, normal: 1.78, schnell: 1.60)
            case .kurz: return TasbihIntervals(langsam: 2.63, normal: 2.14, schnell: 1.95)
            case .lang: return TasbihIntervals(langsam: 10.45, normal: 9.64, schnell: 8.89)
            }
        case .subhanAllah:
            return TasbihIntervals(langsam: 3.28, normal: 2.94, schnell: 2.64)
        case .alhamdulillah:
            return TasbihIntervals(langsam: 4.57, normal: 3.82, schnell: 3.19)
        case .allahuAkbar:
            return TasbihIntervals(langsam: 2.80, normal: 2.43, schnell: 2.11)
        case .laIlahaIllallah:
            return TasbihIntervals(langsam: 5.63, normal: 4.91, schnell: 4.28)
        }
    }
    
    private func speedKeyFor(index: Int) -> String {
        if let custom = customTasbih {
            return "tasbih_speed_\(custom.id)"
        }
        guard let type = type else { return "tasbih_speed_default" }
        switch type {
        case .istighfar:
            guard index < activeIstighfarCases.count else { return "tasbih_speed_istighfar" }
            let form = activeIstighfarCases[index]
            return "tasbih_speed_istighfar_\(form.rawValue)"
        case .salawat:
            guard index < activeSalawatCases.count else { return "tasbih_speed_salawat" }
            let form = activeSalawatCases[index]
            return "tasbih_speed_salawat_\(form.rawValue)"
        case .subhanAllah:
            return "tasbih_speed_subhanAllah"
        case .alhamdulillah:
            return "tasbih_speed_alhamdulillah"
        case .allahuAkbar:
            return "tasbih_speed_allahuAkbar"
        case .laIlahaIllallah:
            return "tasbih_speed_laIlahaIllallah"
        }
    }
    
    private func speedStepFor(index: Int) -> Int {
        _ = speedUpdateToken
        let key = speedKeyFor(index: index)
        if let saved = UserDefaults.standard.object(forKey: key) as? Int {
            return min(max(saved, 0), 2)
        }
        return 1 // Voreinstellung "Mittel" für Tasbih
    }
    
    private func saveSpeedStep(_ newStep: Int, forIndex index: Int) {
        let key = speedKeyFor(index: index)
        UserDefaults.standard.set(newStep, forKey: key)
        speedUpdateToken += 1
        if index == selectedIndex && counterState == .running {
            pauseTimer()
            startTimer()
        }
    }
    
    private var currentTasbihKey: String {
        speedKeyFor(index: selectedIndex)
    }
    
    private var currentSpeedStep: Int {
        speedStepFor(index: selectedIndex)
    }
    
    var interval: Double {
        if let preset = presetTasbihIntervals {
            let step = currentSpeedStep
            switch step {
            case 0: return preset.langsam
            case 1: return preset.normal
            case 2: return preset.schnell
            default: return preset.normal
            }
        }
        return 60.0 / Double(max(1, currentTempo))
    }
    
    private var tempoBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(currentTempo) },
            set: { updateTempo(to: Int($0)) }
        )
    }
    
    private var baseTempo: Int {
        if let _ = customTasbih { return 60 }
        guard let type = type else { return 60 }
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { return 60 }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: return 60
            case .extended: return 50
            case .gewaltig: return 40
            case .yunus: return 40
            case .lang: return 40
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { return 60 }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .waSallim: return 60
            case .kurz: return 60
            case .lang: return 40
            }
        case .subhanAllah: return 60
        case .alhamdulillah: return 60
        case .allahuAkbar: return 60
        case .laIlahaIllallah: return 60
        }
    }
    
    private var tempoStepSize: Int {
        let base = baseTempo
        if base <= 5 {
            return 1
        } else if base <= 15 {
            return 2
        } else if base <= 30 {
            return 5
        } else {
            return 10
        }
    }
    
    private var ringColor: Color {
        switch counterState {
        case .idle, .paused:
            return Color.white.opacity(0.15)
        case .running:
            return Theme.islamicGreen.opacity(0.55)
        }
    }
    
    private var isSmallScreen: Bool {
        #if os(iOS) && !SKIP
        return UIScreen.main.bounds.height <= 700
        #else
        return false
        #endif
    }
    
    private var textBlockHeight: CGFloat {
        isSmallScreen ? 120 : 135
    }
    
    private func arabicFontSizeFor(_ text: String) -> CGFloat {
        let count = text.count
        if count <= 25 {
            return isSmallScreen ? 26 : 28
        } else if count <= 55 {
            return isSmallScreen ? 22 : 24
        } else if count <= 90 {
            return isSmallScreen ? 20 : 22
        } else if count <= 130 {
            return isSmallScreen ? 18 : 19
        } else {
            return isSmallScreen ? 17 : 18
        }
    }
    
    private func arabicLineSpacingFor(_ text: String) -> CGFloat {
        let count = text.count
        if count <= 25 {
            return 6
        } else if count <= 55 {
            return 5
        } else {
            return 4
        }
    }
    
    private func transliterationFontSizeFor(_ text: String) -> CGFloat {
        let count = text.count
        if count <= 35 {
            return isSmallScreen ? 14 : 15
        } else if count <= 70 {
            return isSmallScreen ? 13 : 13.5
        } else if count <= 120 {
            return isSmallScreen ? 12 : 12.5
        } else {
            return isSmallScreen ? 11 : 11.5
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    var body: some View {
        let lang = settings.language
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 5-Minuten-Warnung vor Maghrib
                if solarManager.showFiveMinuteWarning {
                    MaghribFiveMinuteWarningBanner(language: lang) {
                        solarManager.dismissFiveMinuteWarning()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Page Indicator at the very top (feste Höhe für alle Tasbihs)
                HStack(spacing: 8) {
                    if pageCount > 1 {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Circle()
                                .fill(selectedIndex == index ? Theme.islamicGreen : Color.primary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    withAnimation {
                                        selectedIndex = index
                                    }
                                }
                        }
                    } else {
                        Color.clear.frame(width: 8, height: 8)
                    }
                }
                .frame(height: 14)
                .padding(.top, 6)
                .padding(.bottom, 6)
                
                // TabView für die Versionen (BPM & Arabischer Text ändern sich, Zähler bleibt unifiziert)
                TabView(selection: $selectedIndex) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        let arText = titleArFor(index)
                        let transText = transliterationFor(index)
                        let hasTrans = settings.language != "ar" && settings.showTransliteration && !transText.isEmpty
                        let arSize = arabicFontSizeFor(arText)
                        let arSpacing = arabicLineSpacingFor(arText)
                        let transSize = transliterationFontSizeFor(transText)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: hasTrans ? 6 : 0) {
                                Text(arText)
                                    .font(.system(size: arSize, weight: .regular))
                                    .minimumScaleFactor(0.75)
                                    .lineSpacing(arSpacing)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .padding(.horizontal, 16)
                                
                                if hasTrans {
                                    Text(transText)
                                        .font(.system(size: transSize, weight: .medium))
                                        .minimumScaleFactor(0.8)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: textBlockHeight, alignment: .center)
                        }
                        .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif
                .frame(height: textBlockHeight)
                .onChange(of: selectedIndex) { _, newValue in
                    if type == .istighfar {
                        if newValue < activeIstighfarCases.count {
                            settings.istighfarVersion = activeIstighfarCases[newValue].rawValue
                            try? modelContext.save()
                        }
                    } else if type == .salawat {
                        if newValue < activeSalawatCases.count {
                            settings.salawatVersion = activeSalawatCases[newValue].rawValue
                            try? modelContext.save()
                        }
                    }
                    if counterState == .running {
                        pauseTimer()
                        startTimer()
                    }
                }

                // Freier Bereich oberhalb des Zählkreises (symmetrisch zum unteren Bereich)
                Spacer(minLength: 8)

                // Main Counter Circle
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(getCurrentCount()) / CGFloat(max(1, currentGoal)))
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: ringColor)
                    
                    Circle()
                        .fill(Theme.islamicGreen.opacity(Theme.tasbihFlashBaseOpacity))
                        .padding(7.5)
                        .opacity(flashGreen ? flashOpacity : 0.0)
                        .allowsHitTesting(false)
                    
                    // Numerische Fortschrittszahl und Tagesziel im Kreis
                    VStack(spacing: 6) {
                        Text(formatNumber(getCurrentCount()))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Text(formatNumber(currentGoal))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                            if isFridaySalawatGoalActive {
                                Text(L10n.tr("salawat_friday_goal", settings.language))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.islamicGreen)
                            }
                        }
                            
                        if settings.tasbihAutoCount {
                            let iconName = counterState == .running ? "stop.fill" : "play.fill"
                            let iconColor: Color = .gray
                            
                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundColor(iconColor)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                }
                .frame(width: 240, height: 240)
                .contentShape(Circle())
                .onTapGesture {
                    handleCircleTap()
                }

                // Freier Bereich unterhalb des Zählkreises (symmetrisch zum oberen Bereich)
                Spacer(minLength: 8)

                // Symmetrische Buttons unten mit sanften, zum Design passenden Farben
                HStack(alignment: .center) {
                    // Links: Korrektur-Button (Minus, sanftes Rot)
                    Button(action: {
                        handleMinusButtonTap()
                    }) {
                        Image(systemName: "minus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.red.opacity(0.85))
                            .frame(width: 58, height: 58)
                            .background(Color.red.opacity(0.14))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.red.opacity(0.25), lineWidth: 1.5)
                            )
                    }
                    .padding(.leading, 30)
                    
                    Spacer(minLength: 8)
                    
                    // Mitte: Kompakte Drei-Stufen-Auswahl (Langsam / Normal / Schnell)
                    CompactTasbihSpeedSelector(
                        currentStep: currentSpeedStep,
                        language: settings.language,
                        onSelectStep: { newStep in
                            saveSpeedStep(newStep, forIndex: selectedIndex)
                        }
                    )
                    
                    Spacer(minLength: 8)
                    
                    // Rechts: Plus-Button für manuelles Eintragen (sanftes Grün)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showManualAddAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.islamicGreen)
                            .frame(width: 58, height: 58)
                            .background(Theme.islamicGreen.opacity(0.14))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Theme.islamicGreen.opacity(0.25), lineWidth: 1.5)
                            )
                    }
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 24)
            }
            
            if showMashaAllah {
                Color.black.opacity(0.3).ignoresSafeArea()
                Text("ما شاء الله")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.islamicGreen)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if showResetToast {
                VStack {
                    Spacer()
                    Text(L10n.tr("reset_msg", lang))
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showMaghribCountdownToast {
                VStack {
                    Spacer()
                    Text(L10n.tr("tasbih_maghrib_reset_info", lang))
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Custom-Overlay für manuelles Hinzufügen (minimalistisches Pop-up)
            if showManualAddAlert {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissManualAdd()
                        }
                    
                    VStack(spacing: 20) {
                        ManualAddTextField(manualAddAmount: $manualAddAmount, isTextFieldFocused: $isTextFieldFocused)
                        
                        Button(action: {
                            if let amount = Int(manualAddAmount), amount > 0 {
                                addManualCount(amount)
                            }
                            dismissManualAdd()
                        }) {
                            Text(L10n.tr("add", lang))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.islamicGreen)
                                .cornerRadius(12)
                                .shadow(color: Theme.islamicGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(20)
                    .frame(width: 180)
                    .background(Theme.cardBackground)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(10)
            }
            
            // Custom-Overlay für Beenden & Korrektur (Prozente + Letzte Zählung entfernen)
            if showStopSessionSheet {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showStopSessionSheet = false
                            }
                        }
                    
                    VStack(spacing: 16) {
                        // Prozentuale Abzüge der laufenden Sitzung
                        HStack(spacing: 8) {
                            let discounts = [10, 30, 50, 100]
                            ForEach(discounts, id: \.self) { pct in
                                Button(action: {
                                    saveSession(discountPercent: pct)
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showStopSessionSheet = false
                                    }
                                }) {
                                    Text("-\(pct)%")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.red.opacity(sessionCount > 0 ? 0.9 : 0.4))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.red.opacity(sessionCount > 0 ? 0.12 : 0.05))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.red.opacity(sessionCount > 0 ? 0.25 : 0.1), lineWidth: 1)
                                        )
                                }
                                .disabled(sessionCount == 0)
                            }
                        }
                        
                        Divider()
                            .background(Color.primary.opacity(0.15))
                        
                        // Button: Nur die letzte manuelle Hinzufügung entfernen (keine freie Zahleneingabe)
                        let countToRemove = lastManualAddAmount
                        VStack(spacing: 10) {
                            Button(action: {
                                removeLastManualAdd()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(countToRemove > 0
                                         ? String(format: L10n.tr("tasbih_remove_last_count", lang), "\(countToRemove)")
                                         : L10n.tr("tasbih_no_recent_to_remove", lang))
                                        .font(.system(size: 14, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.red.opacity(countToRemove > 0 ? 0.85 : 0.4))
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(countToRemove > 0 ? 0.25 : 0.0), radius: 4, x: 0, y: 2)
                            }
                            .disabled(countToRemove == 0)
                            
                            // Abbrechen
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showStopSessionSheet = false
                                }
                            }) {
                                Text(L10n.tr("cancel", lang))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.primary.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(20)
                    .frame(width: 280)
                    .background(Theme.cardBackground)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(10)
            }
        }
        .navigationTitle(localizedTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showInfoSheet = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.islamicGreen)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showInfoSheet = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.islamicGreen)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            if type == .istighfar {
                let active = activeIstighfarCases
                if let savedVersion = IstighfarForm(rawValue: settings.istighfarVersion),
                   let idx = active.firstIndex(of: savedVersion) {
                    selectedIndex = idx
                } else {
                    selectedIndex = 0
                }
            } else if type == .salawat {
                let active = activeSalawatCases
                if let savedVersion = SalawatForm(rawValue: settings.salawatVersion),
                   let idx = active.firstIndex(of: savedVersion) {
                    selectedIndex = idx
                } else {
                    selectedIndex = 0
                }
            }
        }
        .onDisappear {
            pauseTimer()
            counterState = .idle
            sessionCount = 0
            lastManualAddAmount = 0
        }
        .onChange(of: solarManager.currentTrackingDate) { _, _ in
            handleMaghribReset()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MaghribDayResetTriggered"))) { _ in
            handleMaghribReset()
        }
        .sheet(isPresented: $showInfoSheet) {
            TranslationSheet(
                language: settings.language,
                title: localizedTitle,
                translation: currentTranslation
            )
        }
    }
    
    private func handleMaghribReset() {
        if counterState == .running {
            pauseTimer()
            counterState = .idle
        }
        sessionCount = 0
        lastManualAddAmount = 0
        withAnimation(.easeInOut(duration: 0.3)) {
            showResetToast = true
        }
        #if os(iOS) && !SKIP
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showResetToast = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleCircleTap() {
        let useAuto = settings.tasbihAutoCount
        if useAuto {
            switch counterState {
            case .idle, .paused:
                counterState = .running
                startTimer()
            case .running:
                counterState = .paused
                pauseTimer()
            }
        } else {
            incrementCount(isAuto: false)
        }
    }
    
    private func startTimer() {
        #if os(iOS) && !SKIP
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        autoTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { _ in
            DispatchQueue.main.async {
                self.incrementCount(isAuto: true)
            }
        }
    }
    
    private func pauseTimer() {
        autoTimer?.invalidate()
        autoTimer = nil
        #if os(iOS) && !SKIP
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
    }
    
    private func handleMinusButtonTap() {
        if counterState == .running {
            counterState = .paused
            pauseTimer()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showStopSessionSheet = true
        }
    }
    
    private func saveSession(discountPercent: Int) {
        guard sessionCount > 0 else { return }
        let removeDiff: Int
        if discountPercent == 100 {
            removeDiff = sessionCount
        } else {
            removeDiff = max(1, Int(round(Double(sessionCount) * Double(discountPercent) / 100.0)))
        }
        applyCorrection(removeDiff: removeDiff)
        
        counterState = .idle
        sessionCount = 0
        
        withAnimation(.easeInOut(duration: 0.2)) {
            flashGreen = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                flashGreen = false
            }
        }
        
        #if os(iOS) && !SKIP
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    private func removeLastManualAdd() {
        guard lastManualAddAmount > 0 else { return }
        let toRemove = lastManualAddAmount
        applyCorrection(removeDiff: toRemove)
        lastManualAddAmount = 0
        
        withAnimation(.easeOut(duration: 0.2)) {
            showStopSessionSheet = false
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            flashGreen = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                flashGreen = false
            }
        }
        
        #if os(iOS) && !SKIP
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    private func applyCorrection(removeDiff: Int) {
        guard removeDiff > 0 else { return }
        let record = todayRecord
        if let custom = customTasbih {
            let current = record.getCustomTasbihCount(for: custom.id)
            record.setCustomTasbihCount(for: custom.id, count: max(0, current - removeDiff))
        } else if let type = type {
            switch type {
            case .istighfar: record.istighfarCount = max(0, record.istighfarCount - removeDiff)
            case .salawat: record.salawatCount = max(0, record.salawatCount - removeDiff)
            case .subhanAllah: record.subhanAllahCount = max(0, record.subhanAllahCount - removeDiff)
            case .alhamdulillah: record.alhamdulillahCount = max(0, record.alhamdulillahCount - removeDiff)
            case .allahuAkbar: record.allahuAkbarCount = max(0, record.allahuAkbarCount - removeDiff)
            case .laIlahaIllallah: record.laIlahaIllallahCount = max(0, record.laIlahaIllallahCount - removeDiff)
            }
        }
        try? modelContext.save()
    }
    
    private func resetCurrentCountToZero() {
        let record = todayRecord
        if let custom = customTasbih {
            record.setCustomTasbihCount(for: custom.id, count: 0)
        } else if let type = type {
            switch type {
            case .istighfar:
                record.istighfarCount = 0
                record.istighfarMediumCount = 0
                record.istighfarSayyidCount = 0
            case .salawat:
                record.salawatCount = 0
                record.salawatCombinedCount = 0
                record.salawatIbrahimiyahCount = 0
            case .subhanAllah: record.subhanAllahCount = 0
            case .alhamdulillah: record.alhamdulillahCount = 0
            case .allahuAkbar: record.allahuAkbarCount = 0
            case .laIlahaIllallah: record.laIlahaIllallahCount = 0
            }
        }
        sessionCount = 0
        try? modelContext.save()
    }
    
    private func getCurrentCount() -> Int {
        let record = todayRecord
        let rawCount: Int
        if let custom = customTasbih {
            rawCount = record.getCustomTasbihCount(for: custom.id)
        } else if let type = type {
            switch type {
            case .istighfar: rawCount = record.istighfarCount
            case .salawat: rawCount = record.salawatCount
            case .subhanAllah: rawCount = record.subhanAllahCount
            case .alhamdulillah: rawCount = record.alhamdulillahCount
            case .allahuAkbar: rawCount = record.allahuAkbarCount
            case .laIlahaIllallah: rawCount = record.laIlahaIllallahCount
            }
        } else {
            rawCount = 0
        }
        
        // Automatische Selbstheilung: Falls der Zählerstand z.B. durch Fehleingabe extrem hoch ist (> 500.000)
        if rawCount > 500_000 {
            DispatchQueue.main.async {
                self.resetCurrentCountToZero()
            }
            return 0
        }
        return max(0, rawCount)
    }
    
    private func dismissManualAdd() {
        withAnimation(.easeOut(duration: 0.2)) {
            showManualAddAlert = false
        }
        manualAddAmount = ""
        isTextFieldFocused = false
    }
    
    private func addManualCount(_ amount: Int) {
        let safeAmount = min(max(1, amount), 5_000)
        let record = todayRecord
        if let custom = customTasbih {
            let current = max(0, record.getCustomTasbihCount(for: custom.id))
            record.setCustomTasbihCount(for: custom.id, count: min(current + safeAmount, 500_000))
        } else if let type = type {
            switch type {
            case .istighfar: record.istighfarCount = min(max(0, record.istighfarCount) + safeAmount, 500_000)
            case .salawat: record.salawatCount = min(max(0, record.salawatCount) + safeAmount, 500_000)
            case .subhanAllah: record.subhanAllahCount = min(max(0, record.subhanAllahCount) + safeAmount, 500_000)
            case .alhamdulillah: record.alhamdulillahCount = min(max(0, record.alhamdulillahCount) + safeAmount, 500_000)
            case .allahuAkbar: record.allahuAkbarCount = min(max(0, record.allahuAkbarCount) + safeAmount, 500_000)
            case .laIlahaIllallah: record.laIlahaIllallahCount = min(max(0, record.laIlahaIllallahCount) + safeAmount, 500_000)
            }
        }
        lastManualAddAmount = safeAmount
        sessionCount = 0
        checkCompletion()
        try? modelContext.save()
    }
    
    private func incrementCount(isAuto: Bool = false) {
        let record = todayRecord
        
        if settings.tasbihVibrationEnabled {
            #if os(iOS) && !SKIP
            UIImpactFeedbackGenerator(style: isAuto ? .light : .medium)
                .impactOccurred()
            #endif
        }
        
        if let custom = customTasbih {
            let current = record.getCustomTasbihCount(for: custom.id)
            record.setCustomTasbihCount(for: custom.id, count: current + 1)
        } else if let type = type {
            switch type {
            case .istighfar: record.istighfarCount += 1
            case .salawat: record.salawatCount += 1
            case .subhanAllah: record.subhanAllahCount += 1
            case .alhamdulillah: record.alhamdulillahCount += 1
            case .allahuAkbar: record.allahuAkbarCount += 1
            case .laIlahaIllallah: record.laIlahaIllallahCount += 1
            }
        }
        
        sessionCount += 1
        
        triggerGreenFlash()
        
        checkCompletion()
        try? modelContext.save()
    }
    
    private func triggerGreenFlash() {
        let now = CACurrentMediaTime()
        let interval: Double
        if lastIncrementTime > 0 {
            interval = max(0.01, now - lastIncrementTime)
        } else {
            interval = Theme.tasbihFlashSlowIntervalThreshold
        }
        lastIncrementTime = now
        
        // 1. Stärke proportional zum Intervall berechnen (bei ruhigem Tempo >= 2.0s 100%, bei 0,5s ca. 35%)
        let strengthFactor: Double
        if interval >= Theme.tasbihFlashSlowIntervalThreshold {
            strengthFactor = 1.0
        } else if interval <= Theme.tasbihFlashFastIntervalThreshold {
            strengthFactor = Theme.tasbihFlashMinStrengthFactor
        } else {
            let progress = (interval - Theme.tasbihFlashFastIntervalThreshold) /
                           (Theme.tasbihFlashSlowIntervalThreshold - Theme.tasbihFlashFastIntervalThreshold)
            strengthFactor = Theme.tasbihFlashMinStrengthFactor + progress * (1.0 - Theme.tasbihFlashMinStrengthFactor)
        }
        
        // 2. Dauer proportional berechnen und auf max. 40% des Abstands begrenzen
        let baseTotalDuration = Theme.tasbihFlashBaseHoldDuration + Theme.tasbihFlashBaseFadeOutDuration
        let durationFactor: Double
        if interval >= Theme.tasbihFlashSlowIntervalThreshold {
            durationFactor = 1.0
        } else if interval <= Theme.tasbihFlashFastIntervalThreshold {
            durationFactor = Theme.tasbihFlashMinDurationFactor
        } else {
            let progress = (interval - Theme.tasbihFlashFastIntervalThreshold) /
                           (Theme.tasbihFlashSlowIntervalThreshold - Theme.tasbihFlashFastIntervalThreshold)
            durationFactor = Theme.tasbihFlashMinDurationFactor + progress * (1.0 - Theme.tasbihFlashMinDurationFactor)
        }
        
        let targetTotalDuration = baseTotalDuration * durationFactor
        let maxAllowedDuration = interval * Theme.tasbihFlashMaxDurationRatio
        let finalTotalDuration = min(targetTotalDuration, maxAllowedDuration)
        
        let holdDelay = finalTotalDuration * (Theme.tasbihFlashBaseHoldDuration / baseTotalDuration)
        let fadeOutDuration = finalTotalDuration * (Theme.tasbihFlashBaseFadeOutDuration / baseTotalDuration)
        let fadeInDuration = finalTotalDuration * (Theme.tasbihFlashBaseFadeInDuration / baseTotalDuration)
        
        flashOpacity = strengthFactor
        flashToken &+= 1
        let currentToken = flashToken
        withAnimation(.easeIn(duration: fadeInDuration)) {
            flashGreen = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay) {
            guard self.flashToken == currentToken else { return }
            withAnimation(.easeOut(duration: fadeOutDuration)) {
                self.flashGreen = false
            }
        }
    }
    
    private func checkCompletion() {
        if getCurrentCount() >= currentGoal {
            AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
            if getCurrentCount() == currentGoal {
                withAnimation {
                    showMashaAllah = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showMashaAllah = false
                    }
                }
            }
        }
    }
    
    private func updateTempo(to newValue: Int) {
        let currentStatus = counterState
        if currentStatus == .running {
            pauseTimer()
        }
        
        if let _ = customTasbih {
            if currentStatus == .running {
                startTimer()
            }
            return
        }
        
        guard let type = type else { return }
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { break }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: settings.istighfarKurzBpm = newValue
            case .extended: settings.istighfarExtendedBpm = newValue
            case .gewaltig: settings.istighfarGewaltigBpm = newValue
            case .yunus: settings.istighfarYunusBpm = newValue
            case .lang: settings.istighfarLangBpm = newValue
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { break }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .waSallim: settings.salawatWaSallimBpm = newValue
            case .kurz: settings.salawatKurzBpm = newValue
            case .lang: settings.salawatLangBpm = newValue
            }
        case .subhanAllah: settings.subhanAllahPerMinute = newValue
        case .alhamdulillah: settings.alhamdulillahPerMinute = newValue
        case .allahuAkbar: settings.allahuAkbarPerMinute = newValue
        case .laIlahaIllallah: settings.laIlahaIllallahPerMinute = newValue
        }
        try? modelContext.save()
        
        if currentStatus == .running {
            startTimer()
        }
    }
}

struct TranslationSheet: View {
    @Environment(\.dismiss) var dismiss
    let language: String
    let title: String
    let translation: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 16)
                        }
                        
                        if language != "ar" {
                            Text(translation)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("done", language)) {
                        dismiss()
                    }
                    .foregroundColor(Theme.islamicGreen)
                }
            }
            #if os(iOS)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }
}

struct CompactTasbihSpeedSelector: View {
    let currentStep: Int
    let language: String
    let onSelectStep: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            // Option 0: Schildkröte (Langsam)
            segmentButton(stepIndex: 0, accessibilityText: L10n.tr("tempo_slow", language)) {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 13, weight: currentStep == 0 ? .semibold : .medium))
            }
            
            // Option 1: "Normal"
            segmentButton(stepIndex: 1, accessibilityText: L10n.tr("tempo_normal", language)) {
                Text(L10n.tr("tempo_normal", language))
                    .font(.system(size: 12, weight: currentStep == 1 ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            
            // Option 2: Hase (Schnell)
            segmentButton(stepIndex: 2, accessibilityText: L10n.tr("tempo_fast", language)) {
                Image(systemName: "hare.fill")
                    .font(.system(size: 13, weight: currentStep == 2 ? .semibold : .medium))
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func segmentButton<V: View>(stepIndex: Int, accessibilityText: String, @ViewBuilder content: () -> V) -> some View {
        let isSelected = currentStep == stepIndex
        Button(action: {
            if stepIndex != currentStep {
                #if os(iOS) && !SKIP
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                #endif
                onSelectStep(stepIndex)
            }
        }) {
            content()
                .foregroundColor(isSelected ? Theme.islamicGreen : Color.gray)
                .padding(.horizontal, 10)
                .frame(minHeight: 34)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(Theme.islamicGreen.opacity(0.18))
                        } else {
                            Color.clear
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .frame(minHeight: 44)
    }
}

struct ManualAddTextField: View {
    @Binding var manualAddAmount: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        #if os(iOS)
        TextField("0", text: $manualAddAmount)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
            .focused($isTextFieldFocused)
            .frame(width: 140)
            .onChange(of: manualAddAmount) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if let val = Int(filtered), val > 5000 {
                    manualAddAmount = "5000"
                } else if filtered != newValue || filtered.count > 4 {
                    manualAddAmount = String(filtered.prefix(4))
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        #else
        TextField("0", text: $manualAddAmount)
            .focused($isTextFieldFocused)
            .frame(width: 140)
            .onChange(of: manualAddAmount) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if let val = Int(filtered), val > 5000 {
                    manualAddAmount = "5000"
                } else if filtered != newValue || filtered.count > 4 {
                    manualAddAmount = String(filtered.prefix(4))
                }
            }
        #endif
    }
}
