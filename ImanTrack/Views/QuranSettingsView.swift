import SwiftUI
import SwiftData

struct QuranSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var settingsList: [UserSettings]
    
    @State private var quranDailyGoal: Int = 20
    @AppStorage("quranFontSize") private var quranFontSize: Double = 30.0
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

            Section(header: Text(L10n.tr("reader_background", language))) {
                Picker(L10n.tr("theme", language), selection: $quranTheme) {
                    Text(L10n.tr("theme_system", language)).tag("system")
                    Text(L10n.tr("theme_light", language)).tag("light")
                    Text(L10n.tr("theme_sepia", language)).tag("sepia")
                    Text(L10n.tr("theme_dark", language)).tag("dark")
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text(L10n.tr("preview", language))) {
                HStack {
                    Spacer()
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                        .font(Theme.uthmaniFont(size: quranFontSize * 0.85))
                        .foregroundColor(Theme.getQuranTextColor(for: quranTheme, systemColorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                    Spacer()
                }
                .listRowBackground(Theme.getQuranBackgroundColor(for: quranTheme, systemColorScheme: colorScheme))
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
