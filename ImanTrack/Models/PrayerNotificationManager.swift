import Foundation
import UserNotifications
import SwiftData
import AVFoundation
import Combine
import UIKit

@MainActor
final class PrayerNotificationManager: NSObject, ObservableObject {
    static let shared = PrayerNotificationManager()
    
    enum PrayerType: String, CaseIterable, Identifiable {
        case fajr
        case dhuhr
        case asr
        case maghrib
        case isha
        
        var id: String { rawValue }
        
        func localizedName(lang: String) -> String {
            switch self {
            case .fajr: return L10n.tr("prayer_fajr", lang)
            case .dhuhr: return L10n.tr("prayer_dhuhr", lang)
            case .asr: return L10n.tr("prayer_asr", lang)
            case .maghrib: return L10n.tr("prayer_maghrib", lang)
            case .isha: return L10n.tr("prayer_isha", lang)
            }
        }
        
        func shortName(lang: String) -> String {
            switch self {
            case .fajr: return "Fajr"
            case .dhuhr: return "Dhuhr"
            case .asr: return "Asr"
            case .maghrib: return "Maghrib"
            case .isha: return "Isha"
            }
        }
    }
    
    @Published var isPlayingPreview: Bool = false
    @Published var previewingSound: String? = nil
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Permission
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[PrayerNotificationManager] Error requesting authorization: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Audio Preview
    func togglePlayPreview(soundName: String) {
        if isPlayingPreview && previewingSound == soundName {
            stopPreview()
            return
        }
        
        stopPreview()
        
        // Strip extension if passed
        let baseName = soundName.replacingOccurrences(of: ".caf", with: "")
        guard let url = Bundle.main.url(forResource: baseName, withExtension: "caf")
                ?? Bundle.main.url(forResource: soundName, withExtension: nil) else {
            print("[PrayerNotificationManager] Preview sound not found: \(soundName)")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlayingPreview = true
            previewingSound = soundName
        } catch {
            print("[PrayerNotificationManager] Failed to play preview: \(error)")
            stopPreview()
        }
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingPreview = false
        previewingSound = nil
    }
    
    // MARK: - Scheduling
    func schedulePrayerNotifications(container: ModelContainer? = nil) {
        getAuthorizationStatus { [weak self] status in
            guard let self = self else { return }
            if status == .authorized || status == .provisional {
                self.performSchedulePrayerNotifications(container: container)
            } else {
                print("[PrayerNotificationManager] Notification permission not authorized: \(status.rawValue)")
            }
        }
    }
    
    private func performSchedulePrayerNotifications(container: ModelContainer? = nil) {
        let isAdhanEnabled = UserDefaults.standard.bool(forKey: "prayerAdhanEnabled")
        let is10MinEnabled = UserDefaults.standard.bool(forKey: "prayerReminder10MinEnabled")
        
        cancelPrayerNotifications()
        
        guard isAdhanEnabled || is10MinEnabled else {
            print("[PrayerNotificationManager] Both Adhan and 10-Min reminders are disabled.")
            return
        }
        
        let soundName = UserDefaults.standard.string(forKey: "prayerAdhanSound") ?? "azan.caf"
        let methodRaw = UserDefaults.standard.string(forKey: "calculationMethodRaw") ?? "mwl"
        let asrSchoolRaw = UserDefaults.standard.string(forKey: "asrSchoolRaw") ?? "standard"
        let calcMethod = CalculationMethod(rawValue: methodRaw) ?? .mwl
        
        let lang: String
        if let container = container {
            let context = container.mainContext
            let descriptor = FetchDescriptor<UserSettings>()
            lang = (try? context.fetch(descriptor).first)?.language ?? UserDefaults.standard.string(forKey: "language") ?? "de"
        } else {
            lang = UserDefaults.standard.string(forKey: "language") ?? "de"
        }
        
        let now = Date()
        let calendar = Calendar.current
        let solarManager = LocationAndSolarManager.shared
        
        // Schedule next 4 days (4 days * 5 prayers * 2 = max 40 notifications, safe under 64 iOS limit)
        for dayOffset in 0..<4 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            for prayer in PrayerType.allCases {
                guard isPrayerEnabled(prayer) else { continue }
                
                let prayerDate: Date?
                switch prayer {
                case .fajr:
                    prayerDate = solarManager.getFajrDate(for: targetDate, method: calcMethod)
                case .dhuhr:
                    prayerDate = solarManager.getDhuhrDate(for: targetDate)
                case .asr:
                    prayerDate = solarManager.getAsrDate(for: targetDate, school: asrSchoolRaw)
                case .maghrib:
                    prayerDate = solarManager.getMaghribDate(for: targetDate)
                case .isha:
                    prayerDate = solarManager.getIshaDate(for: targetDate, method: calcMethod)
                }
                
                guard let validPrayerDate = prayerDate else { continue }
                let prayerName = prayer.shortName(lang: lang)
                
                // 1. Adhan Notification (exact prayer time)
                if isAdhanEnabled && validPrayerDate > now {
                    let adhanSoundFile: String
                    if prayer == .fajr && (soundName == "azan.caf" || soundName == "fajar.caf") {
                        adhanSoundFile = "fajar.caf"
                    } else {
                        adhanSoundFile = soundName
                    }
                    
                    let title = L10n.tr("prayer_adhan_title_\(prayer.rawValue)", lang)
                    let body = L10n.tr("prayer_adhan_body", lang)
                    let sound = UNNotificationSound(named: UNNotificationSoundName(adhanSoundFile))
                    
                    scheduleNotification(
                        identifier: "PrayerAdhan_\(prayer.rawValue)_\(dayOffset)",
                        title: title,
                        body: body,
                        date: validPrayerDate,
                        sound: sound
                    )
                }
                
                // 2. 10-Minute Reminder
                if is10MinEnabled {
                    let reminderDate = validPrayerDate.addingTimeInterval(-10 * 60)
                    if reminderDate > now {
                        let title = String(format: L10n.tr("prayer_reminder_10min_title_fmt", lang), prayerName)
                        let body = String(format: L10n.tr("prayer_reminder_10min_body_fmt", lang), prayerName)
                        
                        scheduleNotification(
                            identifier: "PrayerReminder10Min_\(prayer.rawValue)_\(dayOffset)",
                            title: title,
                            body: body,
                            date: reminderDate,
                            sound: .default
                        )
                    }
                }
            }
        }
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date, sound: UNNotificationSound) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        content.sound = sound
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("[PrayerNotificationManager] Error scheduling \(identifier): \(error)")
            } else {
                print("[PrayerNotificationManager] Successfully scheduled \(identifier) for \(date)")
            }
        }
    }
    
    func cancelPrayerNotifications() {
        let center = UNUserNotificationCenter.current()
        var identifiers: [String] = []
        for day in 0..<7 {
            for prayer in PrayerType.allCases {
                identifiers.append("PrayerAdhan_\(prayer.rawValue)_\(day)")
                identifiers.append("PrayerReminder10Min_\(prayer.rawValue)_\(day)")
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("[PrayerNotificationManager] Cancelled pending prayer notifications.")
    }
    
    private func isPrayerEnabled(_ prayer: PrayerType) -> Bool {
        let key = "prayer_\(prayer.rawValue)_enabled"
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.bool(forKey: key)
        }
        return true // default enabled
    }
}
