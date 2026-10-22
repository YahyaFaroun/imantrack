import SwiftUI
import SwiftData

struct QuranSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var settingsList: [UserSettings]
    @ObservedObject private var progressStore = QuranProgressStore.shared
    
    @State private var quranDailyGoal: Int = 20
    @State private var showSetPositionSheet: Bool = false
    @AppStorage("quranFontSize") private var quranFontSize: Double = 30.0
    @AppStorage("quranFontType") private var quranFontType: String = "uthmanic"
    @AppStorage("quranTheme") private var quranTheme: String = "system"
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    private var currentPositionText: String {
        if let verse = QuranAPIService.shared.getVerseAtIndex(progressStore.readFrontier) {
            return "\(QuranSurah.getName(verse.surah)), \(verse.ayah) (S. \(verse.pageNumber))"
        } else if progressStore.readFrontier >= 6236 {
            return "\(L10n.tr("quran_completed_khatmat", language)) ✓"
        }
        return "\(QuranSurah.getName(1)), 1 (S. 1)"
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("quran_reading_progress", language))) {
                HStack {
                    Text(L10n.tr("quran_current_position", language))
                    Spacer()
                    Text(currentPositionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    showSetPositionSheet = true
                }) {
                    HStack {
                        Image(systemName: "bookmark")
                        Text(L10n.tr("quran_set_position", language))
                    }
                    .foregroundColor(Theme.islamicGreen)
                }
                
                HStack {
                    Text(L10n.tr("quran_completed_khatmat", language))
                    Spacer()
                    Text("\(progressStore.khatmCount)")
                        .fontWeight(.bold)
                        .foregroundColor(Theme.islamicGreen)
                }
            }

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
        .sheet(isPresented: $showSetPositionSheet) {
            SetQuranPositionSheet(language: language)
        }
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

// MARK: - Sheet: Lesestelle manuell festlegen
struct SetQuranPositionSheet: View {
    let language: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progressStore = QuranProgressStore.shared
    
    @State private var selectedSurah: Int = 1
    @State private var selectedAyah: Int = 1
    @State private var showConfirmAlert: Bool = false
    
    private var totalAyahs: Int {
        QuranAPIService.shared.getVerseCount(surah: selectedSurah)
    }
    
    private var targetPage: Int {
        if let idx = QuranAPIService.shared.getVerseIndex(surah: selectedSurah, ayah: selectedAyah),
           let verse = QuranAPIService.shared.getVerseAtIndex(idx) {
            return verse.pageNumber
        }
        return 1
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.tr("quran_set_position", language))) {
                    Text(L10n.tr("quran_set_position_desc", language))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Picker("Sure", selection: $selectedSurah) {
                        ForEach(1...114, id: \.self) { num in
                            Text("\(num). \(QuranSurah.getName(num))").tag(num)
                        }
                    }
                    .onChange(of: selectedSurah) { _, _ in
                        selectedAyah = 1
                    }
                    
                    Picker("Vers", selection: $selectedAyah) {
                        ForEach(1...max(1, totalAyahs), id: \.self) { ayah in
                            Text("\(ayah)").tag(ayah)
                        }
                    }
                }
                
                Section(header: Text(L10n.tr("preview", language))) {
                    HStack {
                        Text(QuranSurah.getName(selectedSurah))
                            .fontWeight(.medium)
                        Spacer()
                        Text("Vers \(selectedAyah) · Seite \(targetPage)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        showConfirmAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text(L10n.tr("quran_set_position_action", language))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Theme.islamicGreen)
                        .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(L10n.tr("quran_set_position", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("cancel", language)) {
                        dismiss()
                    }
                }
            }
            .alert(L10n.tr("quran_set_position_confirm_title", language), isPresented: $showConfirmAlert) {
                Button(L10n.tr("quran_set_position_action", language), role: .destructive) {
                    if let idx = QuranAPIService.shared.getVerseIndex(surah: selectedSurah, ayah: selectedAyah) {
                        progressStore.setReadFrontierManually(toIndex: idx)
                    }
                    dismiss()
                }
                Button(L10n.tr("cancel", language), role: .cancel) {}
            } message: {
                Text(String(format: L10n.tr("quran_set_position_confirm_msg", language), QuranSurah.getName(selectedSurah), selectedAyah, targetPage))
            }
            .onAppear {
                if let currentVerse = QuranAPIService.shared.getVerseAtIndex(progressStore.readFrontier) {
                    selectedSurah = currentVerse.surah
                    selectedAyah = currentVerse.ayah
                }
            }
        }
    }
}
