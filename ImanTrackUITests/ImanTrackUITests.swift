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

    struct QuranPosition {
        let frontier: String
        let anchor: String
        let offset: Double
        let topVerse: String
    }

    private func readQuranPosition(app: XCUIApplication) -> QuranPosition? {
        let offsetElem = app.staticTexts["debug_scroll_offset"]
        guard offsetElem.waitForExistence(timeout: 8) else { return nil }
        
        let offsetLabel = offsetElem.label
        let offsetNum = Double(offsetLabel
            .replacingOccurrences(of: "Offset: ", with: "")
            .replacingOccurrences(of: "pt", with: "")
            .trimmingCharacters(in: .whitespaces)) ?? 0.0
            
        let frontierLabel = app.staticTexts["debug_read_frontier"].label
        let anchorLabel = app.staticTexts["debug_resume_anchor"].label
        let topVerseLabel = app.staticTexts["debug_top_visible_verse"].label
        
        return QuranPosition(frontier: frontierLabel, anchor: anchorLabel, offset: offsetNum, topVerse: topVerseLabel)
    }

    private func dragScrollView(app: XCUIApplication, dyPoints: CGFloat) {
        let sv = app.scrollViews.firstMatch
        if sv.exists {
            let start = sv.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            let end = start.withOffset(CGVector(dx: 0, dy: -dyPoints))
            start.press(forDuration: 0.1, thenDragTo: end)
            Thread.sleep(forTimeInterval: 1.2)
        }
    }

    @MainActor
    func testQuranResumePositionAccuracy() throws {
        let dragDeltas: [CGFloat] = [60, 120, 180, 250, 320]
        
        for (i, dragAmount) in dragDeltas.enumerated() {
            print("\n================== TEST DURCHLAUF \(i + 1) (Drag: \(dragAmount)pt) ==================")
            let app = XCUIApplication()
            app.launchArguments = ["-hasSeenOnboarding", "YES", "-debugSetFrontier", "2:240"]
            app.launch()
            
            // Navigate to Quran tab (index 3)
            let tabBars = app.tabBars
            XCTAssertTrue(tabBars.buttons.count > 3, "Tabbar hat nicht genügend Buttons")
            tabBars.buttons.element(boundBy: 3).tap()
            Thread.sleep(forTimeInterval: 1.5)
            
            // Scroll controlled distance
            dragScrollView(app: app, dyPoints: dragAmount)
            
            guard let pos1 = readQuranPosition(app: app) else {
                XCTFail("Durchlauf \(i + 1): Pos 1 konnte nicht gelesen werden")
                continue
            }
            print("[TEST RESULT] P1 (vor Tab-Wechsel): Offset=\(pos1.offset)pt, Top=\(pos1.topVerse), Frontier=\(pos1.frontier), Anchor=\(pos1.anchor)")
            
            // Step b: Tab wechseln (zu Heute: Tab 2) und zurück
            tabBars.buttons.element(boundBy: 2).tap()
            Thread.sleep(forTimeInterval: 1.0)
            tabBars.buttons.element(boundBy: 3).tap()
            Thread.sleep(forTimeInterval: 1.5)
            
            guard let pos2 = readQuranPosition(app: app) else {
                XCTFail("Durchlauf \(i + 1): Pos 2 konnte nach Tab-Wechsel nicht gelesen werden")
                continue
            }
            let diffTab = abs(pos2.offset - pos1.offset)
            print("[TEST RESULT] P2 (nach Tab-Wechsel): Offset=\(pos2.offset)pt, Top=\(pos2.topVerse), Diff=\(diffTab)pt, Frontier=\(pos2.frontier)")
            XCTAssertLessThanOrEqual(diffTab, 2.0, "Durchlauf \(i + 1): Abweichung nach Tab-Wechsel (\(diffTab)pt) > 2 pt")
            XCTAssertEqual(pos2.topVerse, pos1.topVerse, "Durchlauf \(i + 1): Oberster Vers nach Tab-Wechsel weicht ab")
            XCTAssertEqual(pos2.frontier, pos1.frontier, "Durchlauf \(i + 1): Lesefront nach Tab-Wechsel weicht ab")
            
            // Step c: App beenden und neu starten (OHNE -debugSetFrontier, damit Anker wiederhergestellt wird)
            app.terminate()
            let appRestart = XCUIApplication()
            appRestart.launchArguments = ["-hasSeenOnboarding", "YES"]
            appRestart.launch()
            
            let tabBarsRestart = appRestart.tabBars
            tabBarsRestart.buttons.element(boundBy: 3).tap()
            Thread.sleep(forTimeInterval: 1.5)
            
            guard let pos3 = readQuranPosition(app: appRestart) else {
                XCTFail("Durchlauf \(i + 1): Pos 3 konnte nach Neustart nicht gelesen werden")
                continue
            }
            let diffRestart = abs(pos3.offset - pos1.offset)
            print("[TEST RESULT] P3 (nach Neustart): Offset=\(pos3.offset)pt, Top=\(pos3.topVerse), Diff=\(diffRestart)pt, Frontier=\(pos3.frontier)")
            XCTAssertLessThanOrEqual(diffRestart, 2.0, "Durchlauf \(i + 1): Abweichung nach Neustart (\(diffRestart)pt) > 2 pt")
            XCTAssertEqual(pos3.topVerse, pos1.topVerse, "Durchlauf \(i + 1): Oberster Vers nach Neustart weicht ab")
            XCTAssertEqual(pos3.frontier, pos1.frontier, "Durchlauf \(i + 1): Lesefront nach Neustart weicht ab")
            
            // Prüfung: Hochscroll-Sperre nach dem Wiederherstellen
            let preUpScrollOffset = pos3.offset
            dragScrollView(app: appRestart, dyPoints: -80) // Versuch, nach oben zu scrollen
            if let posAfterUp = readQuranPosition(app: appRestart) {
                print("[TEST RESULT] Nach Versuch nach oben zu scrollen: Offset=\(posAfterUp.offset)pt (Sperre bei \(preUpScrollOffset)pt)")
                XCTAssertGreaterThanOrEqual(posAfterUp.offset, preUpScrollOffset - 1.5, "Hochscroll-Sperre wurde überwunden!")
            }
            
            // Prüfung: Nach dem Wiederherstellen weiterlesen, dann Hochscrollen versuchen (Sperre wandert mit)
            dragScrollView(app: appRestart, dyPoints: 160) // Weiterlesen
            if let posAfterAdvance = readQuranPosition(app: appRestart) {
                let advancedOffset = posAfterAdvance.offset
                print("[TEST RESULT] Nach Weiterlesen: Offset=\(advancedOffset)pt")
                dragScrollView(app: appRestart, dyPoints: -80) // Erneuter Hochscroll-Versuch
                if let posAfterSecondUp = readQuranPosition(app: appRestart) {
                    print("[TEST RESULT] Nach 2. Hochscroll-Versuch: Offset=\(posAfterSecondUp.offset)pt (Sperre sollte mitgewandert sein)")
                    XCTAssertGreaterThan(posAfterSecondUp.offset, preUpScrollOffset + 10, "Hochscroll-Sperre wanderte nicht mit nach vorne über Startwert!")
                }
            }
        }
    }

    @MainActor
    func testEdgeCasePageDivider() throws {
        print("\n================== RANDFALL 1: SEITENWECHSEL / TRENNER ==================")
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES", "-debugSetFrontier", "2:153"]
        app.launch()
        
        let tabBars = app.tabBars
        tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        // Scroll so top is in the page divider at bottom of page 23
        dragScrollView(app: app, dyPoints: 200)
        
        guard let p1 = readQuranPosition(app: app) else {
            XCTFail("Randfall 1: P1 konnte nicht gelesen werden")
            return
        }
        print("[RANDFALL 1] P1: Offset=\(p1.offset)pt, Top=\(p1.topVerse), Anchor=\(p1.anchor)")
        
        // Tab-Wechsel
        tabBars.buttons.element(boundBy: 2).tap()
        Thread.sleep(forTimeInterval: 1.0)
        tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        guard let p2 = readQuranPosition(app: app) else {
            XCTFail("Randfall 1: P2 konnte nicht gelesen werden")
            return
        }
        let diffTab = abs(p2.offset - p1.offset)
        print("[RANDFALL 1] P2 (Tab): Offset=\(p2.offset)pt, Diff=\(diffTab)pt, Top=\(p2.topVerse)")
        XCTAssertLessThanOrEqual(diffTab, 2.0, "Randfall 1 Tab-Wechsel Abweichung > 2 pt")
        
        // Neustart
        app.terminate()
        let appRestart = XCUIApplication()
        appRestart.launchArguments = ["-hasSeenOnboarding", "YES"]
        appRestart.launch()
        
        appRestart.tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        guard let p3 = readQuranPosition(app: appRestart) else {
            XCTFail("Randfall 1: P3 konnte nicht gelesen werden")
            return
        }
        let diffRestart = abs(p3.offset - p1.offset)
        print("[RANDFALL 1] P3 (Neustart): Offset=\(p3.offset)pt, Diff=\(diffRestart)pt, Top=\(p3.topVerse)")
        XCTAssertLessThanOrEqual(diffRestart, 2.0, "Randfall 1 Neustart Abweichung > 2 pt")
    }

    @MainActor
    func testEdgeCaseSurahHeaderBasmala() throws {
        print("\n================== RANDFALL 2: SURENKOPF / BASMALA (S. 50, 3:1) ==================")
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES", "-debugSetFrontier", "3:1"]
        app.launch()
        
        let tabBars = app.tabBars
        tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        // Position at top with Surenkopf/Basmala visible
        guard let p1 = readQuranPosition(app: app) else {
            XCTFail("Randfall 2: P1 konnte nicht gelesen werden")
            return
        }
        print("[RANDFALL 2] P1: Offset=\(p1.offset)pt, Top=\(p1.topVerse), Anchor=\(p1.anchor)")
        
        // Tab-Wechsel
        tabBars.buttons.element(boundBy: 2).tap()
        Thread.sleep(forTimeInterval: 1.0)
        tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        guard let p2 = readQuranPosition(app: app) else {
            XCTFail("Randfall 2: P2 konnte nicht gelesen werden")
            return
        }
        let diffTab = abs(p2.offset - p1.offset)
        print("[RANDFALL 2] P2 (Tab): Offset=\(p2.offset)pt, Diff=\(diffTab)pt, Top=\(p2.topVerse)")
        XCTAssertLessThanOrEqual(diffTab, 2.0, "Randfall 2 Tab-Wechsel Abweichung > 2 pt")
        
        // Neustart
        app.terminate()
        let appRestart = XCUIApplication()
        appRestart.launchArguments = ["-hasSeenOnboarding", "YES"]
        appRestart.launch()
        
        appRestart.tabBars.buttons.element(boundBy: 3).tap()
        Thread.sleep(forTimeInterval: 1.5)
        
        guard let p3 = readQuranPosition(app: appRestart) else {
            XCTFail("Randfall 2: P3 konnte nicht gelesen werden")
            return
        }
        let diffRestart = abs(p3.offset - p1.offset)
        print("[RANDFALL 2] P3 (Neustart): Offset=\(p3.offset)pt, Diff=\(diffRestart)pt, Top=\(p3.topVerse)")
        XCTAssertLessThanOrEqual(diffRestart, 2.0, "Randfall 2 Neustart Abweichung > 2 pt")
    }
}

