import SwiftUI
import SwiftData
import AVFoundation
import AudioToolbox

struct FajrSettingsView: View {
    @Query private var settingsList: [UserSettings]
    
    @AppStorage("isFajrAlarmEnabled") private var isFajrAlarmEnabled: Bool = false
    @AppStorage("fajrAlarmMode") private var fajrAlarmMode: String = "atFajr"
    @AppStorage("fajrAlarmOffsetMinutes") private var fajrAlarmOffsetMinutes: Int = 30
    @AppStorage("fajrAlarmFixedTime") private var fajrAlarmFixedTime: Double = 18000 // 5:00 AM
    
    @AppStorage("isFajrAlarm2Enabled") private var isFajrAlarm2Enabled: Bool = false
    @AppStorage("fajrAlarmMode2") private var fajrAlarmMode2: String = "atFajr"
    @AppStorage("fajrAlarmOffsetMinutes2") private var fajrAlarmOffsetMinutes2: Int = 30
    @AppStorage("fajrAlarmFixedTime2") private var fajrAlarmFixedTime2: Double = 21600 // 6:00 AM
    
    @AppStorage("fajrAlarmSound") private var fajrAlarmSound: String = "default"
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingPreview = false
    @State private var delegateHelper = AudioPlayerDelegateHelper()
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("fajr_alarm_first_sec", language))) {
                Toggle(L10n.tr("fajr_alarm_enable", language), isOn: $isFajrAlarmEnabled.animation())
                    .onChange(of: isFajrAlarmEnabled) { _, newValue in
                        if newValue {
                            FajrAlarmManager.shared.requestAuthorization { granted in
                                DispatchQueue.main.async {
                                    if granted {
                                        FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 1)
                                    } else {
                                        isFajrAlarmEnabled = false
                                    }
                                }
                            }
                        } else {
                            FajrAlarmManager.shared.cancelFajrAlarm(alarmNumber: 1)
                        }
                    }
                
                if isFajrAlarmEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(L10n.tr("fajr_alarm_mode", language), selection: $fajrAlarmMode.animation()) {
                            Text(L10n.tr("fajr_alarm_mode_at", language)).tag("atFajr")
                            Text(L10n.tr("fajr_alarm_mode_before", language)).tag("beforeFajr")
                            Text(L10n.tr("fajr_alarm_mode_fixed", language)).tag("fixedTime")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: fajrAlarmMode) { _, _ in
                            FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 1)
                        }
                        
                        if fajrAlarmMode == "beforeFajr" {
                            Picker(L10n.tr("fajr_alarm_mode_before", language), selection: $fajrAlarmOffsetMinutes) {
                                Text("15 Min.").tag(15)
                                Text("30 Min.").tag(30)
                                Text("45 Min.").tag(45)
                                Text("60 Min.").tag(60)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: fajrAlarmOffsetMinutes) { _, _ in
                                FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 1)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        if fajrAlarmMode == "fixedTime" {
                            DatePicker(
                                L10n.tr("fajr_alarm_mode_fixed", language),
                                selection: fixedTimeBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                    
                    Text(nextAlarmPreviewText1)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .transition(.opacity)
                }
            }
            
            Section(header: Text(L10n.tr("fajr_alarm_second_sec", language))) {
                Toggle(L10n.tr("fajr_alarm_enable", language), isOn: $isFajrAlarm2Enabled.animation())
                    .onChange(of: isFajrAlarm2Enabled) { _, newValue in
                        if newValue {
                            FajrAlarmManager.shared.requestAuthorization { granted in
                                DispatchQueue.main.async {
                                    if granted {
                                        FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 2)
                                    } else {
                                        isFajrAlarm2Enabled = false
                                    }
                                }
                            }
                        } else {
                            FajrAlarmManager.shared.cancelFajrAlarm(alarmNumber: 2)
                        }
                    }
                
                if isFajrAlarm2Enabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(L10n.tr("fajr_alarm_mode", language), selection: $fajrAlarmMode2.animation()) {
                            Text(L10n.tr("fajr_alarm_mode_at", language)).tag("atFajr")
                            Text(L10n.tr("fajr_alarm_mode_before", language)).tag("beforeFajr")
                            Text(L10n.tr("fajr_alarm_mode_fixed", language)).tag("fixedTime")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: fajrAlarmMode2) { _, _ in
                            FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 2)
                        }
                        
                        if fajrAlarmMode2 == "beforeFajr" {
                            Picker(L10n.tr("fajr_alarm_mode_before", language), selection: $fajrAlarmOffsetMinutes2) {
                                Text("15 Min.").tag(15)
                                Text("30 Min.").tag(30)
                                Text("45 Min.").tag(45)
                                Text("60 Min.").tag(60)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: fajrAlarmOffsetMinutes2) { _, _ in
                                FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 2)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        if fajrAlarmMode2 == "fixedTime" {
                            DatePicker(
                                L10n.tr("fajr_alarm_mode_fixed", language),
                                selection: fixedTimeBinding2,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                    
                    Text(nextAlarmPreviewText2)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .transition(.opacity)
                }
            }
            
            Section(header: Text(L10n.tr("fajr_alarm_sound", language))) {
                Picker(L10n.tr("fajr_alarm_sound", language), selection: $fajrAlarmSound) {
                    Text(L10n.tr("fajr_sound_system", language)).tag("default")
                    Text(L10n.tr("fajr_sound_azan1", language)).tag("azan.m4a")
                    Text(L10n.tr("fajr_sound_azan2", language)).tag("azan (2).m4a")
                    Text(L10n.tr("fajr_sound_azan_mecca", language)).tag("azan_holy_makkah.m4a")
                    Text(L10n.tr("fajr_sound_azan_beauty", language)).tag("beautifull_azan.m4a")
                    Text(L10n.tr("fajr_sound_fajr1", language)).tag("fajar.m4a")
                    Text(L10n.tr("fajr_sound_fajr2", language)).tag("fajar (1).m4a")
                    Text(L10n.tr("fajr_sound_alarm_mecca", language)).tag("fajr_alarm_mecca.m4a")
                }
                .pickerStyle(.menu)
                .onChange(of: fajrAlarmSound) { _, _ in
                    FajrAlarmManager.shared.scheduleFajrAlarm()
                }
                
                Button(action: toggleSoundPreview) {
                    HStack {
                        Image(systemName: isPlayingPreview ? "stop.fill" : "play.fill")
                            .foregroundColor(Theme.islamicGreen)
                        Text(isPlayingPreview ? L10n.tr("fajr_sound_preview_stop", language) : L10n.tr("fajr_sound_preview_play", language))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L10n.tr("fajr_settings_info_title", language), systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(Theme.islamicGreen)
                    
                    Text(L10n.tr("fajr_settings_info_desc", language))
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text(L10n.tr("fajr_settings_open_ios_settings", language))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Theme.islamicGreen)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }
        }
        .onDisappear {
            if isPlayingPreview {
                audioPlayer?.stop()
                isPlayingPreview = false
            }
        }
        .navigationTitle(L10n.tr("fajr_sec", language))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var fixedTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                let hour = Int(fajrAlarmFixedTime) / 3600
                let minute = (Int(fajrAlarmFixedTime) % 3600) / 60
                components.hour = hour
                components.minute = minute
                components.second = 0
                return calendar.date(from: components) ?? Date()
            },
            set: { newDate in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: newDate)
                let hours = components.hour ?? 5
                let minutes = components.minute ?? 0
                fajrAlarmFixedTime = Double(hours * 3600 + minutes * 60)
                FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 1)
            }
        )
    }
    
    private var fixedTimeBinding2: Binding<Date> {
        Binding<Date>(
            get: {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                let hour = Int(fajrAlarmFixedTime2) / 3600
                let minute = (Int(fajrAlarmFixedTime2) % 3600) / 60
                components.hour = hour
                components.minute = minute
                components.second = 0
                return calendar.date(from: components) ?? Date()
            },
            set: { newDate in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: newDate)
                let hours = components.hour ?? 6
                let minutes = components.minute ?? 0
                fajrAlarmFixedTime2 = Double(hours * 3600 + minutes * 60)
                FajrAlarmManager.shared.scheduleFajrAlarm(alarmNumber: 2)
            }
        )
    }
    
    private var nextAlarmPreviewText1: String {
        guard isFajrAlarmEnabled else { return "" }
        if let nextDate = FajrAlarmManager.shared.getNextAlarmDate(alarmNumber: 1) {
            return formatNextAlarmPreview(nextDate: nextDate)
        }
        return ""
    }
    
    private var nextAlarmPreviewText2: String {
        guard isFajrAlarm2Enabled else { return "" }
        if let nextDate = FajrAlarmManager.shared.getNextAlarmDate(alarmNumber: 2) {
            return formatNextAlarmPreview(nextDate: nextDate)
        }
        return ""
    }
    
    private func formatNextAlarmPreview(nextDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: nextDate)
        
        let dayStr: String
        if Calendar.current.isDateInToday(nextDate) {
            dayStr = L10n.tr("today", language).lowercased()
        } else if Calendar.current.isDateInTomorrow(nextDate) {
            dayStr = L10n.tr("tomorrow", language).lowercased()
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: language)
            dayFormatter.dateFormat = "EEEE"
            dayStr = dayFormatter.string(from: nextDate)
        }
        
        let nextPrefix = L10n.tr("fajr_alarm_next_prefix_dynamic", language)
        if language == "de" {
            return "\(nextPrefix) \(dayStr) um \(timeStr) Uhr"
        } else if language == "en" {
            return "\(nextPrefix) \(dayStr) at \(timeStr)"
        } else if language == "fr" {
            return "\(nextPrefix) \(dayStr) à \(timeStr)"
        } else {
            return "\(nextPrefix) \(dayStr) \(timeStr)"
        }
    }
    
    private func toggleSoundPreview() {
        if isPlayingPreview {
            audioPlayer?.stop()
            isPlayingPreview = false
            return
        }
        
        if fajrAlarmSound == "default" {
            // Play system default sound once (e.g. system sound 1005: SMS/Alarm)
            AudioServicesPlaySystemSound(1005)
        } else {
            let url: URL?
            if fajrAlarmSound.lowercased().hasSuffix(".m4a") {
                let nameOnly = fajrAlarmSound.replacingOccurrences(of: ".m4a", with: "", options: .caseInsensitive)
                url = Bundle.main.url(forResource: nameOnly, withExtension: "m4a")
            } else {
                let nameOnly = fajrAlarmSound.replacingOccurrences(of: ".wav", with: "", options: .caseInsensitive)
                url = Bundle.main.url(forResource: nameOnly, withExtension: "wav")
            }
            
            guard let soundUrl = url else {
                print("Sound file \(fajrAlarmSound) not found in bundle")
                return
            }
            do {
                let player = try AVAudioPlayer(contentsOf: soundUrl)
                delegateHelper.onDidFinishPlaying = {
                    self.isPlayingPreview = false
                }
                player.delegate = delegateHelper
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                self.isPlayingPreview = true
            } catch {
                print("Failed to initialize AVAudioPlayer: \(error)")
            }
        }
    }
}

class AudioPlayerDelegateHelper: NSObject, AVAudioPlayerDelegate {
    var onDidFinishPlaying: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onDidFinishPlaying?()
    }
}
