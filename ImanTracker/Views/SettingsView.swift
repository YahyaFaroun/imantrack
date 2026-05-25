import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    
    @State private var quranDailyGoal: Int = 50
    
    @State private var istighfarEnabled: Bool = true
    @State private var istighfarGoal: Int = 10000
    @State private var istighfarVersion: String = "mittel"
    @State private var istighfarPerMinute: Int = 60
    @State private var salawatEnabled: Bool = true
    @State private var salawatGoal: Int = 10000
    @State private var salawatVersion: String = "mittel"
    @State private var salawatPerMinute: Int = 60
    
    @State private var subhanAllahEnabled: Bool = true
    @State private var subhanAllahGoal: Int = 33
    @State private var subhanAllahPerMinute: Int = 60
    
    @State private var alhamdulillahEnabled: Bool = true
    @State private var alhamdulillahGoal: Int = 33
    @State private var alhamdulillahPerMinute: Int = 60
    
    @State private var allahuAkbarEnabled: Bool = true
    @State private var allahuAkbarGoal: Int = 34
    @State private var allahuAkbarPerMinute: Int = 60
    
    @State private var globalTasbihTempo: Int = 60
    
    @State private var isDarkMode: Bool = true
    @State private var language: String = "de"
    @State private var adhkarAutoCount: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.tr("koran_sec", language))) {
                    Stepper(value: $quranDailyGoal, in: 1...100, step: 1) {
                        HStack {
                            Text(L10n.tr("koran_sec", language))
                            Spacer()
                            Text("\(quranDailyGoal) " + L10n.tr("pages", language))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                }
                
                Section(header: Text(L10n.tr("tasbih_sec", language))) {
                    istighfarSection
                    salawatSection
                    
                    tasbihSettingRow(title: L10n.tr("tasbih_subhanallah", language), arabicLabel: "سبحان الله وبحمده سبحان الله العظيم", isEnabled: $subhanAllahEnabled, goal: $subhanAllahGoal, saveAction: saveSettings)
                    tasbihSettingRow(title: L10n.tr("tasbih_alhamdulillah", language), arabicLabel: "سبحان الله والحمد لله ولا إله إلا الله والله أكبر", isEnabled: $alhamdulillahEnabled, goal: $alhamdulillahGoal, saveAction: saveSettings)
                    tasbihSettingRow(title: L10n.tr("tasbih_lahawla", language), arabicLabel: "لا حول ولا قوة إلا بالله", isEnabled: $allahuAkbarEnabled, goal: $allahuAkbarGoal, saveAction: saveSettings)
                }
                
                Section(header: Text(L10n.tr("adhkar_sec", language))) {
                    Picker(L10n.tr("adhkar_count_mode", language), selection: $adhkarAutoCount) {
                        Text(L10n.tr("adhkar_count_manual", language)).tag(false)
                        Text(L10n.tr("adhkar_count_auto", language)).tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(L10n.tr("appearance_sec", language))) {
                    Toggle(L10n.tr("dark_mode", language), isOn: $isDarkMode)
                }
                
                Section(header: Text(L10n.tr("language", language))) {
                    Picker(L10n.tr("language", language), selection: $language) {
                        Text("Deutsch").tag("de")
                        Text("English").tag("en")
                        Text("العربية").tag("ar")
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
    

    
    private var istighfarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(language == "ar" ? "الاستغفار" : "Istighfar", isOn: $istighfarEnabled)
                .onChange(of: istighfarEnabled) { _, _ in saveSettings() }
            
            if istighfarEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper(value: $istighfarGoal, in: 100...50000, step: 100) {
                        HStack {
                            if language != "ar" {
                                Text("أستغفر الله")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(formatNumber(istighfarGoal))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .onChange(of: istighfarGoal) { _, _ in saveSettings() }
                }
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var salawatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(language == "ar" ? "الصلاة على النبي" : "Salawat", isOn: $salawatEnabled)
                .onChange(of: salawatEnabled) { _, _ in saveSettings() }
            
            if salawatEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper(value: $salawatGoal, in: 100...50000, step: 100) {
                        HStack {
                            if language != "ar" {
                                Text("اللهم صل على محمد")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(formatNumber(salawatGoal))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .onChange(of: salawatGoal) { _, _ in saveSettings() }
                }
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    private func tasbihSettingRow(title: String, arabicLabel: String, isEnabled: Binding<Bool>, goal: Binding<Int>, saveAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: isEnabled)
                .onChange(of: isEnabled.wrappedValue) { _, _ in saveAction() }
            if isEnabled.wrappedValue {
                Stepper(value: goal, in: 10...10000, step: 10) {
                    HStack {
                        if language != "ar" {
                            Text(arabicLabel)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(goal.wrappedValue)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.islamicGreen)
                    }
                }
                .padding(.leading)
                .onChange(of: goal.wrappedValue) { _, _ in saveAction() }
            }
        }
    }
    

    
    private func loadSettings() {
        if let s = settingsList.first {
            if s.quranDailyGoal >= 10 {
                quranDailyGoal = max(1, min(100, s.quranDailyGoal / 20))
                s.quranDailyGoal = quranDailyGoal
                try? modelContext.save()
            } else {
                quranDailyGoal = s.quranDailyGoal
            }
            
            istighfarEnabled = s.istighfarEnabled
            istighfarGoal = s.istighfarGoal
            istighfarVersion = s.istighfarVersion
            istighfarPerMinute = s.istighfarPerMinute == 0 ? 60 : s.istighfarPerMinute
            
            salawatEnabled = s.salawatEnabled
            salawatGoal = s.salawatGoal
            salawatVersion = s.salawatVersion
            salawatPerMinute = s.salawatPerMinute == 0 ? 60 : s.salawatPerMinute
            
            subhanAllahEnabled = s.subhanAllahEnabled
            subhanAllahGoal = s.subhanAllahGoal
            subhanAllahPerMinute = s.subhanAllahPerMinute
            
            alhamdulillahEnabled = s.alhamdulillahEnabled
            alhamdulillahGoal = s.alhamdulillahGoal
            alhamdulillahPerMinute = s.alhamdulillahPerMinute
            
            allahuAkbarEnabled = s.allahuAkbarEnabled
            allahuAkbarGoal = s.allahuAkbarGoal
            allahuAkbarPerMinute = s.allahuAkbarPerMinute
            
            globalTasbihTempo = s.globalTasbihTempo == 0 ? 60 : s.globalTasbihTempo
            
            isDarkMode = s.isDarkMode
            language = s.language
            adhkarAutoCount = s.adhkarAutoCount
        }
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        
        s.quranDailyGoal = quranDailyGoal
        
        s.istighfarEnabled = istighfarEnabled
        s.istighfarGoal = istighfarGoal
        s.istighfarVersion = istighfarVersion
        s.istighfarPerMinute = istighfarPerMinute
        
        s.salawatEnabled = salawatEnabled
        s.salawatGoal = salawatGoal
        s.salawatVersion = salawatVersion
        s.salawatPerMinute = salawatPerMinute
        
        s.subhanAllahEnabled = subhanAllahEnabled
        s.subhanAllahGoal = subhanAllahGoal
        s.subhanAllahPerMinute = subhanAllahPerMinute
        
        s.alhamdulillahEnabled = alhamdulillahEnabled
        s.alhamdulillahGoal = alhamdulillahGoal
        s.alhamdulillahPerMinute = alhamdulillahPerMinute
        
        s.allahuAkbarEnabled = allahuAkbarEnabled
        s.allahuAkbarGoal = allahuAkbarGoal
        s.allahuAkbarPerMinute = allahuAkbarPerMinute
        
        s.globalTasbihTempo = globalTasbihTempo
        
        s.isDarkMode = isDarkMode
        s.language = language
        s.adhkarAutoCount = adhkarAutoCount
        
        try? modelContext.save()
    }
}
