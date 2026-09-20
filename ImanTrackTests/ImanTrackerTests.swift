//
//  ImanTrackerTests.swift
//  ImanTrackerTests
//

import Testing
import Foundation
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

    @Test func validateSolarCalculationsAgainstAladhan() async throws {
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
}
