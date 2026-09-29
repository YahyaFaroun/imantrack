import XCTest

final class ImanTrackUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureRealPermissionSheetAndBanner() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        
        addUIInterruptionMonitor(withDescription: "Location Dialog") { (alert) -> Bool in
            if alert.buttons["Beim Verwenden der App erlauben"].exists {
                alert.buttons["Beim Verwenden der App erlauben"].tap()
                return true
            }
            if alert.buttons["Allow While Using App"].exists {
                alert.buttons["Allow While Using App"].tap()
                return true
            }
            return false
        }
        
        app.launch()
        app.tap() // trigger interruption handler if alert is shown
        
        // 1. Navigate to Adhkar tab
        let tabBars = app.tabBars
        if tabBars.buttons.count > 1 {
            tabBars.buttons.element(boundBy: 1).tap()
        }
        
        sleep(2)
        
        // 2. Tap on first session card in AdhkarOverviewView
        let scrollViews = app.scrollViews
        if scrollViews.buttons.count > 0 {
            scrollViews.buttons.element(boundBy: 0).tap()
        }
        
        sleep(2)
        
        // 3. Complete session inside AdhkarSessionView
        let retroButton = app.buttons["Als gelesen markieren (retro-aktiv)"]
        let finishButton = app.buttons["Alhamdulillah, fertig"]
        
        if retroButton.exists {
            retroButton.tap()
        } else if finishButton.exists && finishButton.isEnabled {
            finishButton.tap()
        } else {
            let closeButton = app.buttons["xmark"]
            if closeButton.exists {
                closeButton.tap()
            }
        }
        
        // Wait 2 seconds for dismissal animation + 0.4s sheet presentation delay
        sleep(3)
        
        // Capture live real screenshot of NotificationPermissionSheet on screen
        let screenshot1 = XCUIScreen.main.screenshot()
        let path1 = "/Users/princepalestine/.gemini/antigravity/brain/c988de47-d5c3-46a8-a524-9c9d00f843e8/real_permission_sheet.png"
        try? screenshot1.pngRepresentation.write(to: URL(fileURLWithPath: path1))
        print("[RAW LOG] REAL SCREENSHOT 1 WRITTEN TO: \(path1)")
        
        // 4. Tap "Später" on NotificationPermissionSheet if visible
        let spaterButton = app.buttons["Später"]
        if spaterButton.exists {
            spaterButton.tap()
        }
        
        sleep(1)
        
        // 5. Navigate to Today tab & open Settings gear
        let tabBars2 = app.tabBars
        if tabBars2.buttons.count > 2 {
            tabBars2.buttons.element(boundBy: 2).tap()
        }
        
        sleep(2)
        
        let gearButton = app.buttons["gearshape.fill"]
        if gearButton.exists {
            gearButton.tap()
            sleep(1)
            
            let dhikrSettings = app.buttons["Adhkar"]
            if dhikrSettings.exists {
                dhikrSettings.tap()
                sleep(1)
                
                // Capture live screenshot of Settings Banner
                let screenshot2 = XCUIScreen.main.screenshot()
                let path2 = "/Users/princepalestine/.gemini/antigravity/brain/c988de47-d5c3-46a8-a524-9c9d00f843e8/real_denied_banner.png"
                try? screenshot2.pngRepresentation.write(to: URL(fileURLWithPath: path2))
                print("[RAW LOG] REAL SCREENSHOT 2 WRITTEN TO: \(path2)")
            }
        }
    }
}
