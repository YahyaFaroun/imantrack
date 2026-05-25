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
    @Published var currentTrackingDate: Date = Date()
    
    private var checkTimer: Timer?
    
    override init() {
        super.init()
        
        // Cache aus UserDefaults laden
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        if cachedLat != 0.0 && cachedLon != 0.0 {
            self.lastLocation = CLLocation(latitude: cachedLat, longitude: cachedLon)
        }
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        // Tracking-Datum initialisieren
        updateTrackingDate()
        
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
        let calendar = Calendar.current
        if !calendar.isDate(currentTrackingDate, inSameDayAs: newDate) {
            DispatchQueue.main.async {
                self.currentTrackingDate = newDate
            }
        }
    }
    
    // Bestimmt das Datum für das Tracking basierend auf der übergebenen Zeit
    func getTrackingDate(for date: Date) -> Date {
        let calendar = Calendar.current
        
        // Koordinaten (Fallback: Mekka, falls kein GPS vorhanden)
        let lat = lastLocation?.coordinate.latitude ?? 21.4225
        let lon = lastLocation?.coordinate.longitude ?? 39.8262
        
        guard let sunsetDate = calculateSunsetDate(for: date, latitude: lat, longitude: lon) else {
            // Fallback auf 18:00 Uhr
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
            // Nach Sonnenuntergang -> nächster Kalendertag
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        } else {
            // Vor Sonnenuntergang -> heutiger Kalendertag
            return calendar.startOfDay(for: date)
        }
    }
    
    // Berechnet die genaue Sonnenuntergangszeit für ein Datum und Koordinaten (NOAA-Equation)
    func calculateSunsetDate(for date: Date, latitude: Double, longitude: Double) -> Date? {
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
            return nil // Polartag / Polarnacht
        }
        
        let H = 360.0 - (acos(cosH) * 180.0 / .pi)
        let Hhour = H / 15.0
        
        let T = Hhour + RA - (0.06571 * t) - 6.622
        var UT = T - lngHour
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        if UT < 0 { UT += 24.0 }
        
        // In ein lokales Date umrechnen
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let startOfTodayUTC = calendar.date(from: components) else { return nil }
        let sunsetInUTC = startOfTodayUTC.addingTimeInterval(UT * 3600.0)
        
        return sunsetInUTC
    }
}
