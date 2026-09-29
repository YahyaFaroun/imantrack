import SwiftUI
import SwiftData
import CoreText

@main
struct ImanTrackApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    init() {
        registerFonts()
        _ = FajrAlarmManager.shared
        
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
            "UthmanicHafs1Ver18.ttf",
            "surah-name-v2.ttf",
            "me_quran.ttf",
            "me_quran_volt_newmet.ttf",
            "AmiriQuran-Regular.ttf",
            "uthmanic-shuba-v20.ttf"
        ]
        
        // Helper to map filename to expected PostScript or Family name
        func expectedFontName(for filename: String) -> String {
            switch filename {
            case "UthmanicHafs1Ver18.ttf": return "KFGQPCHAFSUthmanicScript-Regula"
            case "uthmanic-shuba-v20.ttf": return "KFGQPCShubaUthmanicScript-Regul"
            case "surah-name-v2.ttf": return "surah-name-v2"
            case "me_quran.ttf": return "me_quran"
            case "AmiriQuran-Regular.ttf": return "AmiriQuran-Regular"
            default: return (filename as NSString).deletingPathExtension
            }
        }

        for fontName in fonts {
            let fontBase = expectedFontName(for: fontName)
            if UIFont(name: fontBase, size: 12) != nil {
                print("Font \(fontBase) already available – skipping registration.")
                continue
            }
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
                    LocationAndSolarManager.shared.updateTrackingDate()
                    FajrAlarmManager.shared.scheduleFajrAlarm()
                    AdhkarReminderManager.shared.scheduleReminders(container: sharedModelContainer)
                } else if newPhase == .background || newPhase == .inactive {
                    saveReadingStateOnLifecycleChange()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                saveReadingStateOnLifecycleChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                saveReadingStateOnLifecycleChange()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func saveReadingStateOnLifecycleChange() {
        let currentVerse = UserDefaults.standard.string(forKey: "lastReadVerseId") ?? ""
        if !currentVerse.isEmpty {
            UserDefaults.standard.set(currentVerse, forKey: "lastReadVerseId")
        }
        UserDefaults.standard.synchronize()
    }
}
