import SwiftUI
import SwiftData

struct DhikrDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allDailyRecords: [DailyRecord]
    
    let type: DhikrType
    let titleAr: String
    let titleDe: String
    let transliteration: String
    
    @State private var selectedIndex: Int = 0
    
    enum CounterState { case idle, running, paused }
    @State private var counterState: CounterState = .idle
    @State private var sessionCount = 0
    @State private var autoTimer: Timer? = nil
    
    @State private var showMashaAllah = false
    @State private var showResetToast = false
    @State private var isPulsing = false
    @State private var flashGreen = false
    
    @State private var showStopSessionSheet = false
    @State private var showManualAddAlert = false
    @State private var manualAddAmount = ""
    @State private var showInfoSheet = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
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
        switch type {
        case .istighfar: return settings.istighfarGoal
        case .salawat: return settings.salawatGoal
        case .subhanAllah: return settings.subhanAllahGoal
        case .alhamdulillah: return settings.alhamdulillahGoal
        case .allahuAkbar: return settings.allahuAkbarGoal
        }
    }
    
    private var currentTempo: Int {
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { return baseTempo }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: return settings.istighfarKurzBpm == 0 ? baseTempo : settings.istighfarKurzBpm
            case .extended: return settings.istighfarExtendedBpm == 0 ? baseTempo : settings.istighfarExtendedBpm
            case .gewaltig: return settings.istighfarGewaltigBpm == 0 ? baseTempo : settings.istighfarGewaltigBpm
            case .lang: return settings.istighfarLangBpm == 0 ? baseTempo : settings.istighfarLangBpm
            case .quranisch: return settings.istighfarQuranischBpm == 0 ? baseTempo : settings.istighfarQuranischBpm
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { return baseTempo }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .kurz: return settings.salawatKurzBpm == 0 ? baseTempo : settings.salawatKurzBpm
            case .lang: return settings.salawatLangBpm == 0 ? baseTempo : settings.salawatLangBpm
            }
        case .subhanAllah: return settings.subhanAllahPerMinute == 0 ? baseTempo : settings.subhanAllahPerMinute
        case .alhamdulillah: return settings.alhamdulillahPerMinute == 0 ? baseTempo : settings.alhamdulillahPerMinute
        case .allahuAkbar: return settings.allahuAkbarPerMinute == 0 ? baseTempo : settings.allahuAkbarPerMinute
        }
    }
    
    private var pageCount: Int {
        switch type {
        case .istighfar: return activeIstighfarCases.count
        case .salawat: return activeSalawatCases.count
        default: return 1
        }
    }
    
    private var localizedTitle: String {
        switch type {
        case .istighfar: return L10n.tr("tasbih_type_istighfar", settings.language)
        case .salawat: return L10n.tr("tasbih_type_salawat", settings.language)
        case .subhanAllah: return "SubhanAllah"
        case .alhamdulillah: return "Alhamdulillah"
        case .allahuAkbar: return "La hawla..."
        }
    }
    
    private func titleArFor(_ index: Int) -> String {
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
        }
    }
    
    private var currentTranslation: String {
        titleDeFor(selectedIndex)
    }
    
    private func transliterationFor(_ index: Int) -> String {
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
    
    var interval: Double { 60.0 / Double(max(1, currentTempo)) }
    
    private var tempoBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(currentTempo) },
            set: { updateTempo(to: Int($0)) }
        )
    }
    
    private var baseTempo: Int {
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { return 45 }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: return 60
            case .extended: return 45
            case .gewaltig: return 20
            case .lang: return 3
            case .quranisch: return 15
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { return 40 }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .kurz: return 40
            case .lang: return 6
            }
        case .subhanAllah: return 30
        case .alhamdulillah: return 20
        case .allahuAkbar: return 30
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
    
    private var fiveStepSliderBinding: Binding<Double> {
        Binding<Double>(
            get: {
                let diff = currentTempo - baseTempo
                let step = Double(diff) / Double(tempoStepSize)
                let stepClamped = min(max(round(step), -2.0), 2.0)
                return stepClamped + 2.0
            },
            set: { newValue in
                let stepFromCenter = Int(round(newValue)) - 2
                let newTempo = max(1, baseTempo + stepFromCenter * tempoStepSize)
                updateTempo(to: newTempo)
            }
        )
    }
    
    private var ringColor: Color {
        switch counterState {
        case .idle: return .gray.opacity(0.5)
        case .running: return Theme.islamicGreen
        case .paused: return .orange
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
            
            VStack(spacing: 30) {
                // Page Indicator at the very top
                if pageCount > 1 {
                    HStack(spacing: 8) {
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
                    }
                    .padding(.top, 8)
                }
                
                // TabView für die Versionen (BPM & Arabischer Text ändern sich, Zähler bleibt unifiziert)
                TabView(selection: $selectedIndex) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        ScrollView {
                            VStack(spacing: 12) {
                                let isLangIstighfar = (type == .istighfar && activeIstighfarCases[index] == .lang)
                                
                                Text(titleArFor(index))
                                    .font(.custom("Geeza Pro", size: isLangIstighfar ? 22 : (type == .istighfar ? 24 : (type == .salawat ? 20 : 32))))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .padding(.horizontal)
                                
                                if settings.language != "ar" {
                                    Text(transliterationFor(index))
                                        .font(isLangIstighfar ? .subheadline : .headline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: (type == .istighfar && selectedIndex == 3) ? 270 : 240)
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

                

                // Main Counter Circle
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(getCurrentCount()) / CGFloat(max(1, currentGoal)))
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    if flashGreen {
                        Circle()
                            .fill(Theme.islamicGreen.opacity(0.25))
                            .transition(.opacity)
                    }
                    
                    // Numerische Fortschrittszahl und Tagesziel im Kreis
                    VStack(spacing: 6) {
                        Text(formatNumber(getCurrentCount()))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatNumber(currentGoal))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                }
                .frame(width: 240, height: 240)
                .contentShape(Circle())
                .onTapGesture {
                    handleCircleTap()
                }
                
                // Kein äußeres Tagesziel-Label mehr, da es jetzt im Kreis platziert ist
                
                Spacer()
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
            
            // Symmetrische Buttons unten
            VStack {
                Spacer()
                HStack {
                    // Links: Stopp-Button
                    Button(action: {
                        handleStopButtonTap()
                    }) {
                        Image(systemName: "square.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    // Rechts: Plus-Button für manuelles Eintragen
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showManualAddAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Theme.islamicGreen)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 24)
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
                        TextField("0", text: $manualAddAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.islamicGreen.opacity(0.4), lineWidth: 1.5)
                            )
                            .focused($isTextFieldFocused)
                            .frame(width: 140)
                            .onAppear {
                                isTextFieldFocused = true
                            }
                        
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
            
            // Custom-Overlay für Beenden (minimalistisches Stop-Menü)
            if showStopSessionSheet {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showStopSessionSheet = false
                            }
                        }
                    
                    VStack(spacing: 12) {
                        // 100% Button (Oben)
                        Button(action: {
                            saveSession(discountPercent: 0)
                            withAnimation(.easeOut(duration: 0.2)) {
                                showStopSessionSheet = false
                            }
                        }) {
                            Text("100%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.islamicGreen)
                                .cornerRadius(14)
                                .shadow(color: Theme.islamicGreen.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        // Prozent-Leiste (Darunter)
                        HStack(spacing: 8) {
                            let discounts = [5, 10, 20, 30]
                            ForEach(discounts, id: \.self) { pct in
                                Button(action: {
                                    saveSession(discountPercent: pct)
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showStopSessionSheet = false
                                    }
                                }) {
                                    Text("-\(pct)%")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                        .shadow(color: Color.red.opacity(0.2), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(width: 240)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showInfoSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(Theme.islamicGreen)
                        .font(.title3)
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
        }
        .sheet(isPresented: $showInfoSheet) {
            TranslationSheet(
                language: settings.language,
                title: localizedTitle,
                translation: currentTranslation,
                sliderValue: fiveStepSliderBinding
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleCircleTap() {
        let useAuto = settings.adhkarAutoCount
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
    
    private func handleStopButtonTap() {
        if counterState == .running {
            counterState = .paused
            pauseTimer()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showStopSessionSheet = true
        }
    }
    
    private func startTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
        autoTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { _ in
            DispatchQueue.main.async {
                incrementCount(isAuto: true)
            }
        }
    }
    
    private func pauseTimer() {
        autoTimer?.invalidate()
        autoTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func saveSession(discountPercent: Int) {
        if discountPercent > 0 {
            let removeDiff: Int
            if discountPercent == 100 {
                removeDiff = sessionCount
            } else {
                removeDiff = Int(round(Double(sessionCount) * Double(discountPercent) / 100.0))
            }
            applyCorrection(removeDiff: removeDiff)
        }
        
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
    }
    
    private func applyCorrection(removeDiff: Int) {
        guard removeDiff > 0 else { return }
        let record = todayRecord
        switch type {
        case .istighfar: record.istighfarCount = max(0, record.istighfarCount - removeDiff)
        case .salawat: record.salawatCount = max(0, record.salawatCount - removeDiff)
        case .subhanAllah: record.subhanAllahCount = max(0, record.subhanAllahCount - removeDiff)
        case .alhamdulillah: record.alhamdulillahCount = max(0, record.alhamdulillahCount - removeDiff)
        case .allahuAkbar: record.allahuAkbarCount = max(0, record.allahuAkbarCount - removeDiff)
        }
        try? modelContext.save()
    }
    
    private func getCurrentCount() -> Int {
        let record = todayRecord
        switch type {
        case .istighfar: return record.istighfarCount
        case .salawat: return record.salawatCount
        case .subhanAllah: return record.subhanAllahCount
        case .alhamdulillah: return record.alhamdulillahCount
        case .allahuAkbar: return record.allahuAkbarCount
        }
    }
    
    private func dismissManualAdd() {
        withAnimation(.easeOut(duration: 0.2)) {
            showManualAddAlert = false
        }
        manualAddAmount = ""
        isTextFieldFocused = false
    }
    
    private func addManualCount(_ amount: Int) {
        let record = todayRecord
        switch type {
        case .istighfar: record.istighfarCount += amount
        case .salawat: record.salawatCount += amount
        case .subhanAllah: record.subhanAllahCount += amount
        case .alhamdulillah: record.alhamdulillahCount += amount
        case .allahuAkbar: record.allahuAkbarCount += amount
        }
        checkCompletion()
        try? modelContext.save()
    }
    
    private func incrementCount(isAuto: Bool = false) {
        let record = todayRecord
        
        UIImpactFeedbackGenerator(style: isAuto ? .light : .medium)
            .impactOccurred()
        
        switch type {
        case .istighfar: record.istighfarCount += 1
        case .salawat: record.salawatCount += 1
        case .subhanAllah: record.subhanAllahCount += 1
        case .alhamdulillah: record.alhamdulillahCount += 1
        case .allahuAkbar: record.allahuAkbarCount += 1
        }
        
        if isAuto {
            sessionCount += 1
            
            withAnimation(.easeIn(duration: 0.08)) {
                flashGreen = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.12)) {
                    flashGreen = false
                }
            }
        }
        
        checkCompletion()
        try? modelContext.save()
    }
    
    private func checkCompletion() {
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
    
    private func updateTempo(to newValue: Int) {
        let currentStatus = counterState
        if currentStatus == .running {
            pauseTimer()
        }
        
        switch type {
        case .istighfar:
            guard selectedIndex < activeIstighfarCases.count else { break }
            let form = activeIstighfarCases[selectedIndex]
            switch form {
            case .kurz: settings.istighfarKurzBpm = newValue
            case .extended: settings.istighfarExtendedBpm = newValue
            case .gewaltig: settings.istighfarGewaltigBpm = newValue
            case .lang: settings.istighfarLangBpm = newValue
            case .quranisch: settings.istighfarQuranischBpm = newValue
            }
        case .salawat:
            guard selectedIndex < activeSalawatCases.count else { break }
            let form = activeSalawatCases[selectedIndex]
            switch form {
            case .kurz: settings.salawatKurzBpm = newValue
            case .lang: settings.salawatLangBpm = newValue
            }
        case .subhanAllah: settings.subhanAllahPerMinute = newValue
        case .alhamdulillah: settings.alhamdulillahPerMinute = newValue
        case .allahuAkbar: settings.allahuAkbarPerMinute = newValue
        }
        try? modelContext.save()
        
        if currentStatus == .running {
            startTimer()
        }
    }
}

struct TranslationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let language: String
    let title: String
    let translation: String
    let sliderValue: Binding<Double>
    
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
                        
                        // Tempo-Regler
                        HStack(spacing: 12) {
                            Image(systemName: "tortoise")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            Slider(
                                value: sliderValue,
                                    in: 0...4,
                                    step: 1
                            )
                            .tint(Theme.islamicGreen)
                            
                            Image(systemName: "hare")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.tr("done", language)) {
                        dismiss()
                    }
                    .foregroundColor(Theme.islamicGreen)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
