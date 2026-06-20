import SwiftUI
import CoreLocation
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    @State private var currentPage = 0
    @State private var hasLocationPermission: Bool = false
    @State private var quranGoal: Int = 20
    @State private var istighfarGoal: Int = 1000
    @State private var salawatGoal: Int = 1000
    
    // Timer oder Notification-Observer zur Überprüfung der Berechtigung, wenn der Benutzer aus den Einstellungen zurückkehrt
    let pub = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

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
                    if currentPage < 3 {
                        Button(action: {
                            withAnimation {
                                currentPage = 3
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
                    // Screen 0: Willkommen
                    onboardingCard(
                        icon: "moon.stars.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_welcome_title", language),
                        text: L10n.tr("onboarding_welcome_desc", language),
                        isFirstScreen: true
                    )
                    .tag(0)
                    
                    // Screen 1: Der Islamische Tag & Standort
                    onboardingCard(
                        icon: "sunset.fill",
                        iconColor: .orange,
                        title: L10n.tr("onboarding_sunnah_title", language),
                        text: L10n.tr("onboarding_sunnah_desc", language),
                        actionButton: locationActionButton()
                    )
                    .tag(1)
                    
                    // Screen 2: Tagesziele
                    goalsOnboardingCard()
                        .tag(2)
                    
                    // Screen 3: Bereit
                    onboardingCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_ready_title", language),
                        text: L10n.tr("onboarding_ready_desc", language),
                        actionButton: startAppActionButton()
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkLocationPermission()
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
        isFirstScreen: Bool = false,
        actionButton: AnyView? = nil
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
            
            // Optionaler Aktionsbutton oder Platzhalter
            if let button = actionButton {
                button
                    .padding(.bottom, 60)
            } else if isFirstScreen {
                // Weiter Button für Screen 1
                Button(action: {
                    withAnimation {
                        currentPage = 1
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
            } else {
                Spacer()
                    .frame(height: 114)
            }
        }
    }
    
    // Onboarding-Karte für die Tagesziele
    @ViewBuilder
    private func goalsOnboardingCard() -> some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Icon mit edlem Glow/Hintergrund
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "target")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 4)
            
            // Titel
            Text(L10n.tr("onboarding_goals_title", language))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
            
            // Beschreibungstext
            Text(L10n.tr("onboarding_goals_desc", language))
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            // Ziel-Auswahlelemente
            VStack(spacing: 12) {
                // Koran-Ziel
                VStack(spacing: 4) {
                    Text(L10n.tr("onboarding_quran_goal", language))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if quranGoal > 1 { quranGoal -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                        
                        Text("\(quranGoal)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 60)
                        
                        Button(action: {
                            if quranGoal < 100 { quranGoal += 1 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Theme.cardBackground)
                    .cornerRadius(10)
                }
                
                // Istighfar-Ziel
                VStack(spacing: 4) {
                    Text(L10n.tr("tasbih_type_istighfar", language))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if istighfarGoal > 500 { istighfarGoal -= 500 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                        
                        Text("\(istighfarGoal)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 80)
                        
                        Button(action: {
                            if istighfarGoal < 50000 { istighfarGoal += 500 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Theme.cardBackground)
                    .cornerRadius(10)
                }
                
                // Salawat-Ziel
                VStack(spacing: 4) {
                    Text(L10n.tr("tasbih_type_salawat", language))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if salawatGoal > 500 { salawatGoal -= 500 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                        
                        Text("\(salawatGoal)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 80)
                        
                        Button(action: {
                            if salawatGoal < 50000 { salawatGoal += 500 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.islamicGreen)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Theme.cardBackground)
                    .cornerRadius(10)
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Weiter Button
            Button(action: {
                withAnimation {
                    currentPage = 3
                }
            }) {
                Text(L10n.tr("onboarding_next", language))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.islamicGreen)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // Button für die Standortfreigabe
    private func locationActionButton() -> AnyView {
        AnyView(
            VStack(spacing: 12) {
                Button(action: {
                    LocationAndSolarManager.shared.requestAuthorization()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        checkLocationPermission()
                        if hasLocationPermission {
                            withAnimation {
                                currentPage = 2
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: hasLocationPermission ? "location.fill" : "location.circle")
                        Text(hasLocationPermission ? L10n.tr("onboarding_location_granted", language) : L10n.tr("onboarding_sunnah_btn", language))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(hasLocationPermission ? Color.gray : Theme.islamicGreen)
                    .cornerRadius(16)
                }
                .disabled(hasLocationPermission)
                
                if hasLocationPermission {
                    Button(action: {
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
                }
            }
            .padding(.horizontal, 32)
        )
    }
    
    // Button zum Starten der App
    private func startAppActionButton() -> AnyView {
        AnyView(
            Button(action: {
                saveOnboardingSettings(quranGoal: quranGoal, istighfarGoal: istighfarGoal, salawatGoal: salawatGoal)
                withAnimation {
                    hasSeenOnboarding = true
                }
            }) {
                Text(L10n.tr("onboarding_ready_btn", language))
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
    
    // Berechtigungsstatus prüfen
    private func checkLocationPermission() {
        let status = CLLocationManager().authorizationStatus
        hasLocationPermission = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    // Speichern der Ziele in den globalen UserSettings
    private func saveOnboardingSettings(quranGoal: Int, istighfarGoal: Int, salawatGoal: Int) {
        let s = settings.first ?? UserSettings()
        if settings.isEmpty {
            modelContext.insert(s)
        }
        
        s.quranDailyGoal = quranGoal
        s.istighfarGoal = istighfarGoal
        s.salawatGoal = salawatGoal
        
        if settings.isEmpty {
            s.subhanAllahGoal = 100
            s.alhamdulillahGoal = 100
            s.allahuAkbarGoal = 100
            s.laIlahaIllallahGoal = 100
        }
        
        try? modelContext.save()
    }
}
