import Foundation
import UserNotifications

enum FajrAlarmMode: String, Codable, CaseIterable {
    case atFajr = "atFajr"
    case beforeFajr = "beforeFajr"
    case fixedTime = "fixedTime"
}

class FajrAlarmManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = FajrAlarmManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Erlaube Banner, Sound und Benachrichtigungsliste, auch wenn die App im Vordergrund geöffnet ist
        completionHandler([.banner, .sound, .list])
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
            completion(granted)
        }
    }
    
    func scheduleFajrAlarm() {
        scheduleFajrAlarm(alarmNumber: 1)
        scheduleFajrAlarm(alarmNumber: 2)
    }
    
    func scheduleFajrAlarm(alarmNumber: Int) {
        let suffix = alarmNumber == 1 ? "" : "2"
        let isEnabled = UserDefaults.standard.bool(forKey: "isFajrAlarm\(suffix)Enabled")
        
        cancelFajrAlarm(alarmNumber: alarmNumber)
        
        guard isEnabled else { return }
        
        var scheduledCount = 0
        var dayOffset = 0
        
        while scheduledCount < 10 && dayOffset < 30 {
            if let alarmDate = getAlarmDate(alarmNumber: alarmNumber, dayOffset: dayOffset) {
                if alarmDate > Date() {
                    scheduleNotification(at: alarmDate, alarmNumber: alarmNumber, index: scheduledCount)
                    scheduledCount += 1
                }
            }
            dayOffset += 1
        }
    }
    
    func getNextAlarmDate(alarmNumber: Int) -> Date? {
        var dayOffset = 0
        while dayOffset < 30 {
            if let alarmDate = getAlarmDate(alarmNumber: alarmNumber, dayOffset: dayOffset) {
                if alarmDate > Date() {
                    return alarmDate
                }
            }
            dayOffset += 1
        }
        return nil
    }
    
    func getAlarmDate(alarmNumber: Int, dayOffset: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
        
        let suffix = alarmNumber == 1 ? "" : "2"
        let modeRaw = UserDefaults.standard.string(forKey: "fajrAlarm\(suffix)Mode") ?? "atFajr"
        let mode = FajrAlarmMode(rawValue: modeRaw) ?? .atFajr
        
        switch mode {
        case .atFajr:
            guard let fajrDate = LocationAndSolarManager.shared.getFajrDate(for: targetDate) else {
                return nil
            }
            return fajrDate
            
        case .beforeFajr:
            guard let fajrDate = LocationAndSolarManager.shared.getFajrDate(for: targetDate) else {
                return nil
            }
            let defaultOffset = 30
            let offsetMinutes = UserDefaults.standard.object(forKey: "fajrAlarm\(suffix)OffsetMinutes") != nil ? UserDefaults.standard.integer(forKey: "fajrAlarm\(suffix)OffsetMinutes") : defaultOffset
            return calendar.date(byAdding: .minute, value: -offsetMinutes, to: fajrDate)
            
        case .fixedTime:
            var rawSeconds = alarmNumber == 1 ? 18000.0 : 21600.0
            if UserDefaults.standard.object(forKey: "fajrAlarm\(suffix)FixedTime") != nil {
                rawSeconds = UserDefaults.standard.double(forKey: "fajrAlarm\(suffix)FixedTime")
            }
            let hour = Int(rawSeconds) / 3600
            let minute = (Int(rawSeconds) % 3600) / 60
            
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = hour
            components.minute = minute
            components.second = 0
            
            return calendar.date(from: components)
        }
    }
    
    private func scheduleNotification(at date: Date, alarmNumber: Int, index: Int) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        let lang = UserDefaults.standard.string(forKey: "language") ?? "de"
        
        content.title = L10n.tr("fajr_alarm_title", lang)
        content.body = L10n.tr("fajr_alarm_body", lang)
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        var soundName = UserDefaults.standard.string(forKey: "fajrAlarmSound") ?? "default"
        
        if soundName.hasSuffix(".m4a") {
            soundName = soundName.replacingOccurrences(of: ".m4a", with: ".caf")
        } else if soundName.hasSuffix(".wav") {
            soundName = soundName.replacingOccurrences(of: ".wav", with: ".caf")
        }
        
        if soundName == "default" {
            content.sound = .default
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "FajrAlarm\(alarmNumber)_\(index)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling Fajr Alarm \(alarmNumber)_\(index): \(error)")
            } else {
                print("Successfully scheduled Fajr Alarm \(alarmNumber)_\(index) for \(date)")
            }
        }
    }
    
    func cancelFajrAlarm() {
        cancelFajrAlarm(alarmNumber: 1)
        cancelFajrAlarm(alarmNumber: 2)
    }
    
    func cancelFajrAlarm(alarmNumber: Int) {
        let center = UNUserNotificationCenter.current()
        let identifiers = (0..<10).map { "FajrAlarm\(alarmNumber)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled pending Fajr Alarm \(alarmNumber) notifications.")
    }
}
