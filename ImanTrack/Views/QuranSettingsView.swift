import SwiftUI
import SwiftData

struct QuranSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    
    @State private var quranDailyGoal: Int = 20
    @AppStorage("quranFontSize") private var quranFontSize: Double = 24.0
    @AppStorage("quranFontType") private var quranFontType: String = "uthmanic"
    @AppStorage("quranTheme") private var quranTheme: String = "system"
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("daily_goal", language))) {
                Stepper(value: $quranDailyGoal, in: 1...100, step: 1) {
                    HStack {
                        Text(L10n.tr("pages", language))
                        Spacer()
                        Text("\(quranDailyGoal)")
                            .fontWeight(.bold)
                            .foregroundColor(Theme.islamicGreen)
                    }
                }
                .onChange(of: quranDailyGoal) { _, _ in
                    saveSettings()
                }
            }

            
            Section(header: Text(language == "ar" ? "خلفية القراءة" : (language == "en" ? "Reader Background" : "Lese-Hintergrund"))) {
                Picker(language == "ar" ? "المظهر" : (language == "en" ? "Theme" : "Hintergrund"), selection: $quranTheme) {
                    Text(language == "ar" ? "تلقائي" : (language == "en" ? "System" : "System")).tag("system")
                    Text(language == "ar" ? "فاتح" : (language == "en" ? "Light" : "Hell")).tag("light")
                    Text(language == "ar" ? "سيبيا" : (language == "en" ? "Sepia" : "Sepia")).tag("sepia")
                    Text(language == "ar" ? "داكن" : (language == "en" ? "Dark" : "Dunkel")).tag("dark")
                }
                .pickerStyle(.segmented)
            }
            

        }
        .navigationTitle(L10n.tr("koran_sec", language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let s = settingsList.first {
                quranDailyGoal = s.quranDailyGoal
            }
        }
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        s.quranDailyGoal = quranDailyGoal
        try? modelContext.save()
    }
}
