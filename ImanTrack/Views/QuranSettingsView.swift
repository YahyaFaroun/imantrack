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
    @AppStorage("quranHideReadPages") private var quranHideReadPages: Bool = false
    
    @State private var showResetConfirmAlert = false
    
    #if DEBUG
    @AppStorage("quranShowDebugOverlay") private var quranShowDebugOverlay: Bool = false
    @State private var debugSelectedSurah: Int = 1
    @State private var debugSelectedAyah: Int = 1
    
    private var maxAyahsForDebugSurah: Int {
        QuranAPIService.shared.getVerseCount(surah: debugSelectedSurah)
    }
    #endif
    
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

            Section(header: Text(L10n.tr("quran_reading_options", language))) {
                // Toggle(L10n.tr("quran_hide_read_pages", language), isOn: $quranHideReadPages) // vorerst deaktiviert für Schritt 3
                
                Button(role: .destructive, action: {
                    showResetConfirmAlert = true
                }) {
                    Text(L10n.tr("quran_reset_khatm", language))
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
            
            #if DEBUG
            Section(header: Text("Entwickler-Optionen (Debug)")) {
                Toggle("Debug-Anzeige im Quran", isOn: $quranShowDebugOverlay)
                
                Picker("Sure", selection: $debugSelectedSurah) {
                    ForEach(1...114, id: \.self) { surahNum in
                        Text("\(surahNum). \(QuranSurah.getName(surahNum))").tag(surahNum)
                    }
                }
                .onChange(of: debugSelectedSurah) { _, _ in
                    debugSelectedAyah = 1
                }
                
                Stepper("Vers (Ayah): \(debugSelectedAyah)", value: $debugSelectedAyah, in: 1...max(1, maxAyahsForDebugSurah))
                
                Button("Lesefront auf Sure \(debugSelectedSurah), Vers \(debugSelectedAyah) setzen") {
                    if let verseIdx = QuranAPIService.shared.getVerseIndex(surah: debugSelectedSurah, ayah: debugSelectedAyah) {
                        QuranProgressStore.shared.setReadFrontier(verseIdx, modelContext: modelContext)
                        NotificationCenter.default.post(name: Notification.Name("ResetQuranStartPage"), object: nil)
                    }
                }
                .foregroundColor(.orange)
            }
            #endif
        }
        .alert(L10n.tr("quran_reset_khatm", language), isPresented: $showResetConfirmAlert) {
            Button(L10n.tr("quran_reset_khatm", language), role: .destructive) {
                QuranProgressStore.shared.resetKhatm(modelContext: modelContext)
            }
            Button(L10n.tr("cancel", language), role: .cancel) {}
        } message: {
            Text(L10n.tr("quran_reset_confirm", language))
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
