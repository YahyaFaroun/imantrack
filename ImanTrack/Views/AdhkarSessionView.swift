import SwiftUI
#if os(iOS) && !SKIP
import SwiftData
#endif

struct AdhkarSessionView: View {
    @Environment(\.modelContext) var modelContext
    @Query var allDailyRecords: [DailyRecord]
    @Query var settingsList: [UserSettings]
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("lastActiveSessionId") var lastActiveSessionId: String = ""
    @AppStorage("lastActiveDhikrIndex") var lastActiveDhikrIndex: Int = 0
    @AppStorage("lastActiveDhikrCount") var lastActiveDhikrCount: Int = 0
    @AppStorage("isSessionActive") var isSessionActive: Bool = false
    let type: AdhkarSessionType
    @State var counts: [UUID: Int] = [:]
    @State var completedItems: Set<UUID> = []
    @State var showMashaAllah: UUID? = nil
    @State var activeAutoCountItemId: UUID? = nil
    @State var autoTimer: Timer? = nil
    @State var selectedInfoItem: AdhkarItem? = nil
    @State var showAlMulkReader: Bool = false
    @State var mulkItemToComplete: AdhkarItem? = nil
    @State var localAdhkarList: [AdhkarItem]
    @State var isEditMode: Bool = false
    @StateObject private var audioPlayer = AdhkarAudioPlayer.shared
    @State private var isVoiceMode: Bool = false
    
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
                let defaultSpeed = UserDefaults.standard.object(forKey: "defaultAdhkarSpeedStep") as? Int ?? 1
                list[i].customSpeedStep = defaultSpeed
            }
            
            if list[i].audioFileName == nil || list[i].audioFileName?.isEmpty == true {
                list[i].audioFileName = "\(type.idStr)_\(i + 1)"
            }
        }
        
        let loadedOrder = AdhkarSessionView.loadCustomOrderStatic(type: type, list: list)
        self._localAdhkarList = State(initialValue: loadedOrder)
    }
    
    private static func itemOrderKeyStatic(for item: AdhkarItem) -> String {
        let g = item.german.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let t = item.transliteration.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return "\(item.count)_\(String((g + t).prefix(40)))"
    }

    private static func loadCustomOrderStatic(type: AdhkarSessionType, list: [AdhkarItem]) -> [AdhkarItem] {
        let key = "adhkar_custom_order_\(type.idStr)"
        guard let savedOrder = UserDefaults.standard.stringArray(forKey: key), !savedOrder.isEmpty else {
            return list
        }
        var result: [AdhkarItem] = []
        var remaining = list
        for orderKey in savedOrder {
            if let idx = remaining.firstIndex(where: { itemOrderKeyStatic(for: $0) == orderKey }) {
                result.append(remaining.remove(at: idx))
            }
        }
        result.append(contentsOf: remaining)
        return result
    }

    private func saveCustomOrder() {
        let key = "adhkar_custom_order_\(type.idStr)"
        let orderKeys = localAdhkarList.map { AdhkarSessionView.itemOrderKeyStatic(for: $0) }
        UserDefaults.standard.set(orderKeys, forKey: key)
    }

    private func moveItemUp(index: Int) {
        guard index > 0 else { return }
        #if os(iOS) && !SKIP
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            localAdhkarList.swapAt(index, index - 1)
        }
        saveCustomOrder()
    }

    private func moveItemDown(index: Int) {
        guard index < localAdhkarList.count - 1 else { return }
        #if os(iOS) && !SKIP
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            localAdhkarList.swapAt(index, index + 1)
        }
        saveCustomOrder()
    }
    
    private var language: String {
        settingsList.first?.language ?? (["de", "en", "ar", "tr", "id", "ms", "fr", "es", "ur", "ru", "bn"].contains(Locale.current.language.languageCode?.identifier ?? "") ? (Locale.current.language.languageCode?.identifier ?? "en") : "en")
    }
    
    @StateObject var solarManager = LocationAndSolarManager.shared
    
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
    
    private var adhkarState: AdhkarState {
        getAdhkarState(type: type)
    }
    
    private var isTrackingAllowed: Bool {
        adhkarState == .active
    }


    private var isSessionAlreadyDone: Bool {
        switch type {
        case .sleep: return todayRecord.schlafAdhkarDone
        case .morning: return todayRecord.morgenAdhkarDone
        case .evening: return todayRecord.abendAdhkarDone
        }
    }
    
    private var hasSnapshot: Bool {
        todayRecord.getAdhkarSnapshot(for: type.idStr) != nil
    }
    
    private var canUndoCompletion: Bool {
        isSessionAlreadyDone && hasSnapshot
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if type == .evening, let sec = solarManager.maghribCountdownSeconds {
                                MaghribCountdownBanner(seconds: sec, language: language)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            if isEditMode {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        .foregroundColor(Theme.islamicGreen)
                                    Text(L10n.tr("adhkar_edit_mode_active", language))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.islamicGreen)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.islamicGreen.opacity(0.12))
                                .cornerRadius(20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            if adhkarState != .future {
                                if isSessionAlreadyDone {
                                    if canUndoCompletion {
                                        Button(action: {
                                            #if os(iOS) && !SKIP
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
                                            impact.impactOccurred()
                                            #endif
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                markAsUncompleted()
                                            }
                                        }) {
                                            VStack(spacing: 3) {
                                                Text(L10n.tr("adhkar_read_done", language))
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text(L10n.tr("adhkar_tap_to_undo", language))
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .opacity(0.9)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Theme.islamicGreen)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } else {
                                    Button(action: {
                                        #if os(iOS) && !SKIP
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        #endif
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            markAllAsCompleted()
                                        }
                                    }) {
                                        let isExpired = (adhkarState == .expired)
                                        Text(L10n.tr("adhkar_already_read_prompt", language))
                                            .font(isExpired ? .subheadline : .footnote)
                                            .fontWeight(isExpired ? .medium : .regular)
                                            .foregroundColor(isExpired ? .primary : .secondary)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, isExpired ? 10 : 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isExpired ? Color.gray.opacity(0.16) : Color.gray.opacity(0.08))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(isExpired ? Color.secondary.opacity(0.35) : Color.gray.opacity(0.2), lineWidth: isExpired ? 1.0 : 0.8)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            ForEach(Array(adhkarList.enumerated()), id: \.element.id) { index, item in
                                let isMulkItem = item.german.contains("Al-Mulk") || item.arabic.contains("الْمُلْكِ")
                                AdhkarCard(
                                    item: item,
                                    currentCount: counts[item.id] ?? 0,
                                    isCompleted: completedItems.contains(item.id),
                                    showMashaAllah: showMashaAllah == item.id,
                                    language: language,
                                    showTransliteration: settingsList.first?.showTransliteration ?? true,
                                    isActive: activeAutoCountItemId == item.id,
                                    useAuto: settingsList.first?.adhkarAutoCount ?? true,
                                    isTrackingAllowed: isTrackingAllowed,
                                    isEditMode: isEditMode,
                                    isFirstInList: index == 0,
                                    isLastInList: index == adhkarList.count - 1,
                                    isVoiceMode: isVoiceMode,
                                    audioProgress: audioPlayer.activeItemId == item.id ? audioPlayer.progress : 0.0,
                                    onIncrement: {
                                        if isVoiceMode {
                                            toggleVoicePlayback(item: item, proxy: proxy)
                                        } else {
                                            let useAuto = settingsList.first?.adhkarAutoCount ?? true
                                            if useAuto {
                                                toggleAutoCount(item: item, proxy: proxy)
                                            } else {
                                                incrementCount(item: item, proxy: proxy)
                                            }
                                        }
                                    },
                                    onInfoTap: {
                                        selectedInfoItem = item
                                    },
                                    onOpenReader: isMulkItem ? {
                                        mulkItemToComplete = item
                                        showAlMulkReader = true
                                    } : nil,
                                    onLongPress: {
                                        #if os(iOS) && !SKIP
                                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                                        impact.impactOccurred()
                                        #endif
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            isEditMode = true
                                        }
                                    },
                                    onMoveUp: {
                                        moveItemUp(index: index)
                                    },
                                    onMoveDown: {
                                        moveItemDown(index: index)
                                    }
                                )
                                .id(item.id)
                            }
                            
                            if isSessionAlreadyDone {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(L10n.tr("alhamdulillah_finished", language))
                                }
                                .font(.headline)
                                .foregroundColor(Theme.islamicGreen)
                                .padding(.top, 20)
                                .padding(.bottom, 50)
                            } else if isTrackingAllowed {
                                Button(action: finishSession) {
                                    HStack(spacing: 8) {
                                        Text(L10n.tr("alhamdulillah_finished", language))
                                    }
                                    .font(.headline)
                                    .foregroundColor(allMandatoryCompleted ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(allMandatoryCompleted ? Theme.islamicGreen : Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                                    .padding(.top, 20)
                                }
                                .disabled(!allMandatoryCompleted)
                                .padding(.bottom, 50)
                            } else {
                                Color.clear
                                    .frame(height: 40)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        loadProgressFromDatabase(proxy: proxy)
                        if let s = settingsList.first {
                            isVoiceMode = s.adhkarVoiceEnabled
                        } else {
                            isVoiceMode = UserDefaults.standard.bool(forKey: "adhkarVoiceEnabled")
                        }
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        audioPlayer.stop()
                        cancelSession()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditMode {
                        Button(action: {
                            #if os(iOS) && !SKIP
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            #endif
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                isEditMode = false
                            }
                            saveCustomOrder()
                        }) {
                            Text(L10n.tr("done", language))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Theme.islamicGreen)
                                .cornerRadius(14)
                        }
                    } else if isTrackingAllowed {
                        HStack(spacing: 12) {
                            Button(action: {
                                #if os(iOS) && !SKIP
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #endif
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    isVoiceMode.toggle()
                                    if !isVoiceMode {
                                        audioPlayer.stop()
                                        activeAutoCountItemId = nil
                                    }
                                }
                            }) {
                                Image(systemName: isVoiceMode ? "speaker.wave.2.fill" : "speaker.slash")
                                    .font(.subheadline)
                                    .foregroundColor(isVoiceMode ? Theme.islamicGreen : .gray)
                                    .padding(6)
                                    .background(isVoiceMode ? Theme.islamicGreen.opacity(0.12) : Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            Text(progressText)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            #if os(iOS)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .sheet(item: $selectedInfoItem) { item in
                if let index = localAdhkarList.firstIndex(where: { $0.id == item.id }) {
                    AdhkarInfoModalView(item: $localAdhkarList[index], language: language)
                }
            }
            .sheet(isPresented: $showAlMulkReader) {
                AlMulkReaderView(onComplete: {
                    if let item = mulkItemToComplete {
                        incrementCount(item: item)
                    }
                })
            }

            .onDisappear {
                stopAutoCount()
                audioPlayer.stop()
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
    
    private func incrementCount(item: AdhkarItem, proxy: ScrollViewProxy? = nil, isAuto: Bool = false) {
        guard item.isMandatory else { return }
        let current = counts[item.id] ?? 0
        if current < item.count {
            let next = current + 1
            counts[item.id] = next
            
            // In SwiftData / DailyRecord persistieren
            let record = todayRecord
            let key = safeKey(for: item)
            record.setAdhkarCount(for: key, count: next)
            record.clearAdhkarSnapshot(for: type.idStr)
            
            if let idx = adhkarList.firstIndex(where: { $0.id == item.id }) {
                lastActiveDhikrIndex = idx
                lastActiveDhikrCount = next
            }
            
            #if os(iOS) && !SKIP
            let impact = UIImpactFeedbackGenerator(style: isAuto ? .light : .medium)
            impact.impactOccurred()
            #endif
            
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
                
                // Sobald alle Pflicht-Items erledigt sind, sofort die Gesamtsession als Done speichern
                if allMandatoryCompleted {
                    let record = todayRecord
                    let now = Date()
                    switch type {
                    case .sleep:
                        record.schlafAdhkarDone = true
                        if record.schlafAdhkarTime == nil { record.schlafAdhkarTime = now }
                    case .morning:
                        record.morgenAdhkarDone = true
                        if record.morgenAdhkarTime == nil { record.morgenAdhkarTime = now }
                    case .evening:
                        record.abendAdhkarDone = true
                        if record.abendAdhkarTime == nil { record.abendAdhkarTime = now }
                    }
                    try? modelContext.save()
                    AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showMashaAllah = nil
                    }
                    if isVoiceMode {
                        if audioPlayer.activeItemId != item.id {
                            let settings = settingsList.first
                            if settings?.adhkarAutoAdvance == true {
                                advanceToNextItem(after: item, proxy: proxy, isVoice: true)
                            }
                        }
                        return
                    }
                    let settings = settingsList.first
                    
                    if let index = adhkarList.firstIndex(where: { $0.id == item.id }) {
                        if settings?.adhkarAutoCount == true && settings?.adhkarAutoAdvance == true {
                            advanceToNextItem(after: item, proxy: proxy, isVoice: false)
                        } else {
                            // Normales Verhalten (einfach zum unmittelbar nächsten scrollen)
                            if index + 1 < adhkarList.count {
                                let nextItem = adhkarList[index + 1]
                                lastActiveDhikrIndex = index + 1
                                lastActiveDhikrCount = todayRecord.getAdhkarCount(for: safeKey(for: nextItem))
                                withAnimation {
                                    proxy?.scrollTo(nextItem.id, anchor: .center)
                                }
                            } else if index == adhkarList.count - 1 {
                                withAnimation {
                                    proxy?.scrollTo(adhkarList.last?.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func autoCountInterval(for item: AdhkarItem) -> TimeInterval {
        let normalVal = item.normalInterval ?? item.defaultInterval
        let slowVal = item.slowInterval ?? (normalVal * 1.184)
        let quickVal = item.quickInterval ?? (normalVal * 0.816)
        
        switch item.customSpeedStep {
        case 0: return slowVal                          // Langsam
        case 1: return normalVal                        // Normal
        case 2: return quickVal                         // Schnell
        default: return normalVal
        }
    }
    
    private func advanceToNextItem(after item: AdhkarItem, proxy: ScrollViewProxy?, isVoice: Bool) {
        let settings = settingsList.first
        guard settings?.adhkarAutoAdvance == true else { return }
        
        guard let index = adhkarList.firstIndex(where: { $0.id == item.id }) else { return }
        var nextIndex = index + 1
        while nextIndex < adhkarList.count && (completedItems.contains(adhkarList[nextIndex].id) || !adhkarList[nextIndex].isMandatory) {
            nextIndex += 1
        }
        
        if nextIndex < adhkarList.count {
            let nextItem = adhkarList[nextIndex]
            lastActiveDhikrIndex = nextIndex
            lastActiveDhikrCount = todayRecord.getAdhkarCount(for: safeKey(for: nextItem))
            withAnimation {
                proxy?.scrollTo(nextItem.id, anchor: .center)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let proxy = proxy {
                    if isVoice && isVoiceMode {
                        toggleVoicePlayback(item: nextItem, proxy: proxy)
                    } else if !isVoice && settings?.adhkarAutoCount == true {
                        toggleAutoCount(item: nextItem, proxy: proxy)
                    }
                }
            }
        } else {
            withAnimation {
                proxy?.scrollTo(adhkarList.last?.id, anchor: .bottom)
            }
        }
    }

    private func toggleAutoCount(item: AdhkarItem, proxy: ScrollViewProxy) {
        guard item.isMandatory else { return }
        if activeAutoCountItemId == item.id {
            stopAutoCount()
        } else {
            startAutoCount(item: item, proxy: proxy)
        }
    }
    
    private func startAutoCount(item: AdhkarItem, proxy: ScrollViewProxy) {
        guard item.isMandatory else { return }
        stopAutoCount()
        activeAutoCountItemId = item.id
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        
        let interval = autoCountInterval(for: item)
        
        if interval <= 0.0 {
            // Sonderfall: Sofort erledigt, keine Verzögerung, Auto-Advance greift hier sofort bei Trigger
            let current = counts[item.id] ?? 0
            let diff = item.count - current
            counts[item.id] = item.count
            todayRecord.setAdhkarCount(for: safeKey(for: item), count: item.count)
            completedItems.insert(item.id)
            if let category = item.linkedTasbihCategory {
                switch category {
                case .istighfar: todayRecord.istighfarCount += diff
                case .salawat: todayRecord.salawatCount += diff
                case .subhanAllah: todayRecord.subhanAllahCount += diff
                case .alhamdulillah: todayRecord.alhamdulillahCount += diff
                case .allahuAkbar: todayRecord.allahuAkbarCount += diff
                case .laIlahaIllallah: todayRecord.laIlahaIllallahCount += diff
                }
            }
            try? modelContext.save()
            
            stopAutoCount()
            advanceToNextItem(after: item, proxy: proxy, isVoice: isVoiceMode)
            return
        }
        
        // Verwende einen asynchronen Task-basierten Loop auf dem MainActor
        // Dies vermeidet Sendable-Kapselungsfehler mit ScrollViewProxy
        Task { @MainActor in
            while activeAutoCountItemId == item.id {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard activeAutoCountItemId == item.id else { break }
                incrementCount(item: item, proxy: proxy, isAuto: true)
                let current = counts[item.id] ?? 0
                if current >= item.count {
                    stopAutoCount()
                    break
                }
            }
        }
    }
    
    private func stopAutoCount() {
        autoTimer?.invalidate()
        autoTimer = nil
        activeAutoCountItemId = nil
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
    }
    
    private func toggleVoicePlayback(item: AdhkarItem, proxy: ScrollViewProxy) {
        guard item.isMandatory else { return }
        
        if completedItems.contains(item.id) { return }
        
        if activeAutoCountItemId == item.id {
            if audioPlayer.activeItemId == item.id && audioPlayer.isPlaying {
                audioPlayer.stop()
            }
            stopAutoCount()
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        stopAutoCount()
        
        guard item.audioFileName != nil else {
            if item.german.contains("Al-Mulk") || item.arabic.contains("الْمُلْكِ") {
                mulkItemToComplete = item
                showAlMulkReader = true
            } else {
                toggleAutoCount(item: item, proxy: proxy)
            }
            return
        }
        
        let current = counts[item.id] ?? 0
        
        #if os(iOS) && !SKIP
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
        
        // Subhan Allah & Istighfar (100x): Recitation audio plays only once, then auto tracker takes over
        if item.count == 100 {
            if current >= 1 {
                // Audio has already played at least once, continue tracking
                startAutoCount(item: item, proxy: proxy)
                return
            }
            
            activeAutoCountItemId = item.id
            audioPlayer.play(
                item: item,
                startRepetition: 0,
                targetRepetitions: 1,
                onRepetitionCompleted: { repetition in
                    incrementCount(item: item, proxy: proxy, isAuto: true)
                },
                onFinished: {
                    if (counts[item.id] ?? 0) < item.count {
                        startAutoCount(item: item, proxy: proxy)
                    } else {
                        activeAutoCountItemId = nil
                        advanceToNextItem(after: item, proxy: proxy, isVoice: true)
                    }
                }
            )
            return
        }
        
        activeAutoCountItemId = item.id
        audioPlayer.play(
            item: item,
            startRepetition: current,
            targetRepetitions: item.count,
            onRepetitionCompleted: { repetition in
                incrementCount(item: item, proxy: proxy, isAuto: true)
            },
            onFinished: {
                activeAutoCountItemId = nil
                advanceToNextItem(after: item, proxy: proxy, isVoice: true)
            }
        )
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
        record.clearAdhkarSnapshot(for: type.idStr)
        try? modelContext.save()
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
        
        clearSessionState()
        
        // Modal / Ansicht schließen
        dismiss()
    }
    
    private func markAllAsCompleted() {
        #if os(iOS) && !SKIP
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
        todayRecord.markAllAdhkarCompleted(type: type)
        try? modelContext.save()
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
        clearSessionState()
        
        let record = todayRecord
        var newCompleted = Set<UUID>()
        for item in adhkarList {
            let key = safeKey(for: item)
            let dbCount = record.getAdhkarCount(for: key)
            counts[item.id] = dbCount
            if dbCount >= item.count {
                newCompleted.insert(item.id)
            }
        }
        completedItems = newCompleted
    }
    
    private func markAsUncompleted() {
        guard canUndoCompletion else { return }
        #if os(iOS) && !SKIP
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
        todayRecord.markAdhkarUncompleted(type: type)
        try? modelContext.save()
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
        
        let record = todayRecord
        var newCompleted = Set<UUID>()
        for item in adhkarList {
            let key = safeKey(for: item)
            let dbCount = record.getAdhkarCount(for: key)
            counts[item.id] = dbCount
            if dbCount >= item.count {
                newCompleted.insert(item.id)
            }
        }
        completedItems = newCompleted
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
        let germanClean = item.german.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let transClean = item.transliteration.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let combined = String((germanClean + transClean).prefix(60))
        return "\(type.idStr)_\(item.count)_\(combined)"
    }
    
    private func loadProgressFromDatabase(proxy: ScrollViewProxy) {
        let record = todayRecord
        
        for item in adhkarList {
            let key = safeKey(for: item)
            var dbCount = record.getAdhkarCount(for: key)
            if dbCount == 0 {
                let oldText = String(item.german.prefix(30))
                let oldCleaned = oldText.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                let oldKey = "\(type.idStr)_\(oldCleaned)"
                let oldVal = record.getAdhkarCount(for: oldKey)
                if oldVal == item.count {
                    dbCount = oldVal
                }
            }
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
    var showTransliteration: Bool = true
    let isActive: Bool
    let useAuto: Bool
    let isTrackingAllowed: Bool
    var isEditMode: Bool = false
    var isFirstInList: Bool = false
    var isLastInList: Bool = false
    var isVoiceMode: Bool = false
    var audioProgress: Double = 0.0
    let onIncrement: () -> Void
    let onInfoTap: () -> Void
    var onOpenReader: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            if isEditMode {
                HStack {
                    HStack(spacing: 12) {
                        Button(action: { onMoveUp?() }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(isFirstInList ? .gray.opacity(0.3) : Theme.islamicGreen)
                        }
                        .disabled(isFirstInList)
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { onMoveDown?() }) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(isLastInList ? .gray.opacity(0.3) : Theme.islamicGreen)
                        }
                        .disabled(isLastInList)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text(L10n.tr("adhkar_reorder", language))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }
            
            Text(item.arabic)
                .font(.system(size: 26))
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .foregroundColor(item.isMandatory ? .primary : .gray.opacity(0.6))
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal)
                .padding(.top, isEditMode ? 0 : 8)
            
            // Transliteration
            if showTransliteration && language != "ar" && !item.transliteration.isEmpty {
                Text(item.transliteration)
                    .font(.body)
                    .foregroundColor(item.isMandatory ? .gray : .gray.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let openReaderAction = onOpenReader {
                Button(action: openReaderAction) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.headline)
                            .foregroundColor(Theme.islamicGreen)
                        
                        Text(L10n.tr("read_surah_mulk", language))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.islamicGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.islamicGreen.opacity(0.12))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            
            if isTrackingAllowed && item.isMandatory {
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
                        } else if isVoiceMode {
                            let isPlayingAudio = isActive
                            let effectiveProgress: CGFloat = {
                                if !isPlayingAudio { return CGFloat(currentCount) / CGFloat(max(1, item.count)) }
                                if item.count == 1 { return CGFloat(audioProgress) }
                                return (CGFloat(currentCount) + CGFloat(audioProgress)) / CGFloat(item.count)
                            }()
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: min(1.0, max(0.0, effectiveProgress)))
                                    .stroke(Theme.islamicGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                    .scaleEffect(isPlayingAudio ? 1.05 : 1.0)
                                    .animation(isPlayingAudio ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isPlayingAudio)
                                
                                VStack(spacing: 2) {
                                    if isPlayingAudio {
                                        Image(systemName: "pause.fill")
                                            .font(.title2)
                                            .foregroundColor(Theme.islamicGreen)
                                    } else {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.title3)
                                            .foregroundColor(Theme.islamicGreen)
                                    }
                                    
                                    if item.count > 1 {
                                        Text("\(currentCount)/\(item.count)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }
                                }
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
                    .disabled(isCompleted || isEditMode)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEditMode ? Theme.islamicGreen.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .opacity(isCompleted ? 0.45 : 1.0)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.8) {
            if !isEditMode {
                onLongPress?()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    if onOpenReader != nil && abs(value.translation.width) > 30 && abs(value.translation.height) < 60 {
                        onOpenReader?()
                    }
                }
        )
        .overlay(
            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
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
    @Environment(\.dismiss) var dismiss
    
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
                        
                        // 3. Tempo-Regler (BPM)
                        VStack(spacing: 8) {
                            HStack {
                                Text(L10n.tr("speed", language))
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(
                                    item.customSpeedStep == 0 ? L10n.tr("tempo_slow", language) :
                                    item.customSpeedStep == 1 ? L10n.tr("tempo_normal", language) :
                                    L10n.tr("tempo_fast", language)
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
                                    in: 0...2,
                                    step: 1
                                )
                                .tint(Theme.islamicGreen)
                                .accentColor(Theme.islamicGreen)
                                .padding(.vertical, 8)
                                
                                Button(action: {
                                    if item.customSpeedStep < 2 {
                                        let intVal = item.customSpeedStep + 1
                                        item.customSpeedStep = intVal
                                        let text = String(item.german.prefix(30))
                                        let safeText = text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
                                        UserDefaults.standard.set(intVal, forKey: "adhkar_\(safeText)_speed")
                                    }
                                }) {
                                    Image(systemName: "hare.fill")
                                        .foregroundColor(item.customSpeedStep == 2 ? .gray.opacity(0.3) : .gray)
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
            .navigationTitle(L10n.tr("adhkar_info_title", language))
            #if os(iOS)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(Theme.islamicGreen)
                    .fontWeight(.bold)
                }
            }
            #if os(iOS)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }
}
