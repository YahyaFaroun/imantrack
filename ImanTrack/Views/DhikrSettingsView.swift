import SwiftUI
import SwiftData

struct DhikrSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    
    @State private var adhkarAutoCount: Bool = true
    @State private var adhkarAutoAdvance: Bool = true
    @State private var defaultAdhkarSpeedStep: Int = 2
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("adhkar_count_mode", language))) {
                Picker(L10n.tr("adhkar_count_mode", language), selection: $adhkarAutoCount) {
                    Text(L10n.tr("adhkar_count_manual", language)).tag(false)
                    Text(L10n.tr("adhkar_count_auto", language)).tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: adhkarAutoCount) { _, newValue in
                    withAnimation {
                        if !newValue {
                            adhkarAutoAdvance = false
                        }
                    }
                    saveSettings()
                }
            }
            
            if adhkarAutoCount {
                Section {
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
                
                Section(header: Text(L10n.tr("playback_tempo", language))) {
                    Picker(L10n.tr("playback_tempo", language), selection: $defaultAdhkarSpeedStep) {
                        Text(L10n.tr("tempo_slowest", language)).tag(0)
                        Text(L10n.tr("tempo_slow", language)).tag(1)
                        Text(L10n.tr("tempo_normal", language)).tag(2)
                        Text(L10n.tr("tempo_fast", language)).tag(3)
                        Text(L10n.tr("tempo_fastest", language)).tag(4)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: defaultAdhkarSpeedStep) { _, _ in saveSettings() }
                }
            }
        }
        .navigationTitle(L10n.tr("adhkar_sec", language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let s = settingsList.first {
                adhkarAutoCount = s.adhkarAutoCount
                adhkarAutoAdvance = s.adhkarAutoAdvance
                defaultAdhkarSpeedStep = s.defaultAdhkarSpeedStep
            } else {
                defaultAdhkarSpeedStep = UserDefaults.standard.integer(forKey: "defaultAdhkarSpeedStep")
            }
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
        
        UserDefaults.standard.set(defaultAdhkarSpeedStep, forKey: "defaultAdhkarSpeedStep")
        
        try? modelContext.save()
    }
}
