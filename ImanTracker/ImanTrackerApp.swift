import SwiftUI
import SwiftData

@main
struct ImanTrackerApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
            DailyRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
