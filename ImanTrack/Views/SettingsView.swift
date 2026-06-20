import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    
    @State private var isDarkMode: Bool = true
    @State private var language: String = "de"
    
    var body: some View {
        NavigationStack {
            Form {
                // Bereich 1: Features (Als NavigationLinks)
                Section(header: Text(language == "ar" ? "المميزات" : (language == "en" ? "Features" : "Funktionen"))) {
                    NavigationLink(destination: QuranSettingsView()) {
                        Label {
                            Text(L10n.tr("koran_sec", language))
                        } icon: {
                            Image(systemName: "book.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    NavigationLink(destination: TasbihSettingsView()) {
                        Label {
                            Text(L10n.tr("tasbih_sec", language))
                        } icon: {
                            Image(systemName: "circle.grid.3x3.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    NavigationLink(destination: DhikrSettingsView()) {
                        Label {
                            Text(L10n.tr("adhkar_sec", language))
                        } icon: {
                            Image(systemName: "doc.plaintext.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    NavigationLink(destination: FajrSettingsView()) {
                        Label {
                            Text(L10n.tr("fajr_sec", language))
                        } icon: {
                            Image(systemName: "alarm.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                }
                
                // Bereich 2: Allgemein (Direkt sichtbar)
                Section(header: Text(language == "ar" ? "عام" : (language == "en" ? "General" : "Allgemein"))) {
                    // Appearance: Dark Mode Toggle
                    Toggle(L10n.tr("dark_mode", language), isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _, _ in
                            saveSettings()
                        }
                    
                    // Sprache
                    Picker(L10n.tr("language", language), selection: $language) {
                        Text("Deutsch").tag("de")
                        Text("English").tag("en")
                        Text("العربية").tag("ar")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: language) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "language")
                        saveSettings()
                    }
                }
            }
            .navigationTitle(L10n.tr("settings", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.tr("done", language)) {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    private func loadSettings() {
        if let s = settingsList.first {
            isDarkMode = s.isDarkMode
            language = s.language
        }
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        s.isDarkMode = isDarkMode
        s.language = language
        UserDefaults.standard.set(language, forKey: "language")
        try? modelContext.save()
    }
}

