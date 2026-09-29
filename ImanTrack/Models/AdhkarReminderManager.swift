import Foundation
import UserNotifications
import SwiftData
import UIKit

@MainActor
class AdhkarReminderManager: NSObject {
    static let shared = AdhkarReminderManager()
    
    var hasPromptedNotificationPermissionAfterFirstSession: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasPromptedNotificationPermissionAfterFirstSession")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasPromptedNotificationPermissionAfterFirstSession")
        }
    }
    
    private override init() {
        super.init()
    }
    
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func shouldPromptPermissionAfterFirstSession(completion: @escaping (Bool) -> Void) {
        guard !hasPromptedNotificationPermissionAfterFirstSession else {
            completion(false)
            return
        }
        getAuthorizationStatus { status in
            completion(status == .notDetermined)
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        hasPromptedNotificationPermissionAfterFirstSession = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[LOG] Error requesting notification authorization: \(error)")
            }
            completion(granted)
        }
    }
    
    func scheduleReminders(container: ModelContainer? = nil) {
        let isMorningEnabled = UserDefaults.standard.object(forKey: "isMorningAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isMorningAdhkarReminderEnabled") : true
        let isEveningEnabled = UserDefaults.standard.object(forKey: "isEveningAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isEveningAdhkarReminderEnabled") : true
        let isSleepEnabled = UserDefaults.standard.object(forKey: "isSleepAdhkarReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isSleepAdhkarReminderEnabled") : true
        let isKahfEnabled = UserDefaults.standard.object(forKey: "isKahfReminderEnabled") != nil ? UserDefaults.standard.bool(forKey: "isKahfReminderEnabled") : true
        
        cancelReminders()
        
        guard isMorningEnabled || isEveningEnabled || isSleepEnabled || isKahfEnabled else { return }
        
        var todayMorningDone = false
        var todayEveningDone = false
        var todaySleepDone = false
        var todayKahfDone = false
        
        if let container = container {
            let context = container.mainContext
            let today = LocationAndSolarManager.shared.currentTrackingDate
            let key = getIslamicDateString(for: today)
            let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.dateString == key })
            if let record = try? context.fetch(descriptor).first {
                todayMorningDone = record.morgenAdhkarDone
                todayEveningDone = record.abendAdhkarDone
                todaySleepDone = record.schlafAdhkarDone
                todayKahfDone = record.surahAlKahfDone
            }
        }
        
        let now = Date()
        let calendar = Calendar.current
        let lang = UserDefaults.standard.string(forKey: "language") ?? "de"
        
        // Schedule for next 7 days (7 days * 4 notifications = ~28 total, well below 64 limit)
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let isToday = dayOffset == 0
            
            // 1. Morning Adhkar (+15 mins after Fajr)
            if isMorningEnabled && (!isToday || !todayMorningDone) {
                if let fajrDate = LocationAndSolarManager.shared.getFajrDate(for: targetDate) {
                    let triggerDate = fajrDate.addingTimeInterval(15 * 60)
                    if triggerDate > now {
                        scheduleNotification(
                            identifier: "AdhkarReminder_morning_\(dayOffset)",
                            title: L10n.tr("adhkar_reminder_morning_title", lang),
                            body: L10n.tr("adhkar_reminder_morning_body", lang),
                            date: triggerDate
                        )
                    }
                }
            }
            
            // 2. Evening Adhkar (+15 mins after Asr)
            if isEveningEnabled && (!isToday || !todayEveningDone) {
                if let asrDate = LocationAndSolarManager.shared.getAsrDate(for: targetDate) {
                    let triggerDate = asrDate.addingTimeInterval(15 * 60)
                    if triggerDate > now {
                        scheduleNotification(
                            identifier: "AdhkarReminder_evening_\(dayOffset)",
                            title: L10n.tr("adhkar_reminder_evening_title", lang),
                            body: L10n.tr("adhkar_reminder_evening_body", lang),
                            date: triggerDate
                        )
                    }
                }
            }
            
            // 3. Sleep Adhkar (Fixed at 22:00 Uhr / 10:00 PM)
            if isSleepEnabled && (!isToday || !todaySleepDone) {
                if let triggerDate = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: targetDate) {
                    if triggerDate > now {
                        scheduleNotification(
                            identifier: "AdhkarReminder_sleep_\(dayOffset)",
                            title: L10n.tr("adhkar_reminder_sleep_title", lang),
                            body: L10n.tr("adhkar_reminder_sleep_body", lang),
                            date: triggerDate
                        )
                    }
                }
            }
            
            // 4. Surah Al-Kahf Reminder (Fridays at 09:00 AM)
            if isKahfEnabled && (!isToday || !todayKahfDone) {
                let weekday = calendar.component(.weekday, from: targetDate)
                if weekday == 6 { // 6 = Friday
                    if let triggerDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate) {
                        if triggerDate > now {
                            scheduleNotification(
                                identifier: "KahfReminder_friday_\(dayOffset)",
                                title: L10n.tr("adhkar_reminder_kahf_title", lang),
                                body: L10n.tr("adhkar_reminder_kahf_body", lang),
                                date: triggerDate
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        content.sound = .default
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("[LOG] Error scheduling \(identifier): \(error)")
            } else {
                print("[LOG] Successfully scheduled \(identifier) for \(date)")
            }
        }
    }
    
    func cancelReminders() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request -> String? in
                let id = request.identifier
                if id.hasPrefix("AdhkarReminder_") || id.hasPrefix("SalawatReminder_") || id.hasPrefix("KahfReminder_") {
                    return id
                }
                return nil
            }
            if !identifiersToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("[LOG] Cancelled pending Adhkar/Kahf reminders: \(identifiersToRemove.count)")
            }
        }
    }
    
    func getPendingReminders(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let reminderRequests = requests.filter { req in
                req.identifier.hasPrefix("AdhkarReminder_") || req.identifier.hasPrefix("SalawatReminder_") || req.identifier.hasPrefix("KahfReminder_")
            }
            completion(reminderRequests)
        }
    }
}
