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
        let list: [AdhkarItem]
        switch type {
        case .morning: list = morgenAdhkar
        case .evening: list = abendAdhkar
        case .sleep: list = schlafAdhkar
        }
        self._localAdhkarList = State(initialValue: list)
    }
    
    private var language: String {
        settingsList.first?.language ?? "de"
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
                        restoreSessionState(proxy: proxy)
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
        case .morning: return L10n.tr("adhkar_morning", language)
        case .evening: return L10n.tr("adhkar_evening", language)
        case .sleep: return L10n.tr("adhkar_sleep", language)
        }
    }
    
    private func incrementCount(item: AdhkarItem, proxy: ScrollViewProxy, isAuto: Bool = false) {
        let current = counts[item.id] ?? 0
        if current < item.count {
            let next = current + 1
            counts[item.id] = next
            
            if let idx = adhkarList.firstIndex(where: { $0.id == item.id }) {
                lastActiveDhikrIndex = idx
                lastActiveDhikrCount = next
            }
            
            let impact = UIImpactFeedbackGenerator(style: isAuto ? .light : .medium)
            impact.impactOccurred()
            
            if let category = item.linkedTasbihCategory {
                let record = todayRecord
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
                }
                try? modelContext.save()
            }
            
            if next == item.count {
                withAnimation {
                    completedItems.insert(item.id)
                    showMashaAllah = item.id
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showMashaAllah = nil
                    }
                    // Auto scroll to next
                    if let index = adhkarList.firstIndex(where: { $0.id == item.id }) {
                        if index + 1 < adhkarList.count {
                            lastActiveDhikrIndex = index + 1
                            lastActiveDhikrCount = 0
                            withAnimation {
                                proxy.scrollTo(adhkarList[index + 1].id, anchor: .center)
                            }
                        } else if index == adhkarList.count - 1 {
                            // Scroll to bottom button
                            withAnimation {
                                proxy.scrollTo(adhkarList.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func autoCountInterval(for item: AdhkarItem) -> TimeInterval {
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
        case .morning:
            record.morgenAdhkarDone = true
            record.morgenAdhkarTime = now
        case .evening:
            record.abendAdhkarDone = true
            record.abendAdhkarTime = now
        case .sleep:
            record.schlafAdhkarDone = true
            record.schlafAdhkarTime = now
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
    
    private func restoreSessionState(proxy: ScrollViewProxy) {
        if isSessionActive && lastActiveSessionId == type.idStr {
            // Mark earlier items as completed
            for i in 0..<lastActiveDhikrIndex {
                if i < adhkarList.count {
                    let item = adhkarList[i]
                    counts[item.id] = item.count
                    completedItems.insert(item.id)
                }
            }
            // Set current item count
            if lastActiveDhikrIndex < adhkarList.count {
                let currentItem = adhkarList[lastActiveDhikrIndex]
                counts[currentItem.id] = lastActiveDhikrCount
                if lastActiveDhikrCount >= currentItem.count {
                    completedItems.insert(currentItem.id)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        proxy.scrollTo(currentItem.id, anchor: .top)
                    }
                }
            }
        } else {
            // New session
            lastActiveSessionId = type.idStr
            lastActiveDhikrIndex = 0
            lastActiveDhikrCount = 0
            isSessionActive = true
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
    let onIncrement: () -> Void
    let onInfoTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(item.arabic)
                .font(.custom("KFGQPCUthmanicHafs", size: 26))
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
                    if item.count == 1 {
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Theme.islamicGreen : Theme.islamicGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(isActive ? 1.05 : 1.0)
                                .animation(isActive ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isActive)
                            
                            if isActive {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                                    .foregroundColor(Theme.islamicGreen)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.title)
                                    .foregroundColor(isCompleted ? .white : Theme.islamicGreen)
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
        .background(isCompleted ? Theme.islamicGreen.opacity(0.15) : Theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Theme.islamicGreen : Color.clear, lineWidth: 1)
        )
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
                        Toggle(isOn: $item.isMandatory) {
                            Text(L10n.tr("mandatory", language))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .tint(Theme.islamicGreen)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        
                        // 3. Tempo-Regler
                        HStack(spacing: 12) {
                            Image(systemName: "tortoise")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            Slider(
                                value: Binding(
                                    get: { Double(item.customSpeedStep) },
                                    set: { item.customSpeedStep = Int(round($0)) }
                                ),
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
