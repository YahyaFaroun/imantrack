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
    
    private var currentMethod: CalculationMethod {
        CalculationMethod(rawValue: calculationMethodRaw) ?? .mwl
    }
    
    var body: some View {
        Form {
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
            
            Section(header: Text(L10n.tr("prayer_preview_header", language))) {
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
