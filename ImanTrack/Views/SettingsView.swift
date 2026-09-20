import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    @State private var isDarkMode: Bool = true
    @State private var language: String = "de"
    @State private var showSupportReportSheet: Bool = false
    
    private static let availableLanguages = [
        ("de", "Deutsch"), ("en", "English"), ("ar", "العربية"), ("fr", "Français"), ("es", "Español"),
        ("ur", "اردو"), ("id", "Bahasa Indonesia"), ("tr", "Türkçe"), ("ru", "Русский"), ("bn", "বাংলা"),
        ("ms", "Bahasa Melayu")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Bereich 1: Features (Als NavigationLinks)
                Section(header: Text(L10n.tr("settings_goals", language))) {
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
                            Image(systemName: "circle.hexagongrid.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    NavigationLink(destination: DhikrSettingsView()) {
                        Label {
                            Text(L10n.tr("adhkar_sec", language))
                        } icon: {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                }
                
                // Bereich 2: Allgemein (Direkt sichtbar)
                Section(header: Text(L10n.tr("settings_general", language))) {
                    NavigationLink(destination: FajrSettingsView()) {
                        Label {
                            Text(L10n.tr("fajr_sec", language))
                        } icon: {
                            Image(systemName: "alarm.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    // Appearance: Dark Mode Toggle
                    Toggle(L10n.tr("dark_mode", language), isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _, _ in
                            saveSettings()
                        }
                    
                    // Sprache
                    Picker(L10n.tr("language", language), selection: $language) {
                        ForEach(Self.availableLanguages, id: \.0) { lang in
                            Text(lang.1).tag(lang.0)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: language) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "language")
                        saveSettings()
                    }
                }
                
                // Bereich 3: Support
                Section(header: Text(language == "de" ? "Support" : (language == "ar" ? "الدعم والتعليمات" : "Support"))) {
                    NavigationLink(destination: FAQView()) {
                        Label {
                            Text(language == "de" ? "Häufig gestellte Fragen (FAQ)" : (language == "ar" ? "الأسئلة الشائعة" : "FAQ & Help"))
                        } icon: {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    
                    Button(action: { showSupportReportSheet = true }) {
                        HStack {
                            Label {
                                Text(language == "de" ? "Support kontaktieren" : (language == "ar" ? "تواصل مع الدعم" : "Contact Support"))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Theme.islamicGreen)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Bereich 4: Über ImanTrack / About
                Section(header: Text(language == "de" ? "Über ImanTrack" : (language == "ar" ? "عن التطبيق" : "About"))) {
                    Button(action: rateImanTrack) {
                        HStack {
                            Label {
                                Text(language == "de" ? "ImanTrack bewerten" : (language == "ar" ? "تقييم التطبيق" : "Rate ImanTrack"))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Theme.islamicGreen)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Version Footer
                Section {
                    HStack {
                        Spacer()
                        Text("ImanTrack · Version 2.1.0")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(L10n.tr("settings", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("done", language)) {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSupportReportSheet) {
                SupportReportView(language: language)
            }
            .onAppear {
                loadSettings()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    private func rateImanTrack() {
        let appStoreReviewUrl = "https://apps.apple.com/app/id6782351643?action=write-review"
        if let url = URL(string: appStoreReviewUrl) {
            UIApplication.shared.open(url)
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

