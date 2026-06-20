import SwiftUI
import SwiftData

struct AdhkarSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allDailyRecords: [DailyRecord]
    @Query private var settingsList: [UserSettings]
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("lastActiveSessionId") private var lastActiveSessionId: String = ""
    @AppStorage("lastActiveDhikrIndex") private var lastActiveDhikrIndex: Int = 0
    @AppStorage("lastActiveDhikrCount") private var lastActiveDhikrCount: Int = 0
    @AppStorage("isSessionActive") private var isSessionActive: Bool = false
    
    let type: AdhkarSessionType
    @State private var counts: [UUID: Int] = [:]
    @State private var completedItems: Set<UUID> = []
    @State private var showMashaAllah: UUID? = nil
    @State private var activeAutoCountItemId: UUID? = nil
    @State private var autoTimer: Timer? = nil
    @State private var selectedInfoItem: AdhkarItem? = nil
    @State private var localAdhkarList: [AdhkarItem]
    
    init(type: AdhkarSessionType) {
        self.type = type
        var list: [AdhkarItem]
        switch type {
        case .sleep: list = schlafAdhkar
        case .morning: list = morgenAdhkar
        case .evening: list = abendAdhkar
        }
        
        // Load custom settings from UserDefaults using German translation text as stable key
        for i in 0..<list.count {
            let item = list[i]
            let text = String(item.german.prefix(30))
            let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
            let keyPrefix = "adhkar_\(safeText)"
            
            if let savedMandatory = UserDefaults.standard.object(forKey: "\(keyPrefix)_mandatory") as? Bool {
                list[i].isMandatory = savedMandatory
            }
            if let savedSpeed = UserDefaults.standard.object(forKey: "\(keyPrefix)_speed") as? Int {
                list[i].customSpeedStep = savedSpeed
            } else {
                let defaultSpeed = UserDefaults.standard.object(forKey: "defaultAdhkarSpeedStep") as? Int ?? 2
                list[i].customSpeedStep = defaultSpeed
            }
        }
        
        self._localAdhkarList = State(initialValue: list)
    }
    
    private var language: String {
        settingsList.first?.language ?? (["de", "en", "ar"].contains(Locale.current.language.languageCode?.identifier ?? "") ? (Locale.current.language.languageCode?.identifier ?? "en") : "en")
    }
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    private var adhkarList: [AdhkarItem] {
        localAdhkarList
    }
    
    private var progressText: String {
        "\(completedItems.count) / \(adhkarList.count)"
    }
    
    private var allMandatoryCompleted: Bool {
        localAdhkarList.allSatisfy { item in
            if item.isMandatory {
                return completedItems.contains(item.id)
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(adhkarList) { item in
                                AdhkarCard(
                                    item: item,
                                    currentCount: counts[item.id] ?? 0,
                                    isCompleted: completedItems.contains(item.id),
                                    showMashaAllah: showMashaAllah == item.id,
                                    language: language,
                                    isActive: activeAutoCountItemId == item.id,
                                    useAuto: settingsList.first?.adhkarAutoCount ?? true,
                                    onIncrement: {
                                        let useAuto = settingsList.first?.adhkarAutoCount ?? true
                                        if useAuto {
                                            toggleAutoCount(item: item, proxy: proxy)
                                        } else {
                                            incrementCount(item: item, proxy: proxy)
                                        }
                                    },
                                    onInfoTap: {
                                        selectedInfoItem = item
                                    }
                                )
                                .id(item.id)
                            }
                            
                            Button(action: finishSession) {
                                Text(L10n.tr("alhamdulillah_finished", language))
                                    .font(.headline)
                                    .foregroundColor(allMandatoryCompleted ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(allMandatoryCompleted ? Theme.islamicGreen : Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                                    .padding(.top, 20)
                            }
                            .disabled(!allMandatoryCompleted)
                            .padding(.bottom, 50)
                        }
                        .padding()
                    }
                    .onAppear {
                        loadProgressFromDatabase(proxy: proxy)
                    }
                }
                
                if let _ = showMashaAllah {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    Text("ما شاء الله")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.islamicGreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(sessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { cancelSession() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(progressText)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedInfoItem) { item in
                if let index = localAdhkarList.firstIndex(where: { $0.id == item.id }) {
                    AdhkarInfoModalView(item: $localAdhkarList[index], language: language)
                }
            }
            .onDisappear {
                stopAutoCount()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    isSessionActive = true
                    lastActiveSessionId = type.idStr
                }
            }
        }
    }
    
    private var sessionTitle: String {
        switch type {
        case .sleep: return L10n.tr("adhkar_sleep", language)
        case .morning: return L10n.tr("adhkar_morning", language)
        case .evening: return L10n.tr("adhkar_evening", language)
        }
    }
    
    private func incrementCount(item: AdhkarItem, proxy: ScrollViewProxy, isAuto: Bool = false) {
        let current = counts[item.id] ?? 0
        if current < item.count {
            let next = current + 1
            counts[item.id] = next
            
            // In SwiftData / DailyRecord persistieren
            let record = todayRecord
            let key = safeKey(for: item)
            record.setAdhkarCount(for: key, count: next)
            
            if let idx = adhkarList.firstIndex(where: { $0.id == item.id }) {
                lastActiveDhikrIndex = idx
                lastActiveDhikrCount = next
            }
            
            let impact = UIImpactFeedbackGenerator(style: isAuto ? .light : .medium)
            impact.impactOccurred()
            
            if let category = item.linkedTasbihCategory {
                switch category {
                case .istighfar:
                    record.istighfarCount += 1
                case .salawat:
                    record.salawatCount += 1
                case .subhanAllah:
                    record.subhanAllahCount += 1
                case .alhamdulillah:
                    record.alhamdulillahCount += 1
                case .allahuAkbar:
                    record.allahuAkbarCount += 1
                case .laIlahaIllallah:
                    record.laIlahaIllallahCount += 1
                }
            }
            
            // Sofortige Persistenz erzwingen
            try? modelContext.save()
            
            if next == item.count {
                withAnimation {
                    completedItems.insert(item.id)
                    showMashaAllah = item.id
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showMashaAllah = nil
                    }
                    
                    let settings = settingsList.first ?? UserSettings()
                    
                    if let index = adhkarList.firstIndex(where: { $0.id == item.id }) {
                        if settings.adhkarAutoCount && settings.adhkarAutoAdvance {
                            // Finde das nächste unvollständige Item
                            var nextIndex = index + 1
                            while nextIndex < adhkarList.count && completedItems.contains(adhkarList[nextIndex].id) {
                                nextIndex += 1
                            }
                            
                            if nextIndex < adhkarList.count {
                                let nextItem = adhkarList[nextIndex]
                                lastActiveDhikrIndex = nextIndex
                                lastActiveDhikrCount = todayRecord.getAdhkarCount(for: safeKey(for: nextItem))
                                withAnimation {
                                    proxy.scrollTo(nextItem.id, anchor: .center)
                                }
                                
                                // Starte den Auto-Count für das nächste Item
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    toggleAutoCount(item: nextItem, proxy: proxy)
                                }
                            } else {
                                // Kein weiteres unvollständiges Item vorhanden
                                withAnimation {
                                    proxy.scrollTo(adhkarList.last?.id, anchor: .bottom)
                                }
                            }
                        } else {
                            // Normales Verhalten (einfach zum unmittelbar nächsten scrollen)
                            if index + 1 < adhkarList.count {
                                let nextItem = adhkarList[index + 1]
                                lastActiveDhikrIndex = index + 1
                                lastActiveDhikrCount = todayRecord.getAdhkarCount(for: safeKey(for: nextItem))
                                withAnimation {
                                    proxy.scrollTo(nextItem.id, anchor: .center)
                                }
                            } else if index == adhkarList.count - 1 {
                                withAnimation {
                                    proxy.scrollTo(adhkarList.last?.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func autoCountInterval(for item: AdhkarItem) -> TimeInterval {
        if let quick = item.quickInterval, let normal = item.normalInterval {
            let diff = (normal - quick) / 2.0
            switch item.customSpeedStep {
            case 0: return normal + 2.0 * diff // Stufe 1: Langsam
            case 1: return normal + diff       // Stufe 2: Langsam
            case 2: return normal              // Stufe 3: Normal (getrackt)
            case 3: return normal - diff       // Stufe 4: Schnell
            case 4: return quick               // Stufe 5: Schnell (getrackt)
            default: return normal
            }
        }
        
        let base = item.defaultInterval
        switch item.customSpeedStep {
        case 0: return base * 1.30 // Langsamer
        case 1: return base * 1.15 // Leicht langsamer
        case 2: return base        // Standard
        case 3: return base * 0.85 // Leicht schneller
        case 4: return base * 0.70 // Schneller
        default: return base
        }
    }

    private func toggleAutoCount(item: AdhkarItem, proxy: ScrollViewProxy) {
        if activeAutoCountItemId == item.id {
            stopAutoCount()
        } else {
            stopAutoCount()
            activeAutoCountItemId = item.id
            UIApplication.shared.isIdleTimerDisabled = true
            
            let interval = autoCountInterval(for: item)
            
            if interval <= 0.0 {
                // Sonderfall: Sofort erledigt, keine Verzögerung, Auto-Advance greift hier sofort bei Trigger
                counts[item.id] = item.count
                todayRecord.setAdhkarCount(for: safeKey(for: item), count: item.count)
                completedItems.insert(item.id)
                try? modelContext.save()
                
                stopAutoCount()
                
                let settings = settingsList.first ?? UserSettings()
                if settings.adhkarAutoCount && settings.adhkarAutoAdvance {
                    if let index = adhkarList.firstIndex(where: { $0.id == item.id }) {
                        var nextIndex = index + 1
                        while nextIndex < adhkarList.count && completedItems.contains(adhkarList[nextIndex].id) {
                            nextIndex += 1
                        }
                        
                        if nextIndex < adhkarList.count {
                            let nextItem = adhkarList[nextIndex]
                            lastActiveDhikrIndex = nextIndex
                            lastActiveDhikrCount = todayRecord.getAdhkarCount(for: safeKey(for: nextItem))
                            withAnimation {
                                proxy.scrollTo(nextItem.id, anchor: .center)
                            }
                            
                            // Nächstes Item sofort im Main-Thread starten
                            DispatchQueue.main.async {
                                toggleAutoCount(item: nextItem, proxy: proxy)
                            }
                        } else {
                            withAnimation {
                                proxy.scrollTo(adhkarList.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                return
            }
            
            autoTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                DispatchQueue.main.async {
                    if activeAutoCountItemId == item.id {
                        incrementCount(item: item, proxy: proxy, isAuto: true)
                        let current = counts[item.id] ?? 0
                        if current >= item.count {
                            stopAutoCount()
                        }
                    } else {
                        stopAutoCount()
                    }
                }
            }
        }
    }
    
    private func stopAutoCount() {
        autoTimer?.invalidate()
        autoTimer = nil
        activeAutoCountItemId = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func finishSession() {
        let record = todayRecord
        let now = Date()
        switch type {
        case .sleep:
            record.schlafAdhkarDone = true
            record.schlafAdhkarTime = now
        case .morning:
            record.morgenAdhkarDone = true
            record.morgenAdhkarTime = now
        case .evening:
            record.abendAdhkarDone = true
            record.abendAdhkarTime = now
        }
        try? modelContext.save()
        clearSessionState()
        dismiss()
    }
    
    private func cancelSession() {
        clearSessionState()
        dismiss()
    }
    
    private func clearSessionState() {
        isSessionActive = false
        lastActiveSessionId = ""
        lastActiveDhikrIndex = 0
        lastActiveDhikrCount = 0
    }
    
    private func safeKey(for item: AdhkarItem) -> String {
        let text = String(item.german.prefix(30))
        return text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
    
    private func loadProgressFromDatabase(proxy: ScrollViewProxy) {
        let record = todayRecord
        
        for item in adhkarList {
            let key = safeKey(for: item)
            let dbCount = record.getAdhkarCount(for: key)
            counts[item.id] = dbCount
            if dbCount >= item.count {
                completedItems.insert(item.id)
            }
        }
        
        // Finde das erste unvollständige Item, um dorthin zu scrollen
        if let firstUncompletedIndex = adhkarList.firstIndex(where: { !completedItems.contains($0.id) }) {
            let currentItem = adhkarList[firstUncompletedIndex]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    proxy.scrollTo(currentItem.id, anchor: .center)
                }
            }
        }
    }
}

struct AdhkarCard: View {
    let item: AdhkarItem
    let currentCount: Int
    let isCompleted: Bool
    let showMashaAllah: Bool
    let language: String
    let isActive: Bool
    let useAuto: Bool
    let onIncrement: () -> Void
    let onInfoTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(item.arabic)
                .font(.system(size: 26))
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Transliteration
            if language != "ar" && !item.transliteration.isEmpty {
                Text(item.transliteration)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack {
                Spacer()
                
                Button(action: onIncrement) {
                    if isCompleted {
                        ZStack {
                            Circle()
                                .fill(Theme.islamicGreen)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    } else if item.count == 1 {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(isActive ? 1.05 : 1.0)
                                .animation(isActive ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isActive)
                            
                            if isActive {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.islamicGreen)
                            } else {
                                if useAuto {
                                    Image(systemName: "play.fill")
                                        .font(.title)
                                        .foregroundColor(Theme.islamicGreen.opacity(0.7))
                                        .offset(x: 2)
                                } else {
                                    Image(systemName: "plus")
                                        .font(.title)
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                        }
                    } else {
                        ZStack {
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(currentCount) / CGFloat(item.count))
                                .stroke(Theme.islamicGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .scaleEffect(isActive ? 1.05 : 1.0)
                                .animation(isActive ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isActive)
                            
                            VStack(spacing: 0) {
                                if isActive {
                                    Image(systemName: "pause.fill")
                                        .font(.title2)
                                        .foregroundColor(Theme.islamicGreen)
                                } else {
                                    Text("\(currentCount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                Text("/ \(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isCompleted)
                
                Spacer()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .opacity(isCompleted ? 0.45 : 1.0)
        .overlay(
            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .padding(14)
            }
            .buttonStyle(PlainButtonStyle()),
            alignment: .topTrailing
        )
        .scaleEffect(showMashaAllah ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showMashaAllah)
    }
}

struct AdhkarInfoModalView: View {
    @Binding var item: AdhkarItem
    let language: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Übersetzungen (Deutsch & Englisch)
                        let germanTranslation = item.german
                        let englishTranslation = item.translation(for: "en")
                        
                        if language == "de" && !germanTranslation.isEmpty {
                            Text(germanTranslation)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                        }
                        
                        if language == "en" && !englishTranslation.isEmpty {
                            Text(englishTranslation)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                        }
                        
                        // 2. Pflicht vs. Optional (Toggle)
                        Toggle(isOn: Binding(
                            get: { item.isMandatory },
                            set: { newValue in
                                item.isMandatory = newValue
                                let text = String(item.german.prefix(30))
                                let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                UserDefaults.standard.set(newValue, forKey: "adhkar_\(safeText)_mandatory")
                            }
                        )) {
                            Text(L10n.tr("mandatory", language))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .tint(Theme.islamicGreen)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        
                        // 3. Tempo-Regler
                        VStack(spacing: 8) {
                            HStack {
                                Text(language == "de" ? "Geschwindigkeit" : "Speed")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(
                                    item.customSpeedStep == 0 ? (language == "de" ? "Sehr langsam" : "Very slow") :
                                    item.customSpeedStep == 1 ? (language == "de" ? "Langsam" : "Slow") :
                                    item.customSpeedStep == 2 ? (language == "de" ? "Normal" : "Normal") :
                                    item.customSpeedStep == 3 ? (language == "de" ? "Schnell" : "Fast") :
                                    (language == "de" ? "Sehr schnell" : "Very fast")
                                )
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.islamicGreen)
                            }
                            .padding(.horizontal, 4)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    if item.customSpeedStep > 0 {
                                        let intVal = item.customSpeedStep - 1
                                        item.customSpeedStep = intVal
                                        let text = String(item.german.prefix(30))
                                        let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                        UserDefaults.standard.set(intVal, forKey: "adhkar_\(safeText)_speed")
                                    }
                                }) {
                                    Image(systemName: "tortoise.fill")
                                        .foregroundColor(item.customSpeedStep == 0 ? .gray.opacity(0.3) : .gray)
                                        .font(.body)
                                        .frame(width: 32, height: 32)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(item.customSpeedStep) },
                                        set: { newValue in
                                            let intVal = Int(round(newValue))
                                            item.customSpeedStep = intVal
                                            let text = String(item.german.prefix(30))
                                            let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                            UserDefaults.standard.set(intVal, forKey: "adhkar_\(safeText)_speed")
                                        }
                                    ),
                                    in: 0...4,
                                    step: 1
                                )
                                .tint(Theme.islamicGreen)
                                .accentColor(Theme.islamicGreen)
                                .padding(.vertical, 8)
                                
                                Button(action: {
                                    if item.customSpeedStep < 4 {
                                        let intVal = item.customSpeedStep + 1
                                        item.customSpeedStep = intVal
                                        let text = String(item.german.prefix(30))
                                        let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                        UserDefaults.standard.set(intVal, forKey: "adhkar_\(safeText)_speed")
                                    }
                                }) {
                                    Image(systemName: "hare.fill")
                                        .foregroundColor(item.customSpeedStep == 4 ? .gray.opacity(0.3) : .gray)
                                        .font(.body)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Adhkar Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(Theme.islamicGreen)
                    .fontWeight(.bold)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
