import SwiftUI
import UserNotifications

struct NotificationPermissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Theme.islamicGreen.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Theme.islamicGreen)
            }
            
            VStack(spacing: 12) {
                Text("Adhkar- & Salawat-Erinnerungen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text("Bleibe regelmäßig mit deinen täglichen Adhkar und Salawat verbunden. Aktiviere Mitteilungen, um sanfte Erinnerungen zu den passenden Gebetszeiten zu erhalten.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    AdhkarReminderManager.shared.requestAuthorization { granted in
                        Task { @MainActor in
                            if granted {
                                AdhkarReminderManager.shared.scheduleReminders()
                            }
                            onComplete?()
                            dismiss()
                        }
                    }
                }) {
                    Text("Mitteilungen erlauben")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.islamicGreen)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    AdhkarReminderManager.shared.hasPromptedNotificationPermissionAfterFirstSession = true
                    onComplete?()
                    dismiss()
                }) {
                    Text("Später")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
        .background(Theme.background.ignoresSafeArea())
    }
}
