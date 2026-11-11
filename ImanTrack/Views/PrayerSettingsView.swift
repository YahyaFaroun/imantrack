import SwiftUI
import SwiftData
import UserNotifications

struct PrayerSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @ObservedObject private var prayerNotifManager = PrayerNotificationManager.shared
    
    @State private var calculationMethodRaw: String = "mwl"
    @State private var asrSchoolRaw: String = "standard"
    
    // Notifications & Adhan
    @State private var prayerAdhanEnabled: Bool = false
    @State private var prayerReminder10MinEnabled: Bool = false
    @State private var prayerAdhanSound: String = "azan-1.caf"
    @State private var prayerFajrEnabled: Bool = true
    @State private var prayerDhuhrEnabled: Bool = true
    @State private var prayerAsrEnabled: Bool = true
    @State private var prayerMaghribEnabled: Bool = true
    @State private var prayerIshaEnabled: Bool = true
    @State private var notificationStatus: UNAuthorizationStatus = .authorized
    
    // Manuelle Anpassung
    @State private var isManualAdjustmentExpanded: Bool = false
    @State private var offsetFajr: Int = 0
    @State private var offsetDhuhr: Int = 0
    @State private var offsetAsr: Int = 0
    @State private var offsetMaghrib: Int = 0
    @State private var offsetIsha: Int = 0
    @State private var offsetUpdateToken: Int = 0
    
    private let soundOptions: [(id: String, label: String)] = [
        ("azan-1.caf", "Adhan 1"),
        ("azan-2.caf", "Adhan 2"),
        ("azan-3.caf", "Adhan 3"),
        ("azan-4.caf", "Adhan 4"),
        ("azan-5.caf", "Adhan 5"),
        ("azan-6.caf", "Adhan 6"),
        ("azan-7.caf", "Adhan 7")
    ]
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var currentMethod: CalculationMethod {
        CalculationMethod(rawValue: calculationMethodRaw) ?? .mwl
    }
    
    var body: some View {
        Form {
            // MARK: - Benachrichtigungen & Adhan
            Section(header: Text(L10n.tr("prayer_notifications_sec", language))) {
                if notificationStatus == .denied {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(L10n.tr("prayer_notif_denied_banner", language))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(L10n.tr("open_settings", language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Toggle(isOn: $prayerAdhanEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("prayer_adhan_toggle", language))
                            .font(.body)
                        Text(L10n.tr("prayer_adhan_desc", language))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                .onChange(of: prayerAdhanEnabled) { _, newValue in
                    handleToggleChange(enabled: newValue)
                }
                
                Toggle(isOn: $prayerReminder10MinEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("prayer_reminder_10min_toggle", language))
                            .font(.body)
                        Text(L10n.tr("prayer_reminder_10min_desc", language))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                .onChange(of: prayerReminder10MinEnabled) { _, newValue in
                    handleToggleChange(enabled: newValue)
                }
                
                if prayerAdhanEnabled {
                    Picker(L10n.tr("prayer_adhan_sound", language), selection: $prayerAdhanSound) {
                        ForEach(soundOptions, id: \.id) { opt in
                            Text(opt.label).tag(opt.id)
                        }
                    }
                    .onChange(of: prayerAdhanSound) { _, _ in
                        prayerNotifManager.stopPreview()
                        saveSettings()
                    }
                    
                    HStack {
                        Text(L10n.tr("preview", language))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            prayerNotifManager.togglePlayPreview(soundName: prayerAdhanSound)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: prayerNotifManager.isPlayingPreview ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title3)
                                Text(prayerNotifManager.isPlayingPreview ? L10n.tr("stop", language) : L10n.tr("play", language))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Theme.islamicGreen)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            if prayerAdhanEnabled || prayerReminder10MinEnabled {
                Section(header: Text(L10n.tr("prayer_custom_prayers", language))) {
                    Toggle(L10n.tr("prayer_fajr", language), isOn: $prayerFajrEnabled)
                        .onChange(of: prayerFajrEnabled) { _, _ in saveSettings() }
                    Toggle(L10n.tr("prayer_dhuhr", language), isOn: $prayerDhuhrEnabled)
                        .onChange(of: prayerDhuhrEnabled) { _, _ in saveSettings() }
                    Toggle(L10n.tr("prayer_asr", language), isOn: $prayerAsrEnabled)
                        .onChange(of: prayerAsrEnabled) { _, _ in saveSettings() }
                    Toggle(L10n.tr("prayer_maghrib", language), isOn: $prayerMaghribEnabled)
                        .onChange(of: prayerMaghribEnabled) { _, _ in saveSettings() }
                    Toggle(L10n.tr("prayer_isha", language), isOn: $prayerIshaEnabled)
                        .onChange(of: prayerIshaEnabled) { _, _ in saveSettings() }
                }
            }
            
            // MARK: - Berechnungsmethode
            Section(header: Text(L10n.tr("prayer_settings_sec", language))) {
                NavigationLink {
                    CalculationMethodSelectionView(
                        selectedMethodRaw: $calculationMethodRaw,
                        language: language,
                        onSelect: {
                            saveSettings()
                        }
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("calculation_method", language))
                            .foregroundColor(.primary)
                        
                        Text(L10n.tr("method_\(currentMethod.rawValue)", language))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.islamicGreen)
                        
                        Text(currentMethod.subtitle(language: language))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 3)
                }
                
                Picker(L10n.tr("asr_school", language), selection: $asrSchoolRaw) {
                    Text(L10n.tr("asr_standard", language)).tag("standard")
                    Text(L10n.tr("asr_hanafi", language)).tag("hanafi")
                }
                .onChange(of: asrSchoolRaw) { _, _ in
                    saveSettings()
                }
            }
            
            // MARK: - Heutige Gebetszeiten
            Section(header: Text(L10n.tr("prayer_preview_header", language))) {
                let _ = offsetUpdateToken
                let today = Date()
                let solarManager = LocationAndSolarManager.shared
                
                HStack {
                    Text(L10n.tr("prayer_fajr", language))
                    Spacer()
                    Text(formattedTime(solarManager.getFajrDate(for: today, method: currentMethod)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                }
                
                HStack {
                    Text(L10n.tr("prayer_dhuhr", language))
                    Spacer()
                    Text(formattedTime(solarManager.getDhuhrDate(for: today)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                }
                
                HStack {
                    Text(L10n.tr("prayer_asr", language))
                    Spacer()
                    Text(formattedTime(solarManager.getAsrDate(for: today, school: asrSchoolRaw)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                }
                
                HStack {
                    Text(L10n.tr("prayer_maghrib", language))
                    Spacer()
                    Text(formattedTime(solarManager.getMaghribDate(for: today)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                }
                
                HStack {
                    Text(L10n.tr("prayer_isha", language))
                    Spacer()
                    Text(formattedTime(solarManager.getIshaDate(for: today, method: currentMethod)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
                }
            }
            
            // MARK: - Manuelle Anpassung (Minuten)
            Section {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isManualAdjustmentExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(L10n.tr("prayer_manual_adjustment", language))
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: isManualAdjustmentExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if isManualAdjustmentExpanded {
                    prayerAdjustmentRow(
                        title: L10n.tr("prayer_fajr", language),
                        offset: offsetFajr,
                        prayer: "fajr"
                    )
                    
                    prayerAdjustmentRow(
                        title: L10n.tr("prayer_dhuhr", language),
                        offset: offsetDhuhr,
                        prayer: "dhuhr"
                    )
                    
                    prayerAdjustmentRow(
                        title: L10n.tr("prayer_asr", language),
                        offset: offsetAsr,
                        prayer: "asr"
                    )
                    
                    prayerAdjustmentRow(
                        title: L10n.tr("prayer_maghrib", language),
                        offset: offsetMaghrib,
                        prayer: "maghrib"
                    )
                    
                    prayerAdjustmentRow(
                        title: L10n.tr("prayer_isha", language),
                        offset: offsetIsha,
                        prayer: "isha"
                    )
                }
            }
            
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.islamicGreen)
                        .font(.title3)
                    Text(L10n.tr("prayer_times_info_box", language))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(L10n.tr("prayer_settings_sec", language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
            checkPermissionStatus()
        }
        .onDisappear {
            prayerNotifManager.stopPreview()
        }
    }
    
    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        return timeFormatter.string(from: date)
    }
    
    private func checkPermissionStatus() {
        prayerNotifManager.getAuthorizationStatus { status in
            self.notificationStatus = status
        }
    }
    
    private func handleToggleChange(enabled: Bool) {
        if enabled {
            prayerNotifManager.getAuthorizationStatus { status in
                if status == .notDetermined {
                    prayerNotifManager.requestAuthorization { granted in
                        checkPermissionStatus()
                        saveSettings()
                    }
                } else {
                    checkPermissionStatus()
                    saveSettings()
                }
            }
        } else {
            saveSettings()
        }
    }
    
    private func loadSettings() {
        if let s = settingsList.first {
            calculationMethodRaw = s.calculationMethodRaw
            asrSchoolRaw = s.asrSchoolRaw
            prayerAdhanEnabled = s.prayerAdhanEnabled
            prayerReminder10MinEnabled = s.prayerReminder10MinEnabled
            prayerAdhanSound = PrayerNotificationManager.normalizedAdhanSound(s.prayerAdhanSound)
            prayerFajrEnabled = s.prayerFajrEnabled
            prayerDhuhrEnabled = s.prayerDhuhrEnabled
            prayerAsrEnabled = s.prayerAsrEnabled
            prayerMaghribEnabled = s.prayerMaghribEnabled
            prayerIshaEnabled = s.prayerIshaEnabled
        } else {
            calculationMethodRaw = UserDefaults.standard.string(forKey: "calculationMethodRaw") ?? "mwl"
            asrSchoolRaw = UserDefaults.standard.string(forKey: "asrSchoolRaw") ?? "standard"
            prayerAdhanEnabled = UserDefaults.standard.bool(forKey: "prayerAdhanEnabled")
            prayerReminder10MinEnabled = UserDefaults.standard.bool(forKey: "prayerReminder10MinEnabled")
            prayerAdhanSound = PrayerNotificationManager.normalizedAdhanSound(UserDefaults.standard.string(forKey: "prayerAdhanSound") ?? "azan-1.caf")
            prayerFajrEnabled = UserDefaults.standard.object(forKey: "prayer_fajr_enabled") != nil ? UserDefaults.standard.bool(forKey: "prayer_fajr_enabled") : true
            prayerDhuhrEnabled = UserDefaults.standard.object(forKey: "prayer_dhuhr_enabled") != nil ? UserDefaults.standard.bool(forKey: "prayer_dhuhr_enabled") : true
            prayerAsrEnabled = UserDefaults.standard.object(forKey: "prayer_asr_enabled") != nil ? UserDefaults.standard.bool(forKey: "prayer_asr_enabled") : true
            prayerMaghribEnabled = UserDefaults.standard.object(forKey: "prayer_maghrib_enabled") != nil ? UserDefaults.standard.bool(forKey: "prayer_maghrib_enabled") : true
            prayerIshaEnabled = UserDefaults.standard.object(forKey: "prayer_isha_enabled") != nil ? UserDefaults.standard.bool(forKey: "prayer_isha_enabled") : true
        }
        
        offsetFajr = LocationAndSolarManager.getPrayerOffset(for: "fajr")
        offsetDhuhr = LocationAndSolarManager.getPrayerOffset(for: "dhuhr")
        offsetAsr = LocationAndSolarManager.getPrayerOffset(for: "asr")
        offsetMaghrib = LocationAndSolarManager.getPrayerOffset(for: "maghrib")
        offsetIsha = LocationAndSolarManager.getPrayerOffset(for: "isha")
    }
    
    private func updateOffset(prayer: String, delta: Int) {
        #if os(iOS) && !SKIP
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        
        switch prayer {
        case "fajr":
            offsetFajr = min(max(-60, offsetFajr + delta), 60)
            LocationAndSolarManager.setPrayerOffset(for: "fajr", offset: offsetFajr)
        case "dhuhr":
            offsetDhuhr = min(max(-60, offsetDhuhr + delta), 60)
            LocationAndSolarManager.setPrayerOffset(for: "dhuhr", offset: offsetDhuhr)
        case "asr":
            offsetAsr = min(max(-60, offsetAsr + delta), 60)
            LocationAndSolarManager.setPrayerOffset(for: "asr", offset: offsetAsr)
        case "maghrib":
            offsetMaghrib = min(max(-60, offsetMaghrib + delta), 60)
            LocationAndSolarManager.setPrayerOffset(for: "maghrib", offset: offsetMaghrib)
        case "isha":
            offsetIsha = min(max(-60, offsetIsha + delta), 60)
            LocationAndSolarManager.setPrayerOffset(for: "isha", offset: offsetIsha)
        default: break
        }
        
        offsetUpdateToken += 1
        
        LocationAndSolarManager.shared.updateTrackingDate()
        prayerNotifManager.schedulePrayerNotifications(container: modelContext.container)
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
    }
    
    private func formatOffset(_ val: Int) -> String {
        if val > 0 {
            return "+\(val) Min"
        } else if val < 0 {
            return "\(val) Min"
        } else {
            return "0 Min"
        }
    }
    
    private func prayerAdjustmentRow(title: String, offset: Int, prayer: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(formatOffset(offset))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.islamicGreen)
                .frame(minWidth: 55, alignment: .trailing)
                .padding(.trailing, 8)
            
            PrayerOffsetStepper(
                onDecrement: { updateOffset(prayer: prayer, delta: -1) },
                onIncrement: { updateOffset(prayer: prayer, delta: 1) }
            )
        }
        .padding(.vertical, 3)
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        s.calculationMethodRaw = calculationMethodRaw
        s.asrSchoolRaw = asrSchoolRaw
        s.prayerAdhanEnabled = prayerAdhanEnabled
        s.prayerReminder10MinEnabled = prayerReminder10MinEnabled
        s.prayerAdhanSound = prayerAdhanSound
        s.prayerFajrEnabled = prayerFajrEnabled
        s.prayerDhuhrEnabled = prayerDhuhrEnabled
        s.prayerAsrEnabled = prayerAsrEnabled
        s.prayerMaghribEnabled = prayerMaghribEnabled
        s.prayerIshaEnabled = prayerIshaEnabled
        
        UserDefaults.standard.set(calculationMethodRaw, forKey: "calculationMethodRaw")
        UserDefaults.standard.set(asrSchoolRaw, forKey: "asrSchoolRaw")
        UserDefaults.standard.set(prayerAdhanEnabled, forKey: "prayerAdhanEnabled")
        UserDefaults.standard.set(prayerReminder10MinEnabled, forKey: "prayerReminder10MinEnabled")
        UserDefaults.standard.set(prayerAdhanSound, forKey: "prayerAdhanSound")
        UserDefaults.standard.set(prayerFajrEnabled, forKey: "prayer_fajr_enabled")
        UserDefaults.standard.set(prayerDhuhrEnabled, forKey: "prayer_dhuhr_enabled")
        UserDefaults.standard.set(prayerAsrEnabled, forKey: "prayer_asr_enabled")
        UserDefaults.standard.set(prayerMaghribEnabled, forKey: "prayer_maghrib_enabled")
        UserDefaults.standard.set(prayerIshaEnabled, forKey: "prayer_isha_enabled")
        
        try? modelContext.save()
        
        // Re-calculate & reschedule prayer & adhkar notifications immediately
        LocationAndSolarManager.shared.updateTrackingDate()
        PrayerNotificationManager.shared.schedulePrayerNotifications(container: modelContext.container)
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
    }
}

struct CalculationMethodSelectionView: View {
    @Binding var selectedMethodRaw: String
    let language: String
    let onSelect: () -> Void
    @State private var searchText: String = ""
    
    private var filteredMethods: [CalculationMethod] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanQuery.isEmpty {
            return CalculationMethod.allCases
        }
        return CalculationMethod.allCases.filter { method in
            let title = L10n.tr("method_\(method.rawValue)", language).lowercased()
            let sub = method.subtitle(language: language).lowercased()
            let raw = method.rawValue.lowercased()
            return title.contains(cleanQuery) || sub.contains(cleanQuery) || raw.contains(cleanQuery)
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.islamicGreen)
                        .font(.title3)
                    Text(L10n.tr("calculation_method_desc", language))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                ForEach(filteredMethods, id: \.rawValue) { method in
                    Button {
                        selectedMethodRaw = method.rawValue
                        onSelect()
                    } label: {
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.tr("method_\(method.rawValue)", language))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(method.subtitle(language: language))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedMethodRaw == method.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.islamicGreen)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(Color.secondary.opacity(0.35))
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, prompt: L10n.tr("search_calculation_methods", language))
        .navigationTitle(L10n.tr("calculation_method", language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrayerOffsetStepper: View {
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(width: 1, height: 16)
                .background(Color.white.opacity(0.18))
            
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color(UIColor.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
