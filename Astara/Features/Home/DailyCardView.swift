import SwiftUI

struct DailyCardView: View {
    let horoscope: DailyHoroscope

    var body: some View {
        VStack(spacing: AstaraSpacing.md) {
            // Header: Sign + Energy Ring
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                    HStack(spacing: AstaraSpacing.xs) {
                        Text(horoscope.sign.symbol)
                            .font(.system(size: 24))
                        Text(horoscope.sign.turkishName)
                            .font(AstaraTypography.titleLarge)
                            .foregroundStyle(AstaraColors.textPrimary)
                    }

                    Text(horoscope.theme)
                        .font(AstaraTypography.labelMedium)
                        .foregroundStyle(AstaraColors.gold)
                }

                Spacer()

                // Energy ring
                energyRing
            }

            // Horoscope text
            Text(horoscope.text)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .lineSpacing(4)

            // Tip
            HStack(spacing: AstaraSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AstaraColors.gold)

                Text(horoscope.tip)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.goldLight)
            }
            .padding(AstaraSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AstaraColors.gold.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusSm))

            // Lucky row
            if let number = horoscope.luckyNumber, let color = horoscope.luckyColor {
                HStack {
                    luckyItem(icon: "number", text: "\(number)")
                    Spacer()
                    luckyItem(icon: "paintpalette.fill", text: color)
                }
            }
        }
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    // MARK: - Energy Ring

    private var energyRing: some View {
        ZStack {
            Circle()
                .stroke(AstaraColors.cardBorder, lineWidth: 4)
                .frame(width: 56, height: 56)

            Circle()
                .trim(from: 0, to: CGFloat(horoscope.energy) / 100)
                .stroke(
                    energyColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(horoscope.energy)")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("%")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
        }
    }

    private var energyColor: Color {
        switch horoscope.energy {
        case 0..<30: AstaraColors.fire
        case 30..<60: AstaraColors.ember400
        case 60..<80: AstaraColors.gold
        default: AstaraColors.sage400
        }
    }

    private func luckyItem(icon: String, text: String) -> some View {
        HStack(spacing: AstaraSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AstaraColors.textTertiary)
            Text(text)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
    }
}

#Preview {
    DailyCardView(horoscope: .preview)
        .padding()
        .astaraBackground()
}
