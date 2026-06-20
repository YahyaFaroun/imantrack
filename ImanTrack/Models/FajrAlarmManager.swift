import Foundation
import UserNotifications

enum FajrAlarmMode: String, Codable, CaseIterable {
    case atFajr = "atFajr"
    case beforeFajr = "beforeFajr"
    case fixedTime = "fixedTime"
}

class FajrAlarmManager {
    static let shared = FajrAlarmManager()
    
    private init() {}
    
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
        guard isEnabled else {
            cancelFajrAlarm(alarmNumber: alarmNumber)
            return
        }
        
        guard let alarmDate = getNextAlarmDate(alarmNumber: alarmNumber) else {
            print("Could not calculate next alarm date for alarm \(alarmNumber).")
            return
        }
        
        scheduleNotification(at: alarmDate, alarmNumber: alarmNumber)
    }
    
    func getNextAlarmDate(alarmNumber: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return nil }
        
        let suffix = alarmNumber == 1 ? "" : "2"
        let modeRaw = UserDefaults.standard.string(forKey: "fajrAlarm\(suffix)Mode") ?? "atFajr"
        let mode = FajrAlarmMode(rawValue: modeRaw) ?? .atFajr
        
        switch mode {
        case .atFajr:
            guard let fajrDate = LocationAndSolarManager.shared.getFajrDate(for: tomorrow) else {
                return nil
            }
            if fajrDate <= Date() {
                guard let afterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) else { return nil }
                return LocationAndSolarManager.shared.getFajrDate(for: afterTomorrow)
            }
            return fajrDate
            
        case .beforeFajr:
            guard let fajrDate = LocationAndSolarManager.shared.getFajrDate(for: tomorrow) else {
                return nil
            }
            let defaultOffset = 30
            let offsetMinutes = UserDefaults.standard.object(forKey: "fajrAlarm\(suffix)OffsetMinutes") != nil ? UserDefaults.standard.integer(forKey: "fajrAlarm\(suffix)OffsetMinutes") : defaultOffset
            guard let offsetDate = calendar.date(byAdding: .minute, value: -offsetMinutes, to: fajrDate) else { return nil }
            
            if offsetDate <= Date() {
                guard let afterTomorrow = calendar.date(byAdding: .day, value: 2, to: today),
                      let fajrAfterTomorrow = LocationAndSolarManager.shared.getFajrDate(for: afterTomorrow) else { return nil }
                return calendar.date(byAdding: .minute, value: -offsetMinutes, to: fajrAfterTomorrow)
            }
            return offsetDate
            
        case .fixedTime:
            var rawSeconds = alarmNumber == 1 ? 18000.0 : 21600.0 // 5:00 AM (18000) or 6:00 AM (21600)
            if UserDefaults.standard.object(forKey: "fajrAlarm\(suffix)FixedTime") != nil {
                rawSeconds = UserDefaults.standard.double(forKey: "fajrAlarm\(suffix)FixedTime")
            }
            let hour = Int(rawSeconds) / 3600
            let minute = (Int(rawSeconds) % 3600) / 60
            
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = hour
            components.minute = minute
            components.second = 0
            
            guard let fixedDate = calendar.date(from: components) else { return nil }
            if fixedDate <= Date() {
                guard let afterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) else { return nil }
                var componentsAfter = calendar.dateComponents([.year, .month, .day], from: afterTomorrow)
                componentsAfter.hour = hour
                componentsAfter.minute = minute
                componentsAfter.second = 0
                return calendar.date(from: componentsAfter)
            }
            return fixedDate
        }
    }
    
    private func scheduleNotification(at date: Date, alarmNumber: Int) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        // Sprache aus UserDefaults laden
        let lang = UserDefaults.standard.string(forKey: "language") ?? "de"
        
        content.title = L10n.tr("fajr_alarm_title", lang)
        content.body = L10n.tr("fajr_alarm_body", lang)
        
        let soundName = UserDefaults.standard.string(forKey: "fajrAlarmSound") ?? "default"
        if soundName == "default" {
            content.sound = .default
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "FajrAlarm\(alarmNumber)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling Fajr Alarm \(alarmNumber): \(error)")
            } else {
                print("Successfully scheduled Fajr Alarm \(alarmNumber) for \(date)")
            }
        }
    }
    
    func cancelFajrAlarm() {
        cancelFajrAlarm(alarmNumber: 1)
        cancelFajrAlarm(alarmNumber: 2)
    }
    
    func cancelFajrAlarm(alarmNumber: Int) {
        let identifier = "FajrAlarm\(alarmNumber)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled pending Fajr Alarm \(alarmNumber) notification.")
    }
}
