import SwiftUI
import SwiftData

struct TasbihSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @Query(sort: \CustomTasbih.createdAt, order: .forward) private var customTasbihs: [CustomTasbih]
    
    @State private var showAddCustomDhikr = false
    @State private var newDhikrTitle = ""
    @State private var newDhikrArabic = ""
    @State private var newDhikrTransliteration = ""
    @State private var newDhikrGoal = 100
    
    @State private var tasbihAutoCount: Bool = true
    @State private var tasbihVibrationEnabled: Bool = true
    
    @State private var istighfarEnabled: Bool = true
    @State private var istighfarGoal: Int = 5000
    
    @State private var salawatEnabled: Bool = true
    @State private var salawatGoal: Int = 2000
    
    @State private var subhanAllahEnabled: Bool = true
    @State private var subhanAllahGoal: Int = 1000
    
    @State private var alhamdulillahEnabled: Bool = true
    @State private var alhamdulillahGoal: Int = 1000
    
    @State private var allahuAkbarEnabled: Bool = true
    @State private var allahuAkbarGoal: Int = 1000
    
    @State private var laIlahaIllallahEnabled: Bool = true
    @State private var laIlahaIllallahGoal: Int = 500
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    var body: some View {
        Form {
            Section(header: Text(L10n.tr("tasbih_count_mode", language))) {
                Picker(L10n.tr("tasbih_count_mode", language), selection: $tasbihAutoCount) {
                    Text(L10n.tr("adhkar_count_manual", language)).tag(false)
                    Text(L10n.tr("adhkar_count_auto", language)).tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: tasbihAutoCount) { _, _ in saveSettings() }
            }
            
            Section {
                Toggle(L10n.tr("vibration_feedback", language), isOn: $tasbihVibrationEnabled)
                    .onChange(of: tasbihVibrationEnabled) { _, _ in saveSettings() }
            }
            
            Section(header: Text(L10n.tr("versions", language))) {
                tasbihSettingRow(title: L10n.tr("tasbih_type_istighfar", language), arabicLabel: "أستغفر الله", isEnabled: $istighfarEnabled, goal: $istighfarGoal, saveAction: saveSettings, minVal: 100, maxVal: 50000, step: 100)
                
                tasbihSettingRow(title: L10n.tr("tasbih_type_salawat", language), arabicLabel: "اللهم صل على محمد", isEnabled: $salawatEnabled, goal: $salawatGoal, saveAction: saveSettings, minVal: 100, maxVal: 50000, step: 100)
                
                tasbihSettingRow(title: L10n.tr("tasbih_subhanallah", language), arabicLabel: "سبحان الله وبحمده", isEnabled: $subhanAllahEnabled, goal: $subhanAllahGoal, saveAction: saveSettings, minVal: 10, maxVal: 10000, step: 10)
                
                tasbihSettingRow(title: L10n.tr("tasbih_alhamdulillah", language), arabicLabel: "الحمد لله", isEnabled: $alhamdulillahEnabled, goal: $alhamdulillahGoal, saveAction: saveSettings, minVal: 10, maxVal: 10000, step: 10)
                
                tasbihSettingRow(title: L10n.tr("tasbih_lahawla", language), arabicLabel: "لا حول ولا قوة إلا بالله", isEnabled: $allahuAkbarEnabled, goal: $allahuAkbarGoal, saveAction: saveSettings, minVal: 10, maxVal: 10000, step: 10)
                
                tasbihSettingRow(title: L10n.tr("tasbih_type_lailahaillallah", language), arabicLabel: "لا إله إلا الله", isEnabled: $laIlahaIllallahEnabled, goal: $laIlahaIllallahGoal, saveAction: saveSettings, minVal: 10, maxVal: 10000, step: 10)
            }
            
            Section(header: Text(language == "ar" ? "تسبيح مخصص" : (language == "en" ? "Custom Dhikr" : "Eigene Dhikr"))) {
                ForEach(customTasbihs) { custom in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(custom.title)
                                    .font(.headline)
                                if !custom.arabic.isEmpty {
                                    Text(custom.arabic)
                                        .font(.caption)
                                        .foregroundColor(Theme.islamicGreen)
                                }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                modelContext.delete(custom)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Toggle(language == "ar" ? "تفعيل" : (language == "en" ? "Enabled" : "Aktiviert"), isOn: Binding(
                            get: { custom.isEnabled },
                            set: { newValue in
                                custom.isEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                        
                        if custom.isEnabled {
                            Stepper(value: Binding(
                                get: { custom.goal },
                                set: { newValue in
                                    custom.goal = newValue
                                    try? modelContext.save()
                                }
                            ), in: 10...100000, step: 10) {
                                HStack {
                                    Spacer()
                                    Text("\(formatNumber(custom.goal))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.islamicGreen)
                                }
                            }
                            .padding(.leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Button(action: { showAddCustomDhikr = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.islamicGreen)
                        Text(language == "ar" ? "إضافة ذكر جديد" : (language == "en" ? "Add Custom Dhikr" : "Neuen Dhikr hinzufügen"))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("tasbih_sec", language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let s = settingsList.first {
                tasbihAutoCount = s.tasbihAutoCount
                tasbihVibrationEnabled = s.tasbihVibrationEnabled
                
                istighfarEnabled = s.istighfarEnabled
                istighfarGoal = s.istighfarGoal
                
                salawatEnabled = s.salawatEnabled
                salawatGoal = s.salawatGoal
                
                subhanAllahEnabled = s.subhanAllahEnabled
                subhanAllahGoal = s.subhanAllahGoal
                
                alhamdulillahEnabled = s.alhamdulillahEnabled
                alhamdulillahGoal = s.alhamdulillahGoal
                
                allahuAkbarEnabled = s.allahuAkbarEnabled
                allahuAkbarGoal = s.allahuAkbarGoal
                
                laIlahaIllallahEnabled = s.laIlahaIllallahEnabled
                laIlahaIllallahGoal = s.laIlahaIllallahGoal == 0 ? 500 : s.laIlahaIllallahGoal
            }
        }
        .sheet(isPresented: $showAddCustomDhikr) {
            NavigationStack {
                Form {
                    Section(header: Text(language == "ar" ? "تفاصيل الذكر" : (language == "en" ? "Dhikr Details" : "Dhikr Details"))) {
                        TextField(language == "ar" ? "الاسم" : (language == "en" ? "Title / Translation" : "Titel / Übersetzung"), text: $newDhikrTitle)
                        TextField(language == "ar" ? "النص العربي (اختياري)" : (language == "en" ? "Arabic Text (Optional)" : "Arabischer Text (Optional)"), text: $newDhikrArabic)
                            .environment(\.layoutDirection, .rightToLeft)
                        TextField(language == "ar" ? "اللفظ اللاتيني (اختياري)" : (language == "en" ? "Transliteration (Optional)" : "Transliteration (Optional)"), text: $newDhikrTransliteration)
                    }
                    
                    Section(header: Text(L10n.tr("daily_goal", language))) {
                        Stepper(value: $newDhikrGoal, in: 10...100000, step: 10) {
                            HStack {
                                Spacer()
                                Text("\(formatNumber(newDhikrGoal))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.islamicGreen)
                            }
                        }
                    }
                }
                .navigationTitle(language == "ar" ? "ذكر جديد" : (language == "en" ? "New Dhikr" : "Neuer Dhikr"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.tr("cancel", language)) {
                            showAddCustomDhikr = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.tr("save", language)) {
                            addCustomTasbih()
                        }
                        .disabled(newDhikrTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
    
    private func addCustomTasbih() {
        let trimmedTitle = newDhikrTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newCustom = CustomTasbih(
            title: trimmedTitle,
            arabic: newDhikrArabic.trimmingCharacters(in: .whitespacesAndNewlines),
            transliteration: newDhikrTransliteration.trimmingCharacters(in: .whitespacesAndNewlines),
            goal: newDhikrGoal
        )
        modelContext.insert(newCustom)
        try? modelContext.save()
        
        // Reset form
        newDhikrTitle = ""
        newDhikrArabic = ""
        newDhikrTransliteration = ""
        newDhikrGoal = 100
        showAddCustomDhikr = false
    }
    
    private func saveSettings() {
        let s = settingsList.first ?? UserSettings()
        if settingsList.isEmpty {
            modelContext.insert(s)
        }
        
        s.tasbihAutoCount = tasbihAutoCount
        s.tasbihVibrationEnabled = tasbihVibrationEnabled
        
        s.istighfarEnabled = istighfarEnabled
        s.istighfarGoal = istighfarGoal
        
        s.salawatEnabled = salawatEnabled
        s.salawatGoal = salawatGoal
        
        s.subhanAllahEnabled = subhanAllahEnabled
        s.subhanAllahGoal = subhanAllahGoal
        
        s.alhamdulillahEnabled = alhamdulillahEnabled
        s.alhamdulillahGoal = alhamdulillahGoal
        
        s.allahuAkbarEnabled = allahuAkbarEnabled
        s.allahuAkbarGoal = allahuAkbarGoal
        
        s.laIlahaIllallahEnabled = laIlahaIllallahEnabled
        s.laIlahaIllallahGoal = laIlahaIllallahGoal
        
        try? modelContext.save()
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    private func tasbihSettingRow(title: String, arabicLabel: String, isEnabled: Binding<Bool>, goal: Binding<Int>, saveAction: @escaping () -> Void, minVal: Int, maxVal: Int, step: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: isEnabled)
                .onChange(of: isEnabled.wrappedValue) { _, _ in saveAction() }
            if isEnabled.wrappedValue {
                Stepper(value: goal, in: minVal...maxVal, step: step) {
                    HStack {
                        if language != "ar" {
                            Text(arabicLabel)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(formatNumber(goal.wrappedValue))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.islamicGreen)
                    }
                }
                .padding(.leading)
                .onChange(of: goal.wrappedValue) { _, _ in saveAction() }
            }
        }
        .padding(.vertical, 4)
    }
}
