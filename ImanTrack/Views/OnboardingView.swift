import SwiftUI
import CoreLocation
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) var modelContext
    @Query var settings: [UserSettings]
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    @State var currentPage = 0
    @State var hasLocationPermission: Bool = false
    
    @State private var tempQuranGoal: Int = 5
    @State private var tempIstighfarGoal: Int = 1000
    @State private var tempSalawatGoal: Int = 500
    @State private var tempSubhanAllahGoal: Int = 100
    @State private var tempSpeedStep: Int = 1
    
    private func setupDefaultOnboardingGoals() {
        let s: UserSettings
        if let first = settings.first {
            s = first
        } else {
            s = UserSettings()
            modelContext.insert(s)
        }
        
        if s.quranDailyGoal == 20 { s.quranDailyGoal = 5 }
        if s.istighfarGoal == 5000 || s.istighfarGoal == 100 { s.istighfarGoal = 1000 }
        if s.salawatGoal == 2000 || s.salawatGoal == 100 { s.salawatGoal = 500 }
        if s.subhanAllahGoal == 1000 { s.subhanAllahGoal = 100 }
        if s.alhamdulillahGoal == 1000 { s.alhamdulillahGoal = 100 }
        if s.allahuAkbarGoal == 1000 { s.allahuAkbarGoal = 100 }
        if s.laIlahaIllallahGoal == 500 { s.laIlahaIllallahGoal = 100 }
        
        tempQuranGoal = s.quranDailyGoal
        tempIstighfarGoal = s.istighfarGoal
        tempSalawatGoal = s.salawatGoal
        tempSubhanAllahGoal = s.subhanAllahGoal
        tempSpeedStep = s.defaultAdhkarSpeedStep
        try? modelContext.save()
    }
    
    private func saveGoals() {
        let s: UserSettings
        if let first = settings.first {
            s = first
        } else {
            s = UserSettings()
            modelContext.insert(s)
        }
        s.quranDailyGoal = tempQuranGoal
        s.istighfarGoal = tempIstighfarGoal
        s.salawatGoal = tempSalawatGoal
        s.subhanAllahGoal = tempSubhanAllahGoal
        s.defaultAdhkarSpeedStep = tempSpeedStep
        UserDefaults.standard.set(tempSpeedStep, forKey: "defaultAdhkarSpeedStep")
        try? modelContext.save()
    }
    
    #if os(iOS)
    let pub = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    #else
    let pub = NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
    #endif
    
    // SEITE 3b – Quran Zieleingabe
    @ViewBuilder
    private func quranGoalOnboardingCard() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(L10n.tr("onboarding_quran_goal_title", language))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            Text(L10n.tr("onboarding_quran_goal_desc", language))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer().frame(height: 20)
            
            VStack(spacing: 16) {
                Text("\(tempQuranGoal) " + L10n.tr("onboarding_quran_goal_unit", language))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.islamicGreen)
                
                Stepper("", value: $tempQuranGoal, in: 1...20, step: 1)
                    .labelsHidden()
                    .onChange(of: tempQuranGoal) { _, _ in
                        saveGoals()
                    }
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
            }) {
                Text(L10n.tr("onboarding_next", language))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.islamicGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
    
    // SEITE 5b – Tasbih Zieleingabe
    @ViewBuilder
    private func tasbihGoalOnboardingCard() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(L10n.tr("onboarding_tasbih_goal_title", language))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            Text(L10n.tr("onboarding_tasbih_goal_desc", language))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            ScrollView {
                VStack(spacing: 16) {
                    tasbihGoalRow(title: "Istighfar", value: $tempIstighfarGoal, range: 100...50000, step: 100)
                    tasbihGoalRow(title: "Salawat", value: $tempSalawatGoal, range: 100...50000, step: 100)
                    tasbihGoalRow(title: "Subhanallahi wa bihamdihi", value: $tempSubhanAllahGoal, range: 10...10000, step: 10)
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
            }) {
                Text(L10n.tr("onboarding_next", language))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.islamicGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "'"
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    @ViewBuilder
    private func tasbihGoalRow(title: String, value: Binding<Int>, range: ClosedRange<Int> = 10...50000, step: Int = 50) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            HStack {
                Text("\(formatNumber(value.wrappedValue))")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.islamicGreen)
                    .frame(width: 90, alignment: .leading)
                
                Spacer()
                
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
                    .onChange(of: value.wrappedValue) { _, _ in
                        saveGoals()
                    }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var language: String {
        if let lang = settings.first?.language {
            return lang
        }
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        return ["de", "en", "ar"].contains(locale) ? locale : "en"
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack {
                // Header-Bereich mit Skip-Button oben rechts
                HStack {
                    Spacer()
                    if currentPage < 7 {
                        Button(action: {
                            withAnimation {
                                currentPage = 7
                            }
                        }) {
                            Text(L10n.tr("onboarding_skip", language))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(height: 44)
                
                TabView(selection: $currentPage) {
                    // SEITE 1 – Willkommen & Einstieg
                    onboardingCard(
                        icon: "moon.stars.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_page1_title", language),
                        text: L10n.tr("onboarding_page1_desc", language),
                        buttonText: L10n.tr("onboarding_next", language)
                    )
                    .tag(0)
                    
                    // SEITE 2 – Der islamische Tagesrhythmus
                    onboardingCard(
                        icon: "sunset.fill",
                        iconColor: .orange,
                        title: L10n.tr("onboarding_page2_title", language),
                        text: L10n.tr("onboarding_page2_desc", language),
                        actionButton: locationActionButton()
                    )
                    .tag(1)
                    
                    // SEITE 3 – Quran & automatisches Tracking
                    onboardingCard(
                        icon: "book.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_page3_title", language),
                        text: L10n.tr("onboarding_page3_desc", language),
                        buttonText: L10n.tr("onboarding_next", language)
                    )
                    .tag(2)
                    
                    // SEITE 3b – Quran Zieleingabe
                    quranGoalOnboardingCard()
                    .tag(3)
                    
                    // SEITE 4 – Deine täglichen Adhkar
                    adhkarOnboardingCard()
                        .tag(4)
                    
                    // SEITE 5 – Digitale Tasbih & Ziele
                    onboardingCard(
                        icon: "hand.tap.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_page5_title", language),
                        text: L10n.tr("onboarding_page5_desc", language),
                        buttonText: L10n.tr("onboarding_next", language)
                    )
                    .tag(5)
                    
                    // SEITE 5b – Tasbih Zieleingabe
                    tasbihGoalOnboardingCard()
                    .tag(6)
                    
                    // SEITE 6 – Wöchentliche Sunnah-Highlights
                    onboardingCard(
                        icon: "sparkles",
                        iconColor: .yellow,
                        title: L10n.tr("onboarding_page6_title", language),
                        text: L10n.tr("onboarding_page6_desc", language),
                        buttonText: L10n.tr("onboarding_page6_btn", language),
                        isLastScreen: true
                    )
                    .tag(7)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                #endif
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkLocationPermission()
            setupDefaultOnboardingGoals()
        }
        .onReceive(pub) { _ in
            checkLocationPermission()
        }
    }
    
    // Eine wiederverwendbare Onboarding-Karte
    @ViewBuilder
    private func onboardingCard(
        icon: String,
        iconColor: Color,
        title: String,
        text: String,
        buttonText: String? = nil,
        actionButton: AnyView? = nil,
        isLastScreen: Bool = false
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon mit edlem Glow/Hintergrund
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundColor(iconColor)
            }
            .padding(.bottom, 16)
            
            // Titel
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            // Beschreibungstext
            Text(text)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Aktionsbutton
            if let button = actionButton {
                button
                    .padding(.bottom, 60)
            } else if let btnText = buttonText {
                Button(action: {
                    if isLastScreen {
                        finishOnboarding()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }) {
                    Text(btnText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.islamicGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            } else {
                Spacer()
                    .frame(height: 114)
            }
        }
    }
    
    // Spezielle Onboarding-Karte für die Adhkar (Seite 4)
    @ViewBuilder
    private func adhkarOnboardingCard() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Titel
            Text(L10n.tr("onboarding_page4_title", language))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            // Beschreibung (Intro)
            Text(L10n.tr("onboarding_page4_desc", language))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            // Liste
            VStack(alignment: .leading, spacing: 16) {
                adhkarRow(icon: "moon.fill", iconColor: .blue, text: L10n.tr("onboarding_page4_sleep", language))
                adhkarRow(icon: "sun.max.fill", iconColor: .yellow, text: L10n.tr("onboarding_page4_morning", language))
                adhkarRow(icon: "sunset.fill", iconColor: .orange, text: L10n.tr("onboarding_page4_evening", language))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            
            // Abschlusstext
            Text(L10n.tr("onboarding_page4_footer", language))
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            
            Spacer()
            
            // Weiter Button
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
            }) {
                Text(L10n.tr("onboarding_next", language))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.islamicGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
    
    @ViewBuilder
    private func adhkarRow(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
    
    // Button für die Standortfreigabe (HIG Guideline 5.1.1(iv) konform)
    private func locationActionButton() -> AnyView {
        AnyView(
            Button(action: {
                let status = CLLocationManager().authorizationStatus
                if status == .notDetermined {
                    LocationAndSolarManager.shared.requestAuthorization()
                }
                withAnimation {
                    currentPage = 2
                }
            }) {
                Text(L10n.tr("onboarding_next", language))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.islamicGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
        )
    }
    
    private func checkLocationPermission() {
        let status = CLLocationManager().authorizationStatus
        #if os(macOS)
        hasLocationPermission = (status == .authorizedAlways)
        #else
        hasLocationPermission = (status == .authorizedWhenInUse || status == .authorizedAlways)
        #endif
    }
    
    private func finishOnboarding() {
        let s = settings.first ?? UserSettings()
        if settings.isEmpty {
            modelContext.insert(s)
            s.alhamdulillahGoal = 100
            s.allahuAkbarGoal = 100
            s.laIlahaIllallahGoal = 100
        }
        
        s.quranDailyGoal = tempQuranGoal
        s.istighfarGoal = tempIstighfarGoal
        s.salawatGoal = tempSalawatGoal
        s.subhanAllahGoal = tempSubhanAllahGoal
        s.defaultAdhkarSpeedStep = tempSpeedStep
        UserDefaults.standard.set(tempSpeedStep, forKey: "defaultAdhkarSpeedStep")
        
        try? modelContext.save()
        
        withAnimation {
            hasSeenOnboarding = true
        }
    }
}
