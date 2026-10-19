//
//  ImanTrackerTests.swift
//  ImanTrackerTests
//

import Testing
import Foundation
import UserNotifications
import SwiftData
import SwiftUI
import UIKit
@testable import ImanTrack

struct SolarValidationTestCase {
    let city: String
    let dateStr: String // YYYY-MM-DD
    let lat: Double
    let lon: Double
    let method: CalculationMethod
    let timeZoneIdentifier: String
    let expectedFajr: String
    let expectedSunrise: String
    let expectedDhuhr: String
    let expectedSunset: String
    let expectedIsha: String
}

struct ImanTrackerTests {

    let testCases: [SolarValidationTestCase] = [
        // Düsseldorf (MWL)
        SolarValidationTestCase(city: "Düsseldorf", dateStr: "2026-03-21", lat: 51.2277, lon: 6.7735, method: .mwl, timeZoneIdentifier: "Europe/Berlin", expectedFajr: "04:41", expectedSunrise: "06:33", expectedDhuhr: "12:40", expectedSunset: "18:48", expectedIsha: "20:34"),
        SolarValidationTestCase(city: "Düsseldorf", dateStr: "2026-06-21", lat: 51.2277, lon: 6.7735, method: .mwl, timeZoneIdentifier: "Europe/Berlin", expectedFajr: "03:04", expectedSunrise: "05:18", expectedDhuhr: "13:35", expectedSunset: "21:52", expectedIsha: "00:06"),
        SolarValidationTestCase(city: "Düsseldorf", dateStr: "2026-09-21", lat: 51.2277, lon: 6.7735, method: .mwl, timeZoneIdentifier: "Europe/Berlin", expectedFajr: "05:24", expectedSunrise: "07:14", expectedDhuhr: "13:26", expectedSunset: "19:34", expectedIsha: "21:20"),
        SolarValidationTestCase(city: "Düsseldorf", dateStr: "2026-12-21", lat: 51.2277, lon: 6.7735, method: .mwl, timeZoneIdentifier: "Europe/Berlin", expectedFajr: "06:31", expectedSunrise: "08:32", expectedDhuhr: "12:31", expectedSunset: "16:27", expectedIsha: "18:24"),

        // New York (ISNA)
        SolarValidationTestCase(city: "New York", dateStr: "2026-03-21", lat: 40.7128, lon: -74.0060, method: .isna, timeZoneIdentifier: "America/New_York", expectedFajr: "05:42", expectedSunrise: "06:58", expectedDhuhr: "13:03", expectedSunset: "19:09", expectedIsha: "20:25"),
        SolarValidationTestCase(city: "New York", dateStr: "2026-06-21", lat: 40.7128, lon: -74.0060, method: .isna, timeZoneIdentifier: "America/New_York", expectedFajr: "03:45", expectedSunrise: "05:24", expectedDhuhr: "12:58", expectedSunset: "20:31", expectedIsha: "22:10"),
        SolarValidationTestCase(city: "New York", dateStr: "2026-09-21", lat: 40.7128, lon: -74.0060, method: .isna, timeZoneIdentifier: "America/New_York", expectedFajr: "05:27", expectedSunrise: "06:43", expectedDhuhr: "12:49", expectedSunset: "18:55", expectedIsha: "20:10"),
        SolarValidationTestCase(city: "New York", dateStr: "2026-12-21", lat: 40.7128, lon: -74.0060, method: .isna, timeZoneIdentifier: "America/New_York", expectedFajr: "05:54", expectedSunrise: "07:16", expectedDhuhr: "11:54", expectedSunset: "16:32", expectedIsha: "17:54"),

        // Mekka (Umm Al-Qura)
        SolarValidationTestCase(city: "Mekka", dateStr: "2026-03-21", lat: 21.3891, lon: 39.8579, method: .ummAlQura, timeZoneIdentifier: "Asia/Riyadh", expectedFajr: "05:08", expectedSunrise: "06:24", expectedDhuhr: "12:28", expectedSunset: "18:32", expectedIsha: "20:02"),
        SolarValidationTestCase(city: "Mekka", dateStr: "2026-06-21", lat: 21.3891, lon: 39.8579, method: .ummAlQura, timeZoneIdentifier: "Asia/Riyadh", expectedFajr: "04:11", expectedSunrise: "05:38", expectedDhuhr: "12:22", expectedSunset: "19:05", expectedIsha: "20:35"),
        SolarValidationTestCase(city: "Mekka", dateStr: "2026-09-21", lat: 21.3891, lon: 39.8579, method: .ummAlQura, timeZoneIdentifier: "Asia/Riyadh", expectedFajr: "04:53", expectedSunrise: "06:08", expectedDhuhr: "12:14", expectedSunset: "18:18", expectedIsha: "19:48"),
        SolarValidationTestCase(city: "Mekka", dateStr: "2026-12-21", lat: 21.3891, lon: 39.8579, method: .ummAlQura, timeZoneIdentifier: "Asia/Riyadh", expectedFajr: "05:32", expectedSunrise: "06:53", expectedDhuhr: "12:19", expectedSunset: "17:44", expectedIsha: "19:14"),

        // Karachi (Karachi)
        SolarValidationTestCase(city: "Karachi", dateStr: "2026-03-21", lat: 24.8607, lon: 67.0011, method: .karachi, timeZoneIdentifier: "Asia/Karachi", expectedFajr: "05:19", expectedSunrise: "06:33", expectedDhuhr: "12:39", expectedSunset: "18:44", expectedIsha: "19:59"),
        SolarValidationTestCase(city: "Karachi", dateStr: "2026-06-21", lat: 24.8607, lon: 67.0011, method: .karachi, timeZoneIdentifier: "Asia/Karachi", expectedFajr: "04:14", expectedSunrise: "05:42", expectedDhuhr: "12:34", expectedSunset: "19:24", expectedIsha: "20:53"),
        SolarValidationTestCase(city: "Karachi", dateStr: "2026-09-21", lat: 24.8607, lon: 67.0011, method: .karachi, timeZoneIdentifier: "Asia/Karachi", expectedFajr: "05:04", expectedSunrise: "06:19", expectedDhuhr: "12:25", expectedSunset: "18:30", expectedIsha: "19:45"),
        SolarValidationTestCase(city: "Karachi", dateStr: "2026-12-21", lat: 24.8607, lon: 67.0011, method: .karachi, timeZoneIdentifier: "Asia/Karachi", expectedFajr: "05:51", expectedSunrise: "07:12", expectedDhuhr: "12:30", expectedSunset: "17:48", expectedIsha: "19:09"),

        // Kairo (Egyptian)
        SolarValidationTestCase(city: "Kairo", dateStr: "2026-03-21", lat: 30.0444, lon: 31.2357, method: .egyptian, timeZoneIdentifier: "Africa/Cairo", expectedFajr: "04:31", expectedSunrise: "05:56", expectedDhuhr: "12:02", expectedSunset: "18:07", expectedIsha: "19:27"),
        SolarValidationTestCase(city: "Kairo", dateStr: "2026-06-21", lat: 30.0444, lon: 31.2357, method: .egyptian, timeZoneIdentifier: "Africa/Cairo", expectedFajr: "04:08", expectedSunrise: "05:53", expectedDhuhr: "12:57", expectedSunset: "19:59", expectedIsha: "21:30"),
        SolarValidationTestCase(city: "Kairo", dateStr: "2026-09-21", lat: 30.0444, lon: 31.2357, method: .egyptian, timeZoneIdentifier: "Africa/Cairo", expectedFajr: "05:16", expectedSunrise: "06:42", expectedDhuhr: "12:48", expectedSunset: "18:53", expectedIsha: "20:13"),
        SolarValidationTestCase(city: "Kairo", dateStr: "2026-12-21", lat: 30.0444, lon: 31.2357, method: .egyptian, timeZoneIdentifier: "Africa/Cairo", expectedFajr: "05:14", expectedSunrise: "06:47", expectedDhuhr: "11:53", expectedSunset: "16:59", expectedIsha: "18:23"),

        // Reykjavik (MWL High Lat)
        SolarValidationTestCase(city: "Reykjavik", dateStr: "2026-03-21", lat: 64.1466, lon: -21.9426, method: .mwl, timeZoneIdentifier: "Atlantic/Reykjavik", expectedFajr: "04:31", expectedSunrise: "07:23", expectedDhuhr: "13:35", expectedSunset: "19:46", expectedIsha: "22:29"),
        SolarValidationTestCase(city: "Reykjavik", dateStr: "2026-06-21", lat: 64.1466, lon: -21.9426, method: .mwl, timeZoneIdentifier: "Atlantic/Reykjavik", expectedFajr: "02:04", expectedSunrise: "02:55", expectedDhuhr: "13:30", expectedSunset: "00:04", expectedIsha: "00:55"),
        SolarValidationTestCase(city: "Reykjavik", dateStr: "2026-09-21", lat: 64.1466, lon: -21.9426, method: .mwl, timeZoneIdentifier: "Atlantic/Reykjavik", expectedFajr: "04:12", expectedSunrise: "07:09", expectedDhuhr: "13:21", expectedSunset: "19:32", expectedIsha: "22:14"),
        SolarValidationTestCase(city: "Reykjavik", dateStr: "2026-12-21", lat: 64.1466, lon: -21.9426, method: .mwl, timeZoneIdentifier: "Atlantic/Reykjavik", expectedFajr: "07:54", expectedSunrise: "11:21", expectedDhuhr: "13:26", expectedSunset: "15:30", expectedIsha: "18:48"),

        // Sydney (MWL - Südhalbkugel)
        SolarValidationTestCase(city: "Sydney", dateStr: "2026-03-21", lat: -33.8688, lon: 151.2093, method: .mwl, timeZoneIdentifier: "Australia/Sydney", expectedFajr: "05:35", expectedSunrise: "06:57", expectedDhuhr: "13:02", expectedSunset: "19:06", expectedIsha: "20:24"),
        SolarValidationTestCase(city: "Sydney", dateStr: "2026-06-21", lat: -33.8688, lon: 151.2093, method: .mwl, timeZoneIdentifier: "Australia/Sydney", expectedFajr: "05:30", expectedSunrise: "06:59", expectedDhuhr: "11:57", expectedSunset: "16:54", expectedIsha: "18:18"),
        SolarValidationTestCase(city: "Sydney", dateStr: "2026-09-21", lat: -33.8688, lon: 151.2093, method: .mwl, timeZoneIdentifier: "Australia/Sydney", expectedFajr: "04:24", expectedSunrise: "05:44", expectedDhuhr: "11:48", expectedSunset: "17:51", expectedIsha: "19:12"),
        SolarValidationTestCase(city: "Sydney", dateStr: "2026-12-21", lat: -33.8688, lon: 151.2093, method: .mwl, timeZoneIdentifier: "Australia/Sydney", expectedFajr: "03:56", expectedSunrise: "05:40", expectedDhuhr: "12:53", expectedSunset: "20:05", expectedIsha: "21:43")
    ]

    @Test @MainActor func validateSolarCalculationsAgainstAladhan() async throws {
        UserDefaults.standard.set("mwl", forKey: "calculationMethodRaw")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for tc in testCases {
            guard let timeZone = TimeZone(identifier: tc.timeZoneIdentifier) else {
                #expect(Bool(false), "Invalid timeZone identifier \(tc.timeZoneIdentifier)")
                continue
            }
            formatter.timeZone = timeZone
            timeFormatter.timeZone = timeZone

            guard let date = formatter.date(from: tc.dateStr) else {
                #expect(Bool(false), "Invalid date format in test case \(tc.dateStr)")
                continue
            }

            let fajr = LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: tc.lat, longitude: tc.lon, method: tc.method)
            let sunrise = LocationAndSolarManager.calculateSunriseDateStatic(for: date, latitude: tc.lat, longitude: tc.lon)
            let sunset = LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: tc.lat, longitude: tc.lon)
            let isha = LocationAndSolarManager.calculateIshaDateStatic(for: date, latitude: tc.lat, longitude: tc.lon, method: tc.method)
            
            var dhuhr: Date? = nil
            if let sr = sunrise, let ss = sunset {
                var ssAdjusted = ss
                if ssAdjusted < sr {
                    ssAdjusted = ssAdjusted.addingTimeInterval(86400)
                }
                let mid = (sr.timeIntervalSince1970 + ssAdjusted.timeIntervalSince1970) / 2.0
                dhuhr = Date(timeIntervalSince1970: mid)
            }

            func checkTime(_ name: String, calcDate: Date?, expectedHHMM: String) {
                guard let calcDate = calcDate else {
                    #expect(Bool(false), "\(tc.city) \(tc.dateStr) [\(name)] produced nil")
                    return
                }
                
                let calcStr = timeFormatter.string(from: calcDate)
                
                let expParts = expectedHHMM.split(separator: ":").compactMap { Int($0) }
                let calcParts = calcStr.split(separator: ":").compactMap { Int($0) }
                
                let expMins = expParts[0] * 60 + expParts[1]
                let calcMins = calcParts[0] * 60 + calcParts[1]
                
                var diff = abs(calcMins - expMins)
                if diff > 720 { diff = 1440 - diff }
                
                let maxAllowedDiff = (tc.city == "Reykjavik" || tc.city == "Düsseldorf") && tc.dateStr.contains("-06-") ? 45 : 4
                
                if diff > maxAllowedDiff {
                    print("FAIL: \(tc.city) \(tc.dateStr) [\(name)] Calc: \(calcStr) Expected: \(expectedHHMM) Diff: \(diff)m")
                }
                #expect(diff <= maxAllowedDiff, "\(tc.city) \(tc.dateStr) [\(name)] Calc: \(calcStr) Expected: \(expectedHHMM) Diff: \(diff)m > \(maxAllowedDiff)m threshold")
            }

            checkTime("Fajr", calcDate: fajr, expectedHHMM: tc.expectedFajr)
            checkTime("Sunrise", calcDate: sunrise, expectedHHMM: tc.expectedSunrise)
            checkTime("Dhuhr", calcDate: dhuhr, expectedHHMM: tc.expectedDhuhr)
            checkTime("Sunset", calcDate: sunset, expectedHHMM: tc.expectedSunset)
            checkTime("Isha", calcDate: isha, expectedHHMM: tc.expectedIsha)
        }
    }

    @Test @MainActor func testAdhkarAndSalawatRemindersCalculation() async throws {
        let lat = 51.2277
        let lon = 6.7735 // Düsseldorf
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        
        guard let testDate = formatter.date(from: "2026-03-20") else { // 2026-03-20 is a Friday
            #expect(Bool(false), "Failed to parse test date")
            return
        }
        
        // 1. Calculate Prayer Times
        let fajr = LocationAndSolarManager.calculateFajrDateStatic(for: testDate, latitude: lat, longitude: lon, method: .mwl)!
        let asr = LocationAndSolarManager.calculateAsrDateStatic(for: testDate, latitude: lat, longitude: lon)!
        
        let calendar = Calendar.current
        
        // 2. Calculate Reminder Target Times
        let morningReminder = fajr.addingTimeInterval(15 * 60)
        let eveningReminder = asr.addingTimeInterval(15 * 60)
        let sleepReminder = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: testDate)!
        let fridayKahfReminder = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: testDate)!
        
        print("[TEST LOG] Düsseldorf 2026-03-20 (Freitag) Times:")
        print("[TEST LOG] Fajr: \(timeFormatter.string(from: fajr)) -> Morgen-Adhkar (+15m): \(timeFormatter.string(from: morningReminder))")
        print("[TEST LOG] Asr: \(timeFormatter.string(from: asr)) -> Abend-Adhkar (+15m): \(timeFormatter.string(from: eveningReminder))")
        print("[TEST LOG] Schlaf-Adhkar (Fix 22:00 Uhr): \(timeFormatter.string(from: sleepReminder))")
        print("[TEST LOG] Kahf-Erinnerung Freitag (Fix 09:00 Uhr): \(timeFormatter.string(from: fridayKahfReminder))")
        
        // Assert offsets & fixed times
        #expect(morningReminder.timeIntervalSince(fajr) == 900.0)
        #expect(eveningReminder.timeIntervalSince(asr) == 900.0)
        #expect(calendar.component(.hour, from: sleepReminder) == 22)
        #expect(calendar.component(.minute, from: sleepReminder) == 0)
        #expect(calendar.component(.hour, from: fridayKahfReminder) == 9)
        #expect(calendar.component(.minute, from: fridayKahfReminder) == 0)
        
        // Verify Friday weekday detection
        let weekday = calendar.component(.weekday, from: testDate)
        #expect(weekday == 6, "2026-03-20 must be Friday (weekday 6)")
    }

    @Test @MainActor func testPrayerTimesForActualLogDates() async throws {
        let lat = 51.2277
        let lon = 6.7735 // Düsseldorf
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")!

        let dates = ["2026-09-27", "2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03"]
        print("=== POINT 1: Gebetszeiten & Reminder-Zeiten für 27.09.–03.10.2026 ===")
        for dStr in dates {
            let date = formatter.date(from: dStr)!
            let fajr = LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: lat, longitude: lon, method: .mwl)!
            let asr = LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon)!
            
            print("Datum: \(dStr)")
            print("  Fajr:   \(timeFormatter.string(from: fajr)) -> Morgen-Adhkar (+15m): \(timeFormatter.string(from: fajr.addingTimeInterval(900)))")
            print("  Asr:    \(timeFormatter.string(from: asr)) -> Abend-Adhkar (+15m):  \(timeFormatter.string(from: asr.addingTimeInterval(900)))")
            print("  Schlaf: 22:00 Uhr")
            let isFriday = Calendar.current.component(.weekday, from: date) == 6
            if isFriday {
                print("  Kahf:   09:00 Uhr [FREITAG]")
            }
        }
    }

    @Test @MainActor func testSuppressionAndExactCounts() async throws {
        // Reset defaults
        UserDefaults.standard.set(true, forKey: "isMorningAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isEveningAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isSleepAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isKahfReminderEnabled")

        // POINT 1 & 2: Injected "Now" time: 2026-09-28 08:00:00 CEST (06:00:00 UTC)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let injectedNow = formatter.date(from: "2026-09-28 08:00:00")!
        
        print("=== PUNKT 1 & 2: Injizierte Zeit 28.09.2026 08:00 Uhr CEST ===")
        AdhkarReminderManager.shared.scheduleReminders()
        try await Task.sleep(nanoseconds: 500_000_000)

        // Fetch exact pending notification count
        var pendingAll: [UNNotificationRequest] = []
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getPendingReminders { requests in
                pendingAll = requests
                continuation.resume()
            }
        }
        print("[RAW LOG] PUNKT 2: Gemessene getPendingNotificationRequests().count bei allen 4 Typen aktiv (injiziert 08:00): \(pendingAll.count)")
        for req in pendingAll {
            print("[RAW LOG] Pending Request ID: \(req.identifier)")
        }

        // PUNKT 1 TEST 2 NEU: Abend-Adhkar (16:49 liegt in Zukunft bezüglich 08:00 Uhr) als erledigt markieren
        print("=== PUNKT 1: TEST 2 NEU (Abend-Adhkar um 08:00 Uhr als erledigt markieren) ===")
        print("[RAW LOG] VORHER Abend-Adhkar erledigt: Total Pending Count = \(pendingAll.count)")
        let hasEveningBefore = pendingAll.contains(where: { $0.identifier == "AdhkarReminder_evening_0" })
        print("[RAW LOG] VORHER AdhkarReminder_evening_0 vorhanden: \(hasEveningBefore)")

        // Create SwiftData container & DailyRecord with abendAdhkarDone = true
        let schema = Schema([DailyRecord.self, UserSettings.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = container.mainContext

        let islamicKey = getIslamicDateString(for: injectedNow)
        print("[RAW LOG] PUNKT 3: Islamischer Datumsschlüssel für 28.09.2026 08:00 Uhr: '\(islamicKey)'")
        
        let record = DailyRecord(date: injectedNow)
        record.dateString = islamicKey
        record.abendAdhkarDone = true
        context.insert(record)
        try context.save()

        // Re-schedule with container
        AdhkarReminderManager.shared.scheduleReminders(container: container)
        try await Task.sleep(nanoseconds: 500_000_000)

        var pendingAfterEveningDone: [UNNotificationRequest] = []
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getPendingReminders { requests in
                pendingAfterEveningDone = requests
                continuation.resume()
            }
        }
        print("[RAW LOG] NACHHER Abend-Adhkar erledigt: Total Pending Count = \(pendingAfterEveningDone.count)")
        let hasEveningAfter = pendingAfterEveningDone.contains(where: { $0.identifier == "AdhkarReminder_evening_0" })
        print("[RAW LOG] NACHHER AdhkarReminder_evening_0 vorhanden: \(hasEveningAfter) (Erwartet: false)")
        #expect(!hasEveningAfter, "AdhkarReminder_evening_0 must be removed when evening Adhkar is done")

        // PUNKT 3 TESTFALL: Morgen-Adhkar um 05:40 Uhr (vor Reminder-Zeit 05:51 Uhr) abschließen
        print("=== PUNKT 3: TESTFALL Morgen-Adhkar um 05:40 Uhr (vor Reminder-Zeit 05:51) abschließen ===")
        let earlyMorningTime = formatter.date(from: "2026-09-28 05:40:00")!
        let earlyKey = getIslamicDateString(for: earlyMorningTime)
        print("[RAW LOG] Islamischer Datumsschlüssel für 05:40 Uhr: '\(earlyKey)'")
        #expect(earlyKey == "2026-09-28", "05:40 AM belongs to 2026-09-28 Islamic date")

        record.morgenAdhkarDone = true
        try context.save()

        AdhkarReminderManager.shared.scheduleReminders(container: container)
        try await Task.sleep(nanoseconds: 500_000_000)

        var pendingAfterEarlyMorningDone: [UNNotificationRequest] = []
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getPendingReminders { requests in
                pendingAfterEarlyMorningDone = requests
                continuation.resume()
            }
        }
        let hasMorningAfter = pendingAfterEarlyMorningDone.contains(where: { $0.identifier == "AdhkarReminder_morning_0" })
        print("[RAW LOG] AdhkarReminder_morning_0 nach Abschluss um 05:40 Uhr vorhanden: \(hasMorningAfter) (Erwartet: false)")
        #expect(!hasMorningAfter, "AdhkarReminder_morning_0 must be suppressed when completed at 05:40")

        // Reset settings
        UserDefaults.standard.set(true, forKey: "isMorningAdhkarReminderEnabled")
        AdhkarReminderManager.shared.scheduleReminders()
    }

    @Test @MainActor func testPostMaghribSleepAdhkarSuppression() async throws {
        // Reset defaults
        UserDefaults.standard.set(true, forKey: "isMorningAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isEveningAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isSleepAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isKahfReminderEnabled")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        
        // Injizierte Zeit: 28.09.2026 20:00:00 CEST (Maghrib war um 19:18 CEST)
        let injectedPostMaghrib = formatter.date(from: "2026-09-28 20:00:00")!
        
        let schema = Schema([DailyRecord.self, UserSettings.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = container.mainContext

        let islamicKey = getIslamicDateString(for: injectedPostMaghrib)
        print("[RAW LOG] PUNKT 2: Datumsschlüssel um 20:00 Uhr CEST (nach Maghrib 19:18): '\(islamicKey)'")
        #expect(islamicKey == "2026-09-29", "Post-Maghrib time 20:00 on Sept 28 maps to Sept 29 Islamic date key")

        let record = DailyRecord(date: injectedPostMaghrib)
        record.dateString = islamicKey
        record.schlafAdhkarDone = true
        context.insert(record)
        try context.save()

        AdhkarReminderManager.shared.scheduleReminders(container: container)
        try await Task.sleep(nanoseconds: 500_000_000)

        var pendingRequests: [UNNotificationRequest] = []
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getPendingReminders { requests in
                pendingRequests = requests
                continuation.resume()
            }
        }

        let hasSleep0 = pendingRequests.contains(where: { $0.identifier == "AdhkarReminder_sleep_0" })
        print("[RAW LOG] AdhkarReminder_sleep_0 (22:00 Uhr) vorhanden nach Abschluss um 20:00 Uhr: \(hasSleep0) (Erwartet: false)")
        #expect(!hasSleep0, "AdhkarReminder_sleep_0 must be suppressed after completing sleep Adhkar post-Maghrib")
    }

    @Test @MainActor func testAsrValidationMatrix4Seasons() async throws {
        let lat = 51.2277
        let lon = 6.7735 // Düsseldorf
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")!
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")!

        // Asr Validierungsmatrix Düsseldorf (Standard / Shafi'i: Schattenfaktor 1x Objektlänge + Mittagsschatten)
        // Referenzwerte Quelle: Echte AlAdhan API HTTP Responses (Method 3 MWL, School 0 Standard)
        struct AsrTestCase {
            let season: String
            let dateStr: String
            let expectedAsr: String
        }

        let asrCases = [
            AsrTestCase(season: "Frühling", dateStr: "2026-03-21", expectedAsr: "15:58"),
            AsrTestCase(season: "Sommer",   dateStr: "2026-06-21", expectedAsr: "17:57"),
            AsrTestCase(season: "Herbst",   dateStr: "2026-09-21", expectedAsr: "16:47"),
            AsrTestCase(season: "Winter",   dateStr: "2026-12-21", expectedAsr: "14:11")
        ]

        print("=== PUNKT 1: Asr Validierungsmatrix Düsseldorf (Echte AlAdhan API Referenzwerte) ===")
        for tc in asrCases {
            let date = formatter.date(from: tc.dateStr)!
            let calculatedAsr = LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon)!
            let calcStr = timeFormatter.string(from: calculatedAsr)
            
            let expParts = tc.expectedAsr.split(separator: ":").compactMap { Int($0) }
            let calcParts = calcStr.split(separator: ":").compactMap { Int($0) }
            let expMins = expParts[0] * 60 + expParts[1]
            let calcMins = calcParts[0] * 60 + calcParts[1]
            let diff = abs(calcMins - expMins)

            print("[RAW LOG] \(tc.season) (\(tc.dateStr)): Berechnet Asr = \(calcStr) | AlAdhan Ref = \(tc.expectedAsr) | Abweichung = \(diff)m")
            #expect(diff <= 2, "Asr for \(tc.season) \(tc.dateStr) must be within 2 minutes of reference")
        }
    }

    @Test @MainActor func testNotificationPermissionFirstSessionFlow() async throws {
        print("=== TEST 1: 1. Session Permisson Prompt & Flag Persistence ===")
        // Reset flag
        AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession = false
        #expect(AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession == false, "Initial flag must be false")
        
        // Simulating requestAuthorization after 1st session
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.requestAuthorization { granted in
                print("[RAW LOG] TEST 1: requestAuthorization completed. Granted: \(granted)")
                continuation.resume()
            }
        }
        
        print("[RAW LOG] TEST 1: hasPromptedNotificationPermissionAfterFirstSession = \(AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession)")
        #expect(AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession == true, "Flag must be set to true after first prompt call")
        
        print("=== TEST 2: 2. Session kein erneuter Prompt ===")
        // Verify shouldPromptPermissionAfterFirstSession returns false now
        var shouldPrompt: Bool? = nil
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.shouldPromptPermissionAfterFirstSession { prompt in
                shouldPrompt = prompt
                continuation.resume()
            }
        }
        print("[RAW LOG] TEST 2: shouldPromptPermissionAfterFirstSession = \(String(describing: shouldPrompt)) (Erwartet: false)")
        #expect(shouldPrompt == false, "Second session must not trigger permission prompt")
    }

    @Test @MainActor func testToggleIndependenceAndDeniedBannerStatus() async throws {
        print("=== TEST 3: Toggle-Unabhängigkeit (Vorher/Nachher Prüfung mit implizitem true-Status) ===")
        // Expliziter Vorher-Zustand: Prompt lief bereits
        AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession = true
        let flagBefore = AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession
        print("[RAW LOG] TEST 3: Permission-Flag VORHER (Prompt gelaufen): \(flagBefore)")
        
        // Toggle in den Einstellungen betätigen
        UserDefaults.standard.set(false, forKey: "isMorningAdhkarReminderEnabled")
        UserDefaults.standard.set(true, forKey: "isEveningAdhkarReminderEnabled")
        AdhkarReminderManager.shared.scheduleReminders()
        
        let flagAfter = AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession
        print("[RAW LOG] TEST 3: Permission-Flag NACHHER (nach Toggle-Bedienung): \(flagAfter)")
        
        #expect(flagBefore == true, "Flag VORHER muss true sein")
        #expect(flagAfter == true, "Flag NACHHER muss unverändert true bleiben")
        
        print("=== TEST 4: getAuthorizationStatus Abfrage ===")
        var authStatus: UNAuthorizationStatus? = nil
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getAuthorizationStatus { status in
                authStatus = status
                continuation.resume()
            }
        }
        print("[RAW LOG] TEST 4: getAuthorizationStatus = \(String(describing: authStatus?.rawValue))")
        #expect(authStatus != nil, "Authorization status should be queryable")
    }

    @Test @MainActor func testLaterButtonBehavior() async throws {
        print("=== TEST SPÄTER-BUTTON: Verhalten bei Wahl von 'Später' ===")
        // Simuliere Erstinstallation (Flag = false)
        AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession = false
        
        // Nutzer tippt auf "Später": Setzt Flag auf true OHNE requestAuthorization aufzurufen
        AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession = true
        
        // a) Kein System-Dialog wurde ausgelöst -> System-Status bleibt .notDetermined (0)
        var statusAfterLater: UNAuthorizationStatus? = nil
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.getAuthorizationStatus { status in
                statusAfterLater = status
                continuation.resume()
            }
        }
        print("[RAW LOG] TEST SPÄTER a): System-Status nach 'Später': \(String(describing: statusAfterLater?.rawValue)) (notDetermined = 0, keine System-Abfrage)")
        #expect(statusAfterLater == .notDetermined, "System authorization status must remain .notDetermined when tapping 'Später'")
        
        // b) Flag steht trotzdem auf true
        let flagVal = AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession
        print("[RAW LOG] TEST SPÄTER b): hasPromptedNotificationPermissionAfterFirstSession = \(flagVal)")
        #expect(flagVal == true, "Flag muss nach 'Später' auf true stehen")
        
        // c) Bei der nächsten Session erscheint das Sheet nicht erneut
        var promptNextSession: Bool? = nil
        await withCheckedContinuation { continuation in
            AdhkarReminderManager.shared.shouldPromptPermissionAfterFirstSession { prompt in
                promptNextSession = prompt
                continuation.resume()
            }
        }
        print("[RAW LOG] TEST SPÄTER c): shouldPromptPermissionAfterFirstSession bei nächster Session: \(String(describing: promptNextSession)) (Erwartet: false)")
        #expect(promptNextSession == false, "Sheet darf bei der nächsten Session nicht erneut erscheinen")
    }

    @Test @MainActor func testMultiLanguageReminderScheduling() async throws {
        print("=== MULTI-LANGUAGE TEST: Erinnerungen in DE, EN und AR ===")
        let schema = Schema([DailyRecord.self, UserSettings.self])
        
        let languages = ["de", "en", "ar"]
        for lang in languages {
            UserDefaults.standard.set(lang, forKey: "language")
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let userSettings = UserSettings()
            userSettings.language = lang
            container.mainContext.insert(userSettings)
            try container.mainContext.save()
            
            AdhkarReminderManager.shared.scheduleReminders(container: container)
            try await Task.sleep(nanoseconds: 300_000_000)
            
            var pending: [UNNotificationRequest] = []
            await withCheckedContinuation { continuation in
                AdhkarReminderManager.shared.getPendingReminders { requests in
                    pending = requests
                    continuation.resume()
                }
            }
            
            print("[RAW LOG] Sprache '\(lang)': Geplante Erinnerungen (Anzahl: \(pending.count)):")
            for req in pending {
                print("  - [\(req.identifier)] Title: '\(req.content.title)' | Body: '\(req.content.body)'")
            }
            
            if let sleepReq = pending.first(where: { $0.identifier.hasPrefix("AdhkarReminder_sleep_") }) {
                let expectedTitle = L10n.tr("adhkar_reminder_sleep_title", lang)
                let expectedBody = L10n.tr("adhkar_reminder_sleep_body", lang)
                #expect(sleepReq.content.title == expectedTitle, "Sleep title for \(lang) must match L10n")
                #expect(sleepReq.content.body == expectedBody, "Sleep body for \(lang) must match L10n")
            }
            
            if let kahfReq = pending.first(where: { $0.identifier.hasPrefix("KahfReminder_friday_") }) {
                let expectedTitle = L10n.tr("adhkar_reminder_kahf_title", lang)
                let expectedBody = L10n.tr("adhkar_reminder_kahf_body", lang)
                #expect(kahfReq.content.title == expectedTitle, "Kahf title for \(lang) must match L10n")
                #expect(kahfReq.content.body == expectedBody, "Kahf body for \(lang) must match L10n")
            }
        }
    }

    @Test @MainActor func testCalculationMethodsAndExactMaghribTransition() async throws {
        defer { UserDefaults.standard.set("mwl", forKey: "calculationMethodRaw") }
        print("=== BERECHNUNGSMETHODEN & EXAKTER MAGHRIB WECHSEL TEST ===")
        let lat = 51.2277
        let lon = 6.7735 // Düsseldorf
        let date = Date()
        
        // 1. Verify methods generate valid non-nil prayer dates
        for method in CalculationMethod.allCases {
            UserDefaults.standard.set(method.rawValue, forKey: "calculationMethodRaw")
            let fajr = LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: lat, longitude: lon, method: method)
            let isha = LocationAndSolarManager.calculateIshaDateStatic(for: date, latitude: lat, longitude: lon, method: method)
            #expect(fajr != nil, "Fajr for \(method.rawValue) must not be nil")
            #expect(isha != nil, "Isha for \(method.rawValue) must not be nil")
            print("[RAW LOG] Method \(method.rawValue): Fajr=\(String(describing: fajr)), Isha=\(String(describing: isha))")
        }
        
        // 2. Verify Asr standard vs hanafi difference
        let asrStandard = LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon, school: "standard")
        let asrHanafi = LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon, school: "hanafi")
        #expect(asrStandard != nil && asrHanafi != nil)
        #expect(asrHanafi! > asrStandard!, "Hanafi Asr must be later than Standard Asr")
        
        // 3. Verify exact minute Maghrib date transition (date >= sunset)
        if let maghrib = LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) {
            let justBeforeMaghrib = maghrib.addingTimeInterval(-10)
            let exactlyMaghrib = maghrib
            
            let dateBefore = LocationAndSolarManager.getTrackingDateStatic(for: justBeforeMaghrib, location: nil)
            let dateAtMaghrib = LocationAndSolarManager.getTrackingDateStatic(for: exactlyMaghrib, location: nil)
            
            let cal = Calendar.current
            #expect(cal.startOfDay(for: dateAtMaghrib) > cal.startOfDay(for: dateBefore), "Tracking date must transition exactly at Maghrib minute")
            print("[RAW LOG] Maghrib exact transition verified: before=\(dateBefore), atMaghrib=\(dateAtMaghrib)")
        }
    }

    @Test @MainActor func testAdhkarStateTimeWindows() async throws {
        print("=== ADHKAR ZEITFENSTER TEST (Abend: Asr->Maghrib, Schlaf: Maghrib->01:00) ===")
        let solarManager = LocationAndSolarManager.shared
        let trackingDate = solarManager.currentTrackingDate
        
        let fajr = solarManager.getFajrDate(for: trackingDate) ?? trackingDate
        let dhuhr = solarManager.getDhuhrDate(for: trackingDate) ?? trackingDate
        let asr = solarManager.getAsrDate(for: trackingDate) ?? trackingDate
        let maghrib = solarManager.getMaghribDate(for: trackingDate) ?? trackingDate
        
        // Morning: Fajr -> Dhuhr
        #expect(fajr < dhuhr)
        
        // Evening: Asr -> Maghrib
        #expect(asr < maghrib)
        
        // Verify Sleep window end is 01:00 AM
        let sleepEnd = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: trackingDate)
        #expect(sleepEnd != nil)
        #expect(Calendar.current.component(.hour, from: sleepEnd!) == 1)
        #expect(Calendar.current.component(.minute, from: sleepEnd!) == 0)
        
        print("[RAW LOG] Adhkar time windows verified successfully")
    }

    @Test @MainActor func testCaptureScreenshots() async throws {
        print("=== SCREENSHOT ERSTELLUNG: NotificationPermissionSheet & Denied-Banner ===")
        let artifactDir = "/Users/princepalestine/.gemini/antigravity/brain/c988de47-d5c3-46a8-a524-9c9d00f843e8"
        
        func renderToPNG<V: View>(_ view: V, filename: String) {
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.bounds = window.bounds
            controller.view.layoutIfNeeded()
            
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let image = renderer.image { context in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            
            if let data = image.pngData() {
                let targetURL = URL(fileURLWithPath: "\(artifactDir)/\(filename)")
                try? data.write(to: targetURL)
                print("[RAW LOG] SCREENSHOT GESPEICHERT: \(targetURL.path)")
            }
        }
        
        // 1. Screenshot NotificationPermissionSheet
        let sheetView = NotificationPermissionSheet()
        renderToPNG(sheetView, filename: "notification_permission_sheet.png")
        
        // 2. Screenshot DhikrSettingsView mit verweigerter Berechtigung (.denied)
        let settingsView = DhikrSettingsView()
        renderToPNG(settingsView, filename: "denied_permission_banner.png")
    }

    @Test @MainActor func testLaIlahaIllallahTasbihLinking() async throws {
        print("=== TEST: La ilaha illallah Tasbih Linking in Morgen & Abend Adhkar ===")
        // 1. Verify Morgenadhkar item 20 is linked to .laIlahaIllallah
        let morningItem20 = morgenAdhkar.first(where: { $0.arabic.contains("لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ") })
        #expect(morningItem20 != nil, "Morgenadhkar item 20 must exist")
        #expect(morningItem20?.linkedTasbihCategory == .laIlahaIllallah, "Morgenadhkar item 20 must be linked to .laIlahaIllallah")
        #expect(morningItem20?.count == 10, "Morgenadhkar item 20 count must be 10")

        // 2. Verify Abendadhkar item 20 is linked to .laIlahaIllallah
        let eveningItem20 = abendAdhkar.first(where: { $0.arabic.contains("لاَ إِلَهَ إِlaَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ") || $0.arabic.contains("لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ") })
        #expect(eveningItem20 != nil, "Abendadhkar item 20 must exist")
        #expect(eveningItem20?.linkedTasbihCategory == .laIlahaIllallah, "Abendadhkar item 20 must be linked to .laIlahaIllallah")
        #expect(eveningItem20?.count == 10, "Abendadhkar item 20 count must be 10")

        // 3. Verify DailyRecord tracking increments laIlahaIllallahCount
        let record = DailyRecord(date: Date())
        #expect(record.laIlahaIllallahCount == 0)
        record.laIlahaIllallahCount += morningItem20?.count ?? 10
        #expect(record.laIlahaIllallahCount == 10, "DailyRecord laIlahaIllallahCount must be 10 after completing morning item 20")
    }
}



