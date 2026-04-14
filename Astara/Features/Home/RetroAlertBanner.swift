import SwiftUI

struct RetroAlertBanner: View {
    let retrogrades: [Retrograde]
    @State private var glowPulsing = false

    var body: some View {
        VStack(spacing: AstaraSpacing.xs) {
            ForEach(retrogrades) { retro in
                retroRow(retro: retro)
            }
        }
        .onAppear { glowPulsing = true }
    }

    private func retroRow(retro: Retrograde) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AstaraColors.ember400)
                .symbolEffect(.pulse)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(retro.planet.turkishName) \(String(localized: "retro_active"))")
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text("\(retro.startDate) - \(retro.endDate)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(AstaraSpacing.md)
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                .stroke(
                    AstaraColors.ember400.opacity(glowPulsing ? 0.5 : 0.12),
                    lineWidth: 1
                )
                .shadow(
                    color: AstaraColors.ember400.opacity(glowPulsing ? 0.35 : 0.0),
                    radius: 8
                )
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowPulsing)
        )
        .scaleEffect(glowPulsing ? 1.004 : 1.0)
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowPulsing)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        RetroAlertBanner(retrogrades: [.preview])
            .padding()
    }
}
