import Foundation
import CoreLocation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class LocationAndSolarManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @MainActor static let shared = LocationAndSolarManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var lastLocation: CLLocation? {
        didSet {
            if let loc = lastLocation {
                UserDefaults.standard.set(loc.coordinate.latitude, forKey: "last_latitude")
                UserDefaults.standard.set(loc.coordinate.longitude, forKey: "last_longitude")
            }
        }
    }
    
    // Das aktuelle spirituelle Datum (immer 00:00 Uhr des Ziel-Tages)
    @Published var currentTrackingDate: Date
    @Published var hasLocationPermission: Bool
    @Published var isNightTime: Bool = false
    
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        // Cache aus UserDefaults laden
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let loc = (cachedLat != 0.0 && cachedLon != 0.0) ? CLLocation(latitude: cachedLat, longitude: cachedLon) : nil
        self.lastLocation = loc
        
        let initialTrackingDate = LocationAndSolarManager.getTrackingDateStatic(for: Date(), location: loc)
        self.currentTrackingDate = Calendar.current.startOfDay(for: initialTrackingDate)
        
        let isAuth: Bool
        #if os(macOS)
        isAuth = (locationManager.authorizationStatus == .authorizedAlways)
        #else
        let status = locationManager.authorizationStatus
        isAuth = (status == .authorizedWhenInUse || status == .authorizedAlways)
        #endif
        self.hasLocationPermission = isAuth
        self.isNightTime = false
        
        super.init()
        
        let initialNight = calculateIsNightTime(now: Date())
        self.isNightTime = initialNight
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"
        let now = Date()
        let nowStr = timeFmt.string(from: now)
        let fajrStr = getFajrDate(for: now).map { timeFmt.string(from: $0) } ?? "nil"
        let maghribStr = getMaghribDate(for: now).map { timeFmt.string(from: $0) } ?? "nil"
        print("[DAY_LABEL] Init: isNightTime = \(initialNight) (Zeit: \(nowStr), Fajr: \(fajrStr), Maghrib: \(maghribStr), Ergebnis: \(initialNight ? "Nacht" : "Tag"))")
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        #if os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateTrackingDate()
                }
            }
            .store(in: &cancellables)
        #endif
        
        // Timer zur regelmäßigen Überprüfung
        startTimer()
    }
    
    func requestAuthorization() {
        // Fordert Berechtigung an, falls nötig, und startet Updates
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            let isAuthorized: Bool
            #if os(macOS)
            isAuthorized = (status == .authorizedAlways)
            #else
            isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
            #endif
            
            if isAuthorized {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.lastLocation = location
        // Stop updates to save battery once we have a location
        locationManager.stopUpdatingLocation()
        self.updateTrackingDate()
        // Fajr Alarm & Adhkar Reminders aktualisieren, wenn neuer Standort vorliegt
        FajrAlarmManager.shared.scheduleFajrAlarm()
        AdhkarReminderManager.shared.scheduleReminders()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let isAuthorized: Bool
        #if os(macOS)
        isAuthorized = (status == .authorizedAlways)
        #else
        isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        #endif
        
        self.hasLocationPermission = isAuthorized
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
        self.updateTrackingDate()
    }
    
    private func startTimer() {
        // Alle 5 Sekunden überprüfen, um sofort reagieren zu können
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            if let self = self {
                Task { @MainActor in
                    self.updateTrackingDate()
                }
            }
        }
    }
    
    func updateTrackingDate() {
        let now = Date()
        let newDate = getTrackingDate(for: now)
        let startOfNewDate = Calendar.current.startOfDay(for: newDate)
        if currentTrackingDate != startOfNewDate {
            self.currentTrackingDate = startOfNewDate
            // Fajr Alarm & Adhkar Reminders automatisch bei spirituellem Datumswechsel neu planen
            FajrAlarmManager.shared.scheduleFajrAlarm()
            AdhkarReminderManager.shared.scheduleReminders()
        }
        
        let newNight = calculateIsNightTime(now: now)
        if isNightTime != newNight {
            let timeFmt = DateFormatter()
            timeFmt.dateFormat = "HH:mm:ss"
            let nowStr = timeFmt.string(from: now)
            let fajrStr = getFajrDate(for: now).map { timeFmt.string(from: $0) } ?? "nil"
            let maghribStr = getMaghribDate(for: now).map { timeFmt.string(from: $0) } ?? "nil"
            print("[DAY_LABEL] Statuswechsel: isNightTime: \(self.isNightTime) -> \(newNight) (Zeit: \(nowStr), Fajr: \(fajrStr), Maghrib: \(maghribStr), Ergebnis: \(newNight ? "Nacht" : "Tag"))")
            self.isNightTime = newNight
        }
    }
    
    func calculateIsNightTime(now: Date = Date()) -> Bool {
        guard hasLocationPermission else { return false }
        guard let fajrToday = getFajrDate(for: now),
              let maghribToday = getMaghribDate(for: now) else {
            return false
        }
        return now >= maghribToday || now < fajrToday
    }
    
    // MARK: - Wochentags- und Datumsanzeige (Islamischer Tagesbeginn)
    
    /// Formatiert den Wochentag für die Anzeige unter Berücksichtigung von Maghrib und Fajr.
    /// Von Maghrib bis Fajr: "Nacht zum <Wochentag>" (z. B. "Nacht zum Freitag", "ليلة الجمعة", "Night before Friday")
    /// Ab Fajr bis Maghrib: "<Wochentag>"
    /// Ohne Standortfreigabe: normaler Wochentag
    func displayWeekdayTitle(for weekdayName: String, language: String) -> String {
        guard isNightTime else { return weekdayName }
        
        let lang = language.lowercased()
        let format = L10n.tr("night_before_weekday", lang)
        
        var formattedWeekday = weekdayName
        if lang == "fr" || lang == "es" {
            // Französisch & Spanisch: Wochentag klein (z. B. "vendredi", "viernes")
            formattedWeekday = formattedWeekday.lowercased()
        } else if lang == "ru" {
            // Russisch: Wochentag im Akkusativ ("Ночь на пятницу", "Ночь на среду", "Ночь на субботу")
            let lower = formattedWeekday.lowercased()
            if lower.hasSuffix("а") {
                formattedWeekday = String(lower.dropLast()) + "у"
            } else {
                formattedWeekday = lower
            }
        }
        
        return String(format: format, formattedWeekday)
    }
    
    /// Formatiert das Gregorianische Datum für die Anzeige mit Wochentag ("Nacht zum <Wochentag>, <Tag>. <Monat>")
    func formattedDisplayDate(for date: Date, language: String) -> String {
        let lang = language.lowercased()
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: lang)
        weekdayFormatter.dateFormat = "EEEE"
        let rawWeekday = weekdayFormatter.string(from: date)
        let displayWeekday = displayWeekdayTitle(for: rawWeekday, language: lang)
        
        let restFormatter = DateFormatter()
        restFormatter.locale = Locale(identifier: lang)
        if lang == "en" {
            restFormatter.dateFormat = "MMMM d"
            return "\(displayWeekday), \(restFormatter.string(from: date))"
        } else if lang == "ar" {
            restFormatter.dateFormat = "d MMMM"
            return "\(displayWeekday)، \(restFormatter.string(from: date))"
        } else if lang == "de" {
            restFormatter.dateFormat = "d. MMMM"
            return "\(displayWeekday), \(restFormatter.string(from: date))"
        } else {
            restFormatter.setLocalizedDateFormatFromTemplate("d MMMM")
            return "\(displayWeekday), \(restFormatter.string(from: date))"
        }
    }
    
    var isFridayKahfVisible: Bool {
        let cal = Calendar.current
        let trackerDate = currentTrackingDate
        let weekday = cal.component(.weekday, from: trackerDate)
        guard weekday == 6 else { return false }
        
        let now = Date()
        let fajrDate = getFajrDate(for: trackerDate) ?? trackerDate
        return now >= fajrDate
    }
    
    // Bestimmt das Datum für das Tracking basierend auf der übergebenen Zeit
    // Bestimmt das Datum für das Tracking basierend auf der übergebenen Zeit
    nonisolated func getTrackingDate(for date: Date) -> Date {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let loc = (cachedLat != 0.0 && cachedLon != 0.0) ? CLLocation(latitude: cachedLat, longitude: cachedLon) : nil
        return LocationAndSolarManager.getTrackingDateStatic(for: date, location: loc)
    }
    
    // Berechnet die genaue Sonnenuntergangszeit für ein Datum und Koordinaten (NOAA-Equation)
    func calculateSunsetDate(for date: Date, latitude: Double, longitude: Double) -> Date? {
        return LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: latitude, longitude: longitude)
    }
    
    // Berechnet die Fajr-Zeit für ein Datum (Dawn-Equation mit 18 Grad Dämmerung)
    nonisolated func getFajrDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        return LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: lat, longitude: lon)
    }
    
    // Berechnet die Dhuhr-Zeit (Solar Noon) für ein Datum
    nonisolated func getDhuhrDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        if let sunrise = LocationAndSolarManager.calculateSunriseDateStatic(for: date, latitude: lat, longitude: lon),
           let sunset = LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) {
            let mid = (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2.0
            return Date(timeIntervalSince1970: mid)
        }
        return nil
    }
    
    // Berechnet die Asr-Zeit für ein Datum (Nachmittagsgebet)
    nonisolated func getAsrDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        return LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon)
    }

    // Berechnet die Maghrib-Zeit (Sonnenuntergang) für ein Datum
    nonisolated func getMaghribDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        return LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon)
    }
    
    // Berechnet die Isha-Zeit für ein Datum (Maghrib + 90 Minuten als sicherer Standard)
    nonisolated func getIshaDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        return LocationAndSolarManager.calculateIshaDateStatic(for: date, latitude: lat, longitude: lon)
    }
    
    // Statische Hilfsmethoden für zeitzonen- und sonnenuntergangsgetreue Berechnung ohne Instanzreferenz
    nonisolated static func getTrackingDateStatic(for date: Date, location: CLLocation?) -> Date {
        let calendar = Calendar.current
        let loc = location ?? CLLocation(latitude: 51.2217, longitude: 6.7762) // Standard Düsseldorf Fallback
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        
        guard let sunsetDate = calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) else {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 18
            components.minute = 30
            components.second = 0
            let fallbackSunset = calendar.date(from: components) ?? date
            if date >= fallbackSunset {
                return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
            } else {
                return calendar.startOfDay(for: date)
            }
        }
        
        if date >= sunsetDate {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        } else {
            return calendar.startOfDay(for: date)
        }
    }
}

public enum CalculationMethod: String, CaseIterable, Codable, Sendable {
    case mwl = "mwl"               // MWL: Fajr 18.0°, Isha 17.0°
    case isna = "isna"             // ISNA: Fajr 15.0°, Isha 15.0°
    case ummAlQura = "ummAlQura"   // Umm al-Qura: Fajr 18.5°, Isha = Maghrib + 90 min
    case karachi = "karachi"       // Karachi: Fajr 18.0°, Isha 18.0°
    case egyptian = "egyptian"     // Egyptian: Fajr 19.5°, Isha 17.5°
    
    public nonisolated var fajrAngle: Double {
        switch self {
        case .mwl: return 18.0
        case .isna: return 15.0
        case .ummAlQura: return 18.5
        case .karachi: return 18.0
        case .egyptian: return 19.5
        }
    }
    
    public nonisolated var ishaAngle: Double? {
        switch self {
        case .mwl: return 17.0
        case .isna: return 15.0
        case .ummAlQura: return nil
        case .karachi: return 18.0
        case .egyptian: return 17.5
        }
    }
    
    public nonisolated var ishaIntervalMinutes: Double? {
        switch self {
        case .ummAlQura: return 90.0
        default: return nil
        }
    }
}

extension LocationAndSolarManager {
    nonisolated static func calculateSunsetDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let startOfTodayUTC = gmtCalendar.date(from: components) else { return nil }
        
        let doy = Double(gmtCalendar.ordinality(of: .day, in: .year, for: startOfTodayUTC) ?? 1)
        let lngHour = longitude / 15.0
        let t = doy + ((18.0 - lngHour) / 24.0)
        
        let M = (0.9856 * t) - 3.289
        var L = M + (1.916 * sin(M * .pi / 180.0)) + (0.020 * sin(2.0 * M * .pi / 180.0)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }
        
        var RA = atan(0.91764 * tan(L * .pi / 180.0)) * (180.0 / .pi)
        RA = RA.truncatingRemainder(dividingBy: 360.0)
        if RA < 0 { RA += 360.0 }
        
        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA = RA / 15.0
        
        let sinDec = 0.39782 * sin(L * .pi / 180.0)
        let cosDec = cos(asin(sinDec))
        let zenith = 90.833 * .pi / 180.0
        let cosH = (cos(zenith) - (sinDec * sin(latitude * .pi / 180.0))) / (cosDec * cos(latitude * .pi / 180.0))
        
        if cosH > 1.0 || cosH < -1.0 { return nil }
        
        let H = acos(cosH) * 180.0 / .pi
        let Hhour = H / 15.0
        var T = Hhour + RA - (0.06571 * t) - 6.622
        T = T.truncatingRemainder(dividingBy: 24.0)
        if T < 0 { T += 24.0 }
        
        var UT = T - lngHour
        if UT < 0 { UT += 24.0 }
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        
        var sunsetDate = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
        if T > 18.0 && UT < 6.0 {
            sunsetDate = sunsetDate.addingTimeInterval(86400.0)
        }
        return sunsetDate
    }
    
    nonisolated static func calculateSunriseDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let startOfTodayUTC = gmtCalendar.date(from: components) else { return nil }
        
        let doy = Double(gmtCalendar.ordinality(of: .day, in: .year, for: startOfTodayUTC) ?? 1)
        let lngHour = longitude / 15.0
        let t = doy + ((6.0 - lngHour) / 24.0)
        
        let M = (0.9856 * t) - 3.289
        var L = M + (1.916 * sin(M * .pi / 180.0)) + (0.020 * sin(2.0 * M * .pi / 180.0)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }
        
        var RA = atan(0.91764 * tan(L * .pi / 180.0)) * (180.0 / .pi)
        RA = RA.truncatingRemainder(dividingBy: 360.0)
        if RA < 0 { RA += 360.0 }
        
        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA = RA / 15.0
        
        let sinDec = 0.39782 * sin(L * .pi / 180.0)
        let cosDec = cos(asin(sinDec))
        let zenith = 90.833 * .pi / 180.0
        let cosH = (cos(zenith) - (sinDec * sin(latitude * .pi / 180.0))) / (cosDec * cos(latitude * .pi / 180.0))
        
        if cosH > 1.0 || cosH < -1.0 { return nil }
        
        let H = acos(cosH) * 180.0 / .pi
        let Hhour = H / 15.0
        let T = RA - Hhour - (0.06571 * t) - 6.622
        var UT = T - lngHour
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        if UT < 0 { UT += 24.0 }
        
        return startOfTodayUTC.addingTimeInterval(UT * 3600.0)
    }
    
    nonisolated static func calculateIshaDateStatic(for date: Date, latitude: Double, longitude: Double, method: CalculationMethod = .mwl) -> Date? {
        guard let maghrib = calculateSunsetDateStatic(for: date, latitude: latitude, longitude: longitude) else { return nil }
        
        if let minutes = method.ishaIntervalMinutes {
            return maghrib.addingTimeInterval(minutes * 60.0)
        }
        
        guard let angle = method.ishaAngle else { return maghrib.addingTimeInterval(90.0 * 60.0) }
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let startOfTodayUTC = gmtCalendar.date(from: components) else { return nil }
        
        let doy = Double(gmtCalendar.ordinality(of: .day, in: .year, for: startOfTodayUTC) ?? 1)
        let lngHour = longitude / 15.0
        let t = doy + ((18.0 - lngHour) / 24.0)
        
        let M = (0.9856 * t) - 3.289
        var L = M + (1.916 * sin(M * .pi / 180.0)) + (0.020 * sin(2.0 * M * .pi / 180.0)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }
        
        var RA = atan(0.91764 * tan(L * .pi / 180.0)) * (180.0 / .pi)
        RA = RA.truncatingRemainder(dividingBy: 360.0)
        if RA < 0 { RA += 360.0 }
        
        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA = RA / 15.0
        
        let sinDec = 0.39782 * sin(L * .pi / 180.0)
        let cosDec = cos(asin(sinDec))
        let zenith = (90.0 + angle) * .pi / 180.0
        let cosH = (cos(zenith) - (sinDec * sin(latitude * .pi / 180.0))) / (cosDec * cos(latitude * .pi / 180.0))
        
        if cosH >= -1.0 && cosH <= 1.0 {
            let H = acos(cosH) * 180.0 / .pi
            let Hhour = H / 15.0
            let T = Hhour + RA - (0.06571 * t) - 6.622
            var UT = T - lngHour
            UT = UT.truncatingRemainder(dividingBy: 24.0)
            if UT < 0 { UT += 24.0 }
            
            let tempIsha = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
            
            // High-latitude check (30% night limit)
            if abs(latitude) > 50.0,
               let yesterday = gmtCalendar.date(byAdding: .day, value: -1, to: startOfTodayUTC),
               let yesterdaySunset = calculateSunsetDateStatic(for: yesterday, latitude: latitude, longitude: longitude),
               let todaySunrise = calculateSunriseDateStatic(for: date, latitude: latitude, longitude: longitude) {
                let nightDuration = todaySunrise.timeIntervalSince(yesterdaySunset)
                let maxIsha = maghrib.addingTimeInterval(nightDuration * 0.3)
                if tempIsha > maxIsha {
                    return maxIsha
                }
            }
            return tempIsha
        }
        
        return maghrib.addingTimeInterval(90.0 * 60.0)
    }
    
    nonisolated static func calculateFajrDateStatic(for date: Date, latitude: Double, longitude: Double, method: CalculationMethod = .mwl) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let startOfTodayUTC = gmtCalendar.date(from: components) else { return nil }
        
        guard let yesterday = gmtCalendar.date(byAdding: .day, value: -1, to: startOfTodayUTC),
              let yesterdaySunset = calculateSunsetDateStatic(for: yesterday, latitude: latitude, longitude: longitude),
              let todaySunrise = calculateSunriseDateStatic(for: date, latitude: latitude, longitude: longitude) else {
            return nil
        }
        
        let nightDuration = todaySunrise.timeIntervalSince(yesterdaySunset)
        let twilightLimit = todaySunrise.addingTimeInterval(-nightDuration * 0.3)
        
        let doy = Double(gmtCalendar.ordinality(of: .day, in: .year, for: startOfTodayUTC) ?? 1)
        let lngHour = longitude / 15.0
        let t = doy + ((6.0 - lngHour) / 24.0)
        
        let M = (0.9856 * t) - 3.289
        var L = M + (1.916 * sin(M * .pi / 180.0)) + (0.020 * sin(2.0 * M * .pi / 180.0)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }
        
        var RA = atan(0.91764 * tan(L * .pi / 180.0)) * (180.0 / .pi)
        RA = RA.truncatingRemainder(dividingBy: 360.0)
        if RA < 0 { RA += 360.0 }
        
        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA = RA / 15.0
        
        let sinDec = 0.39782 * sin(L * .pi / 180.0)
        let cosDec = cos(asin(sinDec))
        
        let angle = method.fajrAngle
        let zenith = (90.0 + angle) * .pi / 180.0
        let cosH = (cos(zenith) - (sinDec * sin(latitude * .pi / 180.0))) / (cosDec * cos(latitude * .pi / 180.0))
        
        var calculatedFajr: Date? = nil
        
        if cosH >= -1.0 && cosH <= 1.0 {
            let H = acos(cosH) * 180.0 / .pi
            let Hhour = H / 15.0
            let T = RA - Hhour - (0.06571 * t) - 6.622
            var UT = T - lngHour
            UT = UT.truncatingRemainder(dividingBy: 24.0)
            if UT < 0 { UT += 24.0 }
            
            let tempFajr = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
            if tempFajr >= twilightLimit {
                calculatedFajr = tempFajr
            }
        }
        
        if let fajr = calculatedFajr {
            return fajr
        } else {
            return todaySunrise.addingTimeInterval(-nightDuration * 0.3)
        }
    }

    nonisolated static func calculateAsrDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        guard let sunrise = calculateSunriseDateStatic(for: date, latitude: latitude, longitude: longitude),
              let sunset = calculateSunsetDateStatic(for: date, latitude: latitude, longitude: longitude) else {
            return nil
        }
        let dhuhrTime = (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2.0
        let dhuhrDate = Date(timeIntervalSince1970: dhuhrTime)
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let startOfTodayUTC = gmtCalendar.date(from: components) else { return nil }
        
        let doy = Double(gmtCalendar.ordinality(of: .day, in: .year, for: startOfTodayUTC) ?? 1)
        let lngHour = longitude / 15.0
        let t = doy + ((12.0 - lngHour) / 24.0)
        
        let M = (0.9856 * t) - 3.289
        var L = M + (1.916 * sin(M * .pi / 180.0)) + (0.020 * sin(2.0 * M * .pi / 180.0)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }
        
        let sinDec = 0.39782 * sin(L * .pi / 180.0)
        let cosDec = cos(asin(sinDec))
        let dec = asin(sinDec)
        let latRad = latitude * .pi / 180.0
        
        let angleDistance = abs(latRad - dec)
        let cotA = 1.0 + tan(angleDistance)
        let sinA = sin(atan(1.0 / cotA))
        
        let cosH = (sinA - (sinDec * sin(latRad))) / (cosDec * cos(latRad))
        
        if cosH >= -1.0 && cosH <= 1.0 {
            let H = acos(cosH) * 180.0 / .pi
            let Hhour = H / 15.0
            return dhuhrDate.addingTimeInterval(Hhour * 3600.0)
        }
        
        return dhuhrDate.addingTimeInterval(3.5 * 3600.0)
    }
}

