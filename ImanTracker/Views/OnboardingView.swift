import SwiftUI
import CoreLocation
import SwiftData

struct OnboardingView: View {
    @Query private var settings: [UserSettings]
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var hasLocationPermission: Bool = false
    
    // Timer oder Notification-Observer zur Überprüfung der Berechtigung, wenn der Benutzer aus den Einstellungen zurückkehrt
    let pub = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    private var language: String {
        settings.first?.language ?? "de"
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack {
                // Header-Bereich mit Skip-Button oben rechts
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button(action: {
                            withAnimation {
                                currentPage = 2
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
                    // Screen 1: Willkommen
                    onboardingCard(
                        icon: "moon.stars.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_welcome_title", language),
                        text: L10n.tr("onboarding_welcome_desc", language),
                        isFirstScreen: true
                    )
                    .tag(0)
                    
                    // Screen 2: Der Islamische Tag & Standort
                    onboardingCard(
                        icon: "sunset.fill",
                        iconColor: .orange,
                        title: L10n.tr("onboarding_sunnah_title", language),
                        text: L10n.tr("onboarding_sunnah_desc", language),
                        actionButton: locationActionButton()
                    )
                    .tag(1)
                    
                    // Screen 3: Bereit
                    onboardingCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Theme.islamicGreen,
                        title: L10n.tr("onboarding_ready_title", language),
                        text: L10n.tr("onboarding_ready_desc", language),
                        actionButton: startAppActionButton()
                    )
                    .tag(2)
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
    
    // Button für die Standortfreigabe
    private func locationActionButton() -> AnyView {
        AnyView(
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
            .padding(.horizontal, 32)
        )
    }
    
    // Button zum Starten der App
    private func startAppActionButton() -> AnyView {
        AnyView(
            Button(action: {
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
}

#Preview {
    OnboardingView()
}
