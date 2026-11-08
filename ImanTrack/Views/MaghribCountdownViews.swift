import SwiftUI

// MARK: - 5-Minuten-Warnung Banner (Pop-up)
struct MaghribFiveMinuteWarningBanner: View {
    let language: String
    var onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("maghrib_5min_warning_title", language))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(L10n.tr("maghrib_5min_warning_sub", language))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            
            Text(L10n.tr("maghrib_5min_warning_desc", language))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}

// MARK: - 1-Minute Countdown Banner / Regler
struct MaghribCountdownBanner: View {
    let seconds: Int
    let language: String
    var onTap: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing: Bool = false
    
    private var progress: Double {
        Double(max(0, min(60, seconds))) / 60.0
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Pulsierende Sanduhr mit sanftem Glow
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .scaleEffect(isPulsing ? 1.15 : 0.95)
                        
                        Image(systemName: "hourglass.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(L10n.tr("maghrib_countdown_title", language))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Große, prägnante Countdown-Ziffern
                            HStack(spacing: 2) {
                                Image(systemName: "timer")
                                    .font(.system(size: 11, weight: .bold))
                                Text("\(seconds)s")
                                    .font(.system(size: 17, weight: .heavy, design: .monospaced))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.18))
                            )
                        }
                        
                        Text(L10n.tr("maghrib_countdown_sub", language))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Dynamischer Fortschrittsbalken (60s -> 0s)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * progress), height: 5)
                            .animation(.linear(duration: 1.0), value: seconds)
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .shadow(color: Color.orange.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 10, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.75), Color.orange.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Tages-Reset Toast
struct MaghribDayResetToast: View {
    let language: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
                .font(.system(size: 15, weight: .bold))
            
            Text(L10n.tr("maghrib_day_reset_complete", language))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.88))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, 20)
    }
}
