import SwiftUI
import SwiftData

struct DhikrSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @ObservedObject private var audioPlayer = AdhkarAudioPlayer.shared
    
    @State private var adhkarAutoCount: Bool = true
    @State private var adhkarAutoAdvance: Bool = true
    @State private var defaultAdhkarSpeedStep: Int = 1
    @State private var adhkarVoiceEnabled: Bool = false
    @State private var adhkarReciter: String = "iapetus"
    @State private var hasLoadedInitialSettings: Bool = false
    
    @State private var isMorningAdhkarReminderEnabled: Bool = true
    @State private var isEveningAdhkarReminderEnabled: Bool = true
    @State private var isSleepAdhkarReminderEnabled: Bool = true
    @State private var isKahfReminderEnabled: Bool = true
    @State private var isPermissionDenied: Bool = false
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    var body: some View {
        Form {
            if isPermissionDenied {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.slash.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text(L10n.tr("notif_disabled_ios", language))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(L10n.tr("open_settings", language))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.islamicGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.islamicGreen.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text(L10n.tr("adhkar_reminder_section_header", language))) {
                Toggle(L10n.tr("reminder_morning_adhkar", language), isOn: $isMorningAdhkarReminderEnabled)
                    .onChange(of: isMorningAdhkarReminderEnabled) { _, newValue in
                        handleReminderToggle(newValue)
                    }
                Toggle(L10n.tr("reminder_evening_adhkar", language), isOn: $isEveningAdhkarReminderEnabled)
                    .onChange(of: isEveningAdhkarReminderEnabled) { _, newValue in
                        handleReminderToggle(newValue)
                    }
                Toggle(L10n.tr("reminder_sleep_adhkar", language), isOn: $isSleepAdhkarReminderEnabled)
                    .onChange(of: isSleepAdhkarReminderEnabled) { _, newValue in
                        handleReminderToggle(newValue)
                    }
                Toggle(L10n.tr("reminder_kahf", language), isOn: $isKahfReminderEnabled)
                    .onChange(of: isKahfReminderEnabled) { _, newValue in
                        handleReminderToggle(newValue)
                    }
            }

            Section(header: Text(L10n.tr("adhkar_count_mode", language))) {
                Picker(L10n.tr("adhkar_count_mode", language), selection: $adhkarAutoCount) {
                    Text(L10n.tr("adhkar_count_manual", language)).tag(false)
                    Text(L10n.tr("adhkar_count_auto", language)).tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: adhkarAutoCount) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if !newValue {
                            adhkarAutoAdvance = false
                        }
                    }
                    saveSettings()
                }
                
                if adhkarAutoCount {
                    Toggle(isOn: $adhkarAutoAdvance) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr("adhkar_auto_advance", language))
                                .font(.body)
                            Text(L10n.tr("adhkar_auto_advance_desc", language))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                    .onChange(of: adhkarAutoAdvance) { _, _ in saveSettings() }
                }
            }
            
            Section(header: Text(L10n.tr("adhkar_voice_mode", language))) {
                Toggle(isOn: $adhkarVoiceEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("adhkar_voice_mode_title", language))
                            .font(.body)
                        Text(L10n.tr("adhkar_voice_mode_desc", language))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                .onChange(of: adhkarVoiceEnabled) { _, newValue in
                    if !newValue {
                        audioPlayer.stopPreview()
                    }
                    saveSettings()
                }
                
                if adhkarVoiceEnabled {
                    Picker(L10n.tr("adhkar_voice_reciter", language), selection: $adhkarReciter) {
                        ForEach(AdhkarReciter.allCases) { reciter in
                            Text(reciter.title(for: language)).tag(reciter.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: adhkarReciter) { _, newValue in
                        saveSettings()
                        if hasLoadedInitialSettings {
                            audioPlayer.playReciterPreview(reciter: newValue)
                        }
                    }
                    
                    HStack {
                        Text(L10n.tr("preview", language))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            audioPlayer.toggleReciterPreview(reciter: adhkarReciter)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: audioPlayer.isPlayingPreview ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title3)
                                Text(audioPlayer.isPlayingPreview ? L10n.tr("stop", language) : L10n.tr("play", language))
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
            
            if adhkarAutoCount {
                Section(header: Text(L10n.tr("playback_tempo", language))) {
                    Picker(L10n.tr("playback_tempo", language), selection: $defaultAdhkarSpeedStep) {
                        Text(L10n.tr("tempo_slow", language)).tag(0)
                        Text(L10n.tr("tempo_normal", language)).tag(1)
                        Text(L10n.tr("tempo_fast", language)).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: defaultAdhkarSpeedStep) { _, _ in saveSettings() }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: adhkarAutoCount)
        .navigationTitle(L10n.tr("adhkar_sec", language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkPermissionStatus()
            if let s = settingsList.first {
                adhkarAutoCount = s.adhkarAutoCount
                adhkarAutoAdvance = s.adhkarAutoAdvance
                defaultAdhkarSpeedStep = s.defaultAdhkarSpeedStep
                adhkarVoiceEnabled = s.adhkarVoiceEnabled
                adhkarReciter = s.adhkarReciter
            } else {
                defaultAdhkarSpeedStep = UserDefaults.standard.integer(forKey: "defaultAdhkarSpeedStep")
                adhkarVoiceEnabled = UserDefaults.standard.bool(forKey: "adhkarVoiceEnabled")
                adhkarReciter = UserDefaults.standard.string(forKey: "adhkarReciter") ?? "iapetus"
            }
            isMorningAdhkarReminderEnabled = UserDefaults.standard.object(forKey: "isMorningAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isMorningAdhkarReminderEnabled") : true
            isEveningAdhkarReminderEnabled = UserDefaults.standard.object(forKey: "isEveningAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isEveningAdhkarReminderEnabled") : true
            isSleepAdhkarReminderEnabled = UserDefaults.standard.object(forKey: "isSleepAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isSleepAdhkarReminderEnabled") : true
            isKahfReminderEnabled = UserDefaults.standard.object(forKey: "isKahfReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isKahfReminderEnabled") : true
            DispatchQueue.main.async {
                hasLoadedInitialSettings = true
            }
        }
        .onDisappear {
            audioPlayer.stopPreview()
        }
    }
    
    private func checkPermissionStatus() {
        AdhkarReminderManager.shared.getAuthorizationStatus { status in
            isPermissionDenied = (status == .denied)
        }
    }
    
    private func handleReminderToggle(_ enabled: Bool) {
        saveSettings()
        if enabled {
            AdhkarReminderManager.shared.requestAuthorization { granted in
                checkPermissionStatus()
                if granted {
                    AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
                }
            }
        } else {
            AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
        }
    }

    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        
        s.adhkarAutoCount = adhkarAutoCount
        s.adhkarAutoAdvance = adhkarAutoAdvance
        s.defaultAdhkarSpeedStep = defaultAdhkarSpeedStep
        s.adhkarVoiceEnabled = adhkarVoiceEnabled
        s.adhkarReciter = adhkarReciter
        
        UserDefaults.standard.set(defaultAdhkarSpeedStep, forKey: "defaultAdhkarSpeedStep")
        UserDefaults.standard.set(adhkarVoiceEnabled, forKey: "adhkarVoiceEnabled")
        UserDefaults.standard.set(adhkarReciter, forKey: "adhkarReciter")
        UserDefaults.standard.set(isMorningAdhkarReminderEnabled, forKey: "isMorningAdhkarReminderEnabled")
        UserDefaults.standard.set(isEveningAdhkarReminderEnabled, forKey: "isEveningAdhkarReminderEnabled")
        UserDefaults.standard.set(isSleepAdhkarReminderEnabled, forKey: "isSleepAdhkarReminderEnabled")
        UserDefaults.standard.set(isKahfReminderEnabled, forKey: "isKahfReminderEnabled")
        
        try? modelContext.save()
    }
}
