import SwiftUI

struct ChartShareView: View {
    let chart: BirthChart
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 50).opacity(0.2)

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Header
                        HStack {
                            Text(String(localized: "share_chart"))
                                .font(AstaraTypography.titleLarge)
                                .foregroundStyle(AstaraColors.textPrimary)
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AstaraColors.textTertiary)
                            }
                        }
                        .padding(.horizontal, AstaraSpacing.lg)

                        // Preview card
                        shareCard
                            .padding(.horizontal, AstaraSpacing.lg)

                        // Share button
                        AstaraButton(title: String(localized: "share_button"), style: .primary) {
                            ShareManager.shareAsImage(shareCard)
                        }
                        .padding(.horizontal, AstaraSpacing.lg)
                    }
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var shareCard: some View {
        VStack(spacing: AstaraSpacing.lg) {
            // Wordmark
            Text("ASTARA")
                .font(.custom("CormorantGaramond-Bold", size: 30))
                .foregroundStyle(AstaraColors.gold)
                .tracking(8)

            // Decorative separator
            HStack(spacing: AstaraSpacing.sm) {
                Rectangle()
                    .fill(AstaraColors.gold.opacity(0.3))
                    .frame(height: 1)
                Text("✦")
                    .font(.system(size: 12))
                    .foregroundStyle(AstaraColors.gold.opacity(0.5))
                Rectangle()
                    .fill(AstaraColors.gold.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, AstaraSpacing.md)

            // Big Three
            HStack(spacing: 0) {
                if let sun = chart.sunSign {
                    signBadge(symbol: "☉", label: String(localized: "sun_short"), sign: sun, color: AstaraColors.gold)
                }
                if chart.sunSign != nil {
                    Rectangle().fill(AstaraColors.cardBorder).frame(width: 1, height: 60)
                }
                if let moon = chart.moonSign {
                    signBadge(symbol: "☽", label: String(localized: "moon_short"), sign: moon, color: AstaraColors.mist400)
                }
                if chart.moonSign != nil {
                    Rectangle().fill(AstaraColors.cardBorder).frame(width: 1, height: 60)
                }
                if let rising = chart.risingSign {
                    signBadge(symbol: "ASC", label: String(localized: "rising_short"), sign: rising, color: AstaraColors.goldLight)
                }
            }
            .padding(.vertical, AstaraSpacing.sm)

            // Watermark
            HStack(spacing: AstaraSpacing.xxs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(AstaraColors.gold.opacity(0.4))
                Text("astara.app")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
        }
        .padding(AstaraSpacing.xl)
        .background(
            ZStack {
                LinearGradient(
                    colors: [AstaraColors.gold.opacity(0.08), AstaraColors.backgroundEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                StarfieldView(starCount: 20).opacity(0.15)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusXl))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusXl)
                .stroke(AstaraColors.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func signBadge(symbol: String, label: String, sign: ZodiacSign, color: Color) -> some View {
        VStack(spacing: AstaraSpacing.xxs) {
            Text(symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            Text(sign.symbol)
                .font(.system(size: 26))
            Text(sign.turkishName)
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AstaraColors.textTertiary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ChartShareView(chart: .preview)
        }
}
