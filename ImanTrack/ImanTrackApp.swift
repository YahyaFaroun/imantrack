import SwiftUI
import SwiftData
import CoreText

@main
struct ImanTrackApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    init() {
        registerFonts()
        
        // Liste alle registrierten Custom Fonts im Konsolenlog auf
        for family in UIFont.familyNames {
            let names = UIFont.fontNames(forFamilyName: family)
            for name in names {
                if name.contains("KFGQPC") || name.contains("Hafs") || name.contains("surah-name") || name.contains("me_quran") {
                    print("Found Custom Font: \(name) in family \(family)")
                }
            }
        }
    }

    private func registerFonts() {
        let fonts = [
            "UthmanicHafs_V22.ttf",
            "UthmanicHafs1Ver18.ttf",
            "surah-name-v2.ttf",
            "me_quran.ttf",
            "me_quran_volt_newmet.ttf",
            "KfgqpcHafsUthmanicScriptRegular-1jGEe.ttf",
            "KfgqpcHafsUthmanicScriptRegular-nARZ1.ttf"
        ]
        for fontName in fonts {
            guard let url = Bundle.main.url(forResource: fontName, withExtension: nil) else {
                print("Font file \(fontName) not found in bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if success {
                print("Successfully registered font: \(fontName)")
            } else {
                if let err = error?.takeRetainedValue() {
                    let description = CFErrorCopyDescription(err) as String
                    print("Failed to register font \(fontName): \(description)")
                } else {
                    print("Failed to register font \(fontName)")
                }
            }
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
            DailyRecord.self,
            CustomTasbih.self
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
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    FajrAlarmManager.shared.scheduleFajrAlarm()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
