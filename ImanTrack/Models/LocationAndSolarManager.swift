import Foundation
import CoreLocation
import Combine
import SwiftUI
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
    
    // MARK: - Maghrib Countdown & 5-Minuten-Warnung
    @Published var maghribCountdownSeconds: Int? = nil // 60 ... 1
    @Published var showFiveMinuteWarning: Bool = false
    @Published var showDayResetToast: Bool = false
    @Published var isTestSimulationActive: Bool = false
    @Published var isSimulatedDayActive: Bool = false
    private var simulatedMaghribTargetDate: Date? = nil
    private var hasShownFiveMinuteWarningToday: Bool = false
    
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
        AdhkarReminderManager.shared.scheduleReminders()
        PrayerNotificationManager.shared.schedulePrayerNotifications()
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
        checkTimer?.invalidate()
        // Sekündliche Prüfung für präzisen 60-Sekunden-Countdown und 5-Minuten-Warnung
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.checkMaghribCountdownAndTransitions()
            }
        }
    }
    
    func checkMaghribCountdownAndTransitions() {
        let now = Date()
        
        let maghrib: Date
        if isTestSimulationActive, let simDate = simulatedMaghribTargetDate {
            maghrib = simDate
        } else {
            self.updateTrackingDate()
            guard let realMaghrib = getMaghribDate(for: now) else {
                if maghribCountdownSeconds != nil { maghribCountdownSeconds = nil }
                if showFiveMinuteWarning { showFiveMinuteWarning = false }
                return
            }
            maghrib = realMaghrib
        }
        
        let diff = maghrib.timeIntervalSince(now)
        
        // 1. 5-Minuten-Warnung Pop-up (zwischen 300s und 60s vor Maghrib)
        if diff > 60.0 && diff <= 300.0 {
            if !hasShownFiveMinuteWarningToday && !isTestSimulationActive {
                hasShownFiveMinuteWarningToday = true
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.showFiveMinuteWarning = true
                }
                #if os(iOS)
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.warning)
                #endif
                
                // Automatisches sanftes Ausblenden nach 7 Sekunden ("was dann vergeht als Warnung")
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { [weak self] in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self?.showFiveMinuteWarning = false
                    }
                }
            }
        } else if diff > 300.0 {
            hasShownFiveMinuteWarningToday = false
            if showFiveMinuteWarning && !isTestSimulationActive {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFiveMinuteWarning = false
                }
            }
        }
        
        // 2. 1-Minute-Countdown (zwischen 60.0s und 0.0s vor Maghrib)
        if diff > 0.0 && diff <= 60.0 {
            if showFiveMinuteWarning {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFiveMinuteWarning = false
                }
            }
            let sec = Int(ceil(diff))
            if maghribCountdownSeconds != sec {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    self.maghribCountdownSeconds = sec
                }
            }
        } else if diff <= 0.0 && diff > -3.5 {
            if maghribCountdownSeconds != nil || isTestSimulationActive {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.maghribCountdownSeconds = nil
                }
                
                let wasSimulation = isTestSimulationActive
                if wasSimulation {
                    self.isTestSimulationActive = false
                    self.simulatedMaghribTargetDate = nil
                    self.isSimulatedDayActive = true
                    // Im Testmodus: Datum sofort auf nächsten Tag setzen, damit der Zähler-Reset optisch & technisch live sichtbar ist
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: self.currentTrackingDate) ?? Date()
                    self.currentTrackingDate = Calendar.current.startOfDay(for: nextDay)
                } else {
                    self.updateTrackingDate()
                }
                
                hasShownFiveMinuteWarningToday = false
                NotificationCenter.default.post(name: Notification.Name("MaghribDayResetTriggered"), object: nil)
                
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.showDayResetToast = true
                }
                #if os(iOS)
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self?.showDayResetToast = false
                    }
                }
            }
        } else {
            if maghribCountdownSeconds != nil && !isTestSimulationActive {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.maghribCountdownSeconds = nil
                }
            }
        }
    }
    
    func dismissFiveMinuteWarning() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.showFiveMinuteWarning = false
        }
    }
    
    // MARK: - Test & Simulation
    func triggerTestFiveMinuteWarning() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.showFiveMinuteWarning = true
        }
        #if os(iOS)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
        #endif
        
        // Push-Benachrichtigung für 2 Sekunden später planen (damit man auch bei gesperrtem Handy testen kann)
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Neuer islamischer Tag in 5 Minuten"
        content.body = "Mit Maghrib beginnt der neue islamische Tag. Alle täglichen Tracks (Dhikr, Adhkar, Koran) werden zurückgestellt."
        content.sound = .default
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier: "TestMaghrib5Min_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        center.add(request)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { [weak self] in
            withAnimation(.easeInOut(duration: 0.4)) {
                self?.showFiveMinuteWarning = false
            }
        }
    }
    
    func startTestCountdown(seconds: Int = 60) {
        self.isTestSimulationActive = true
        self.simulatedMaghribTargetDate = Date().addingTimeInterval(Double(seconds))
        self.maghribCountdownSeconds = seconds
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        #endif
    }
    
    func stopTestSimulation() {
        self.isTestSimulationActive = false
        self.isSimulatedDayActive = false
        self.simulatedMaghribTargetDate = nil
        self.maghribCountdownSeconds = nil
        self.showFiveMinuteWarning = false
        self.showDayResetToast = false
        self.updateTrackingDate()
    }
    
    func updateTrackingDate() {
        let now = Date()
        let newDate = getTrackingDate(for: now)
        let startOfNewDate = Calendar.current.startOfDay(for: newDate)
        if currentTrackingDate != startOfNewDate {
            self.currentTrackingDate = startOfNewDate
            AdhkarReminderManager.shared.scheduleReminders()
            PrayerNotificationManager.shared.schedulePrayerNotifications()
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
    
    // Berechnet die Fajr-Zeit für ein Datum
    nonisolated func getFajrDate(for date: Date, method: CalculationMethod? = nil) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        let calcMethod = method ?? LocationAndSolarManager.getSelectedCalculationMethod()
        guard let base = LocationAndSolarManager.calculateFajrDateStatic(for: date, latitude: lat, longitude: lon, method: calcMethod) else { return nil }
        let offset = LocationAndSolarManager.getPrayerOffset(for: "fajr")
        return base.addingTimeInterval(Double(offset) * 60.0)
    }
    
    // Berechnet die Sonnenaufgangszeit (Sunrise) für ein Datum
    nonisolated func getSunriseDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        return LocationAndSolarManager.calculateSunriseDateStatic(for: date, latitude: lat, longitude: lon)
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
            let base = Date(timeIntervalSince1970: mid)
            let offset = LocationAndSolarManager.getPrayerOffset(for: "dhuhr")
            return base.addingTimeInterval(Double(offset) * 60.0)
        }
        return nil
    }
    
    // Berechnet die Asr-Zeit für ein Datum (Nachmittagsgebet)
    nonisolated func getAsrDate(for date: Date, school: String? = nil) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        let asrSchool = school ?? LocationAndSolarManager.getSelectedAsrSchool()
        guard let base = LocationAndSolarManager.calculateAsrDateStatic(for: date, latitude: lat, longitude: lon, school: asrSchool) else { return nil }
        let offset = LocationAndSolarManager.getPrayerOffset(for: "asr")
        return base.addingTimeInterval(Double(offset) * 60.0)
    }

    // Berechnet die Maghrib-Zeit (Sonnenuntergang) für ein Datum
    nonisolated func getMaghribDate(for date: Date) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        guard let base = LocationAndSolarManager.calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) else { return nil }
        let offset = LocationAndSolarManager.getPrayerOffset(for: "maghrib")
        return base.addingTimeInterval(Double(offset) * 60.0)
    }
    
    // Berechnet die Isha-Zeit für ein Datum
    nonisolated func getIshaDate(for date: Date, method: CalculationMethod? = nil) -> Date? {
        let cachedLat = UserDefaults.standard.double(forKey: "last_latitude")
        let cachedLon = UserDefaults.standard.double(forKey: "last_longitude")
        let lat = (cachedLat != 0.0) ? cachedLat : 51.2217
        let lon = (cachedLon != 0.0) ? cachedLon : 6.7762
        let calcMethod = method ?? LocationAndSolarManager.getSelectedCalculationMethod()
        guard let base = LocationAndSolarManager.calculateIshaDateStatic(for: date, latitude: lat, longitude: lon, method: calcMethod) else { return nil }
        let offset = LocationAndSolarManager.getPrayerOffset(for: "isha")
        return base.addingTimeInterval(Double(offset) * 60.0)
    }

    nonisolated static func getPrayerOffset(for prayer: String) -> Int {
        UserDefaults.standard.integer(forKey: "prayer_offset_\(prayer.lowercased())")
    }
    
    nonisolated static func setPrayerOffset(for prayer: String, offset: Int) {
        UserDefaults.standard.set(offset, forKey: "prayer_offset_\(prayer.lowercased())")
    }

    nonisolated static func getSelectedCalculationMethod() -> CalculationMethod {
        let raw = UserDefaults.standard.string(forKey: "calculationMethodRaw") ?? "mwl"
        return CalculationMethod(rawValue: raw) ?? .mwl
    }

    nonisolated static func getSelectedAsrSchool() -> String {
        return UserDefaults.standard.string(forKey: "asrSchoolRaw") ?? "standard"
    }
    
    // Statische Hilfsmethoden für zeitzonen- und sonnenuntergangsgetreue Berechnung ohne Instanzreferenz
    nonisolated static func getTrackingDateStatic(for date: Date, location: CLLocation?) -> Date {
        let calendar = Calendar.current
        let loc = location ?? CLLocation(latitude: 51.2217, longitude: 6.7762) // Standard Düsseldorf Fallback
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let offset = getPrayerOffset(for: "maghrib")
        
        guard let sunsetDate = calculateSunsetDateStatic(for: date, latitude: lat, longitude: lon) else {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 18
            components.minute = 30
            components.second = 0
            let fallbackSunset = calendar.date(from: components) ?? date
            let effectiveSunset = fallbackSunset.addingTimeInterval(Double(offset) * 60.0)
            if date >= effectiveSunset {
                return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
            } else {
                return calendar.startOfDay(for: date)
            }
        }
        
        let effectiveSunset = sunsetDate.addingTimeInterval(Double(offset) * 60.0)
        if date >= effectiveSunset {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        } else {
            return calendar.startOfDay(for: date)
        }
    }
}

public enum CalculationMethod: String, CaseIterable, Codable, Sendable {
    case ummAlQura = "ummAlQura"
    case mwl = "mwl"
    case egyptian = "egyptian"
    case karachi = "karachi"
    case uae = "uae"
    case kuwait = "kuwait"
    case qatar = "qatar"
    case diyanet = "diyanet"
    case singapore = "singapore"
    case malaysia = "malaysia"
    case indonesia = "indonesia"
    case morocco = "morocco"
    case tunisia = "tunisia"
    case algeria = "algeria"
    case isna = "isna"
    case moonsighting = "moonsighting"
    case france18 = "france18"
    case france15 = "france15"
    case uoif = "uoif"
    case tehran = "tehran"
    
    public nonisolated var fajrAngle: Double {
        switch self {
        case .ummAlQura: return 18.5
        case .mwl: return 18.0
        case .egyptian: return 19.5
        case .karachi: return 18.0
        case .uae: return 18.2
        case .kuwait: return 18.0
        case .qatar: return 18.0
        case .diyanet: return 18.0
        case .singapore: return 20.0
        case .malaysia: return 20.0
        case .indonesia: return 20.0
        case .morocco: return 19.0
        case .tunisia: return 18.0
        case .algeria: return 18.0
        case .isna: return 15.0
        case .moonsighting: return 18.0
        case .france18: return 18.0
        case .france15: return 15.0
        case .uoif: return 12.0
        case .tehran: return 17.7
        }
    }
    
    public nonisolated var ishaAngle: Double? {
        switch self {
        case .ummAlQura, .qatar: return nil
        case .mwl: return 17.0
        case .egyptian: return 17.5
        case .karachi: return 18.0
        case .uae: return 18.0
        case .kuwait: return 17.5
        case .diyanet: return 17.0
        case .singapore: return 18.0
        case .malaysia: return 18.0
        case .indonesia: return 18.0
        case .morocco: return 17.0
        case .tunisia: return 18.0
        case .algeria: return 17.0
        case .isna: return 15.0
        case .moonsighting: return 18.0
        case .france18: return 18.0
        case .france15: return 15.0
        case .uoif: return 12.0
        case .tehran: return 14.0
        }
    }
    
    public nonisolated var ishaIntervalMinutes: Double? {
        switch self {
        case .ummAlQura, .qatar: return 90.0
        default: return nil
        }
    }
    
    private nonisolated func formatAngle(_ angle: Double) -> String {
        if angle.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(angle))°"
        } else {
            return String(format: "%.1f°", angle)
        }
    }
    
    public nonisolated func subtitle(language: String) -> String {
        let fajrPart = "Fajr \(formatAngle(fajrAngle))"
        let ishaPart: String
        if let interval = ishaIntervalMinutes {
            let mins = Int(interval)
            let template = L10n.tr("prayer_interval_after_maghrib", language)
            ishaPart = String(format: template, mins)
        } else if let angle = ishaAngle {
            ishaPart = "Isha \(formatAngle(angle))"
        } else {
            ishaPart = ""
        }
        return "\(fajrPart) · \(ishaPart)"
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
    
    nonisolated static func calculateIshaDateStatic(for date: Date, latitude: Double, longitude: Double, method: CalculationMethod = getSelectedCalculationMethod()) -> Date? {
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
    
    nonisolated static func calculateFajrDateStatic(for date: Date, latitude: Double, longitude: Double, method: CalculationMethod = getSelectedCalculationMethod()) -> Date? {
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

    nonisolated static func calculateAsrDateStatic(for date: Date, latitude: Double, longitude: Double, school: String = getSelectedAsrSchool()) -> Date? {
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
        let factor: Double = (school == "hanafi") ? 2.0 : 1.0
        let cotA = factor + tan(angleDistance)
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

