import SwiftUI

struct PremiumLockOverlay: View {
    var title: String = "Premium ile aç"
    var subtitle: String = "Tüm içeriği görmek için premium'a geç"
    var onTap: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [Color.clear, AstaraColors.backgroundStart.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: AstaraSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(AstaraColors.gold.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(AstaraColors.gold)
                }

                Text(title)
                    .font(AstaraTypography.titleMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AstaraSpacing.lg)

                Button {
                    Haptics.light()
                    onTap()
                } label: {
                    HStack(spacing: AstaraSpacing.xs) {
                        Image(systemName: "star.circle.fill")
                        Text(String(localized: "go_premium"))
                            .font(AstaraTypography.labelLarge)
                    }
                    .foregroundStyle(AstaraColors.backgroundStart)
                    .frame(height: 46)
                    .padding(.horizontal, AstaraSpacing.xl)
                    .background(
                        LinearGradient(
                            colors: [AstaraColors.gold, AstaraColors.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: AstaraColors.gold.opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(AstaraSpringButtonStyle())
            }
            .padding(AstaraSpacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
    }
}

#Preview {
    ZStack {
        GradientBackground()
        PremiumLockOverlay(
            title: "Haftalık tahvil",
            subtitle: "Tüm 7 günlük transitleri görmek için premium'a geç"
        ) {}
        .frame(height: 280)
        .padding()
    }
}
