import Foundation
import CoreLocation
import Combine

class LocationAndSolarManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationAndSolarManager()
    
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
    
    private var checkTimer: Timer?
    
    override init() {
        // Cache aus UserDefaults laden
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let loc = (cachedLat != 0.0 && cachedLon != 0.0) ? CLLocation(latitude: cachedLat, longitude: cachedLon) : nil
        self.lastLocation = loc
        
        let initialTrackingDate = LocationAndSolarManager.getTrackingDateStatic(for: Date(), location: loc)
        self.currentTrackingDate = Calendar.current.startOfDay(for: initialTrackingDate)
        
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        // Timer zur regelmäßigen Überprüfung
        startTimer()
    }
    
    func requestAuthorization() {
        // Fordert Berechtigung an, falls nötig, und startet Updates
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.lastLocation = location
        // Stop updates to save battery once we have a location
        locationManager.stopUpdatingLocation()
        updateTrackingDate()
        // Fajr Alarm aktualisieren, wenn neuer Standort vorliegt
        FajrAlarmManager.shared.scheduleFajrAlarm()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func startTimer() {
        // Alle 5 Sekunden überprüfen, um sofort reagieren zu können
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateTrackingDate()
        }
    }
    
    func updateTrackingDate() {
        let newDate = getTrackingDate(for: Date())
        let startOfNewDate = Calendar.current.startOfDay(for: newDate)
        if currentTrackingDate != startOfNewDate {
            DispatchQueue.main.async {
                self.currentTrackingDate = startOfNewDate
                // Fajr Alarm automatisch bei spirituellem Datumswechsel neu planen
                FajrAlarmManager.shared.scheduleFajrAlarm()
            }
        }
    }
    
    // Bestimmt das Datum für das Tracking basierend auf der übergebenen Zeit
    func getTrackingDate(for date: Date) -> Date {
        return LocationAndSolarManager.getTrackingDateStatic(for: date, location: lastLocation)
    }
    
    // Berechnet die genaue Sonnenuntergangszeit für ein Datum und Koordinaten (NOAA-Equation)
    func calculateSunsetDate(for date: Date, latitude: Double, longitude: Double) -> Date? {
        return LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: latitude, longitude: longitude)
    }
    
    // Berechnet die Fajr-Zeit für ein Datum (Dawn-Equation mit 18 Grad Dämmerung)
    func getFajrDate(for date: Date) -> Date? {
        guard let loc = lastLocation else {
            // Fallback ohne Standort: 05:00 Uhr morgens lokaler Zeit
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 5
            components.minute = 0
            components.second = 0
            return calendar.date(from: components)
        }
        return LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
    }
    
    // Statische Hilfsmethoden für zeitzonen- und sonnenuntergangsgetreue Berechnung ohne Instanzreferenz
    static func getTrackingDateStatic(for date: Date, location: CLLocation?) -> Date {
        let calendar = Calendar.current
        
        guard let location = location else {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 19
            components.minute = 30
            components.second = 0
            let fallbackSunset = calendar.date(from: components) ?? date
            if date >= fallbackSunset {
                return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
            } else {
                return calendar.startOfDay(for: date)
            }
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        guard let sunsetDate = calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) else {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 18
            components.minute = 0
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
    
    static func calculateSunsetDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let doy = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        
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
        
        if cosH > 1.0 || cosH < -1.0 {
            return nil
        }
        
        // Für Sunset verwenden wir H = acos(cosH) * 180 / pi
        let H = acos(cosH) * 180.0 / .pi
        let Hhour = H / 15.0
        
        let T = Hhour + RA - (0.06571 * t) - 6.622
        var UT = T - lngHour
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        if UT < 0 { UT += 24.0 }
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let startOfTodayUTC = calendar.date(from: components) else { return nil }
        let sunsetInUTC = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
        
        return sunsetInUTC
    }
    
    static func calculateSunriseDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let doy = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        
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
        
        func cosCos() -> Double { return cosDec * cos(latitude * .pi / 180.0) }
        let cosHReal = (cos(zenith) - (sinDec * sin(latitude * .pi / 180.0))) / cosCos()
        
        if cosHReal > 1.0 || cosHReal < -1.0 {
            return nil
        }
        
        let H = acos(cosHReal) * 180.0 / .pi
        let Hhour = H / 15.0
        
        let T = RA - Hhour - (0.06571 * t) - 6.622
        var UT = T - lngHour
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        if UT < 0 { UT += 24.0 }
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let startOfTodayUTC = calendar.date(from: components) else { return nil }
        let sunriseInUTC = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
        
        return sunriseInUTC
    }
    
    static func calculateFajrDateStatic(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        
        // 1. Berechne Sunrise für heute und Sunset für gestern
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
              let yesterdaySunset = calculateSunsetDateStatic(for: yesterday, latitude: latitude, longitude: longitude),
              let todaySunrise = calculateSunriseDateStatic(for: date, latitude: latitude, longitude: longitude) else {
            // Absoluter Fallback falls Sonnenberechnung komplett fehlschlägt
            return nil
        }
        
        let nightDuration = todaySunrise.timeIntervalSince(yesterdaySunset)
        
        // 2. Berechne Twilight-Angle-Limit (nach adhan-swift, 30% der Nacht bei 18 Grad)
        let twilightLimit = todaySunrise.addingTimeInterval(-nightDuration * 0.3)
        
        // 3. Berechne standardmäßiges Fajr bei 18 Grad Dämmerung
        let doy = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
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
        
        // Versuche 18-Grad-Berechnung
        let zenith18 = 108.0 * .pi / 180.0
        let cosH18 = (cos(zenith18) - (sinDec * sin(latitude * .pi / 180.0))) / (cosDec * cos(latitude * .pi / 180.0))
        
        var calculatedFajr: Date? = nil
        
        if cosH18 >= -1.0 && cosH18 <= 1.0 {
            let H = acos(cosH18) * 180.0 / .pi
            let Hhour = H / 15.0
            let T = RA - Hhour - (0.06571 * t) - 6.622
            var UT = T - lngHour
            UT = UT.truncatingRemainder(dividingBy: 24.0)
            if UT < 0 { UT += 24.0 }
            
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 0
            components.minute = 0
            components.second = 0
            components.timeZone = TimeZone(secondsFromGMT: 0)
            if let startOfTodayUTC = calendar.date(from: components) {
                let tempFajr = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
                // Wende die HighLatitudeRule.twilightAngle Begrenzung an:
                if tempFajr >= twilightLimit {
                    calculatedFajr = tempFajr
                }
            }
        }
        
        // Falls die 18-Grad-Dämmerung nicht erreicht wird (Sommermonate) oder vor dem twilightLimit liegt,
        // weichen wir für Diyanet/DITIB im Sommer direkt auf 90 Minuten vor Sonnenaufgang aus.
        if let fajr = calculatedFajr {
            return fajr
        } else {
            return todaySunrise.addingTimeInterval(-90.0 * 60.0)
        }
    }
}
