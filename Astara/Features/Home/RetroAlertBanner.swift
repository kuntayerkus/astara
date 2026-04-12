import SwiftUI

struct RetroAlertBanner: View {
    let retrogrades: [Retrograde]

    var body: some View {
        VStack(spacing: AstaraSpacing.xs) {
            ForEach(retrogrades) { retro in
                retroRow(retro: retro)
            }
        }
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
    }
}

#Preview {
    ZStack {
        GradientBackground()
        RetroAlertBanner(retrogrades: [.preview])
            .padding()
    }
}
