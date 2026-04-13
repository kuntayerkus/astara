import SwiftUI

struct HoroscopeCardView: View {
    let horoscope: DailyHoroscope

    var body: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.lg) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AstaraSpacing.xs) {
                    HStack(spacing: AstaraSpacing.sm) {
                        Text(horoscope.sign.symbol)
                            .font(.system(size: 32))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(horoscope.sign.turkishName)
                                .font(AstaraTypography.titleLarge)
                                .foregroundStyle(AstaraColors.textPrimary)

                            Text(horoscope.theme.uppercased())
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.gold)
                                .tracking(2)
                        }
                    }

                    Text(horoscope.date)
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }

                Spacer()

                energyGauge
            }

            // Divider
            Rectangle()
                .fill(AstaraColors.cardBorder)
                .frame(height: 1)

            // Text
            Text(horoscope.text)
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(AstaraColors.textSecondary)
                .lineSpacing(6)

            // Tip box
            HStack(alignment: .top, spacing: AstaraSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.gold)
                    .padding(.top, 2)

                Text(horoscope.tip)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.goldLight)
                    .lineSpacing(4)
            }
            .padding(AstaraSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AstaraColors.gold.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusSm))

            // Lucky row
            if let number = horoscope.luckyNumber, let color = horoscope.luckyColor {
                HStack(spacing: AstaraSpacing.lg) {
                    luckyBadge(icon: "number.circle.fill", label: String(localized: "lucky_number"), value: "\(number)")
                    luckyBadge(icon: "circle.fill", label: String(localized: "lucky_color"), value: color)
                    Spacer()
                }
            }
        }
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    // MARK: - Energy Gauge

    private var energyGauge: some View {
        ZStack {
            Circle()
                .stroke(AstaraColors.cardBorder, lineWidth: 5)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: CGFloat(horoscope.energy) / 100)
                .stroke(energyColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: horoscope.energy)

            VStack(spacing: 0) {
                Text("\(horoscope.energy)")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text(String(localized: "energy"))
                    .font(.system(size: 8))
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

    // MARK: - Lucky Badge

    private func luckyBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AstaraColors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(AstaraColors.textTertiary)
                Text(value)
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
        }
    }
}

#Preview {
    HoroscopeCardView(horoscope: .preview)
        .padding()
        .astaraBackground()
}
