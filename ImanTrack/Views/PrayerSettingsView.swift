import SwiftUI
import SwiftData

struct PrayerSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    
    @State private var calculationMethodRaw: String = "mwl"
    @State private var asrSchoolRaw: String = "standard"
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("prayer_settings_sec", language))) {
                Picker(L10n.tr("calculation_method", language), selection: $calculationMethodRaw) {
                    Text(L10n.tr("method_mwl", language)).tag("mwl")
                    Text(L10n.tr("method_isna", language)).tag("isna")
                    Text(L10n.tr("method_umm_al_qura", language)).tag("ummAlQura")
                    Text(L10n.tr("method_karachi", language)).tag("karachi")
                    Text(L10n.tr("method_egyptian", language)).tag("egyptian")
                    Text(L10n.tr("method_uoif", language)).tag("uoif")
                }
                .onChange(of: calculationMethodRaw) { _, _ in
                    saveSettings()
                }
                
                Picker(L10n.tr("asr_school", language), selection: $asrSchoolRaw) {
                    Text(L10n.tr("asr_standard", language)).tag("standard")
                    Text(L10n.tr("asr_hanafi", language)).tag("hanafi")
                }
                .onChange(of: asrSchoolRaw) { _, _ in
                    saveSettings()
                }
            }
            
            Section(header: Text(L10n.tr("prayer_preview_header", language))) {
                let today = Date()
                let solarManager = LocationAndSolarManager.shared
                
                HStack {
                    Text(L10n.tr("prayer_fajr", language))
                    Spacer()
                    Text(formattedTime(solarManager.getFajrDate(for: today)))
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
                    Text(formattedTime(solarManager.getAsrDate(for: today)))
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
                    Text(formattedTime(solarManager.getIshaDate(for: today)))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.islamicGreen)
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
        }
    }
    
    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        return timeFormatter.string(from: date)
    }
    
    private func loadSettings() {
        if let s = settingsList.first {
            calculationMethodRaw = s.calculationMethodRaw
            asrSchoolRaw = s.asrSchoolRaw
        } else {
            calculationMethodRaw = UserDefaults.standard.string(forKey: "calculationMethodRaw") ?? "mwl"
            asrSchoolRaw = UserDefaults.standard.string(forKey: "asrSchoolRaw") ?? "standard"
        }
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        s.calculationMethodRaw = calculationMethodRaw
        s.asrSchoolRaw = asrSchoolRaw
        
        UserDefaults.standard.set(calculationMethodRaw, forKey: "calculationMethodRaw")
        UserDefaults.standard.set(asrSchoolRaw, forKey: "asrSchoolRaw")
        
        try? modelContext.save()
        
        // Re-calculate & reschedule reminders and tracking date immediately
        LocationAndSolarManager.shared.updateTrackingDate()
        AdhkarReminderManager.shared.scheduleReminders(container: modelContext.container)
    }
}
