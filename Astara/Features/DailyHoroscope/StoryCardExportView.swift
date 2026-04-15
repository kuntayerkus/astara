import SwiftUI

/// A vertical 9:16 view designed specifically as a shareable Instagram/TikTok Story card.
/// Combines the "Brutally Honest" text with the "Optimized Liquid Glass" aesthetic.
struct StoryCardExportView: View {
    let horoscope: DailyHoroscope

    var body: some View {
        ZStack {
            GradientBackground(ambient: .daily)

            VStack(spacing: AstaraSpacing.xl) {
                // Header (App Branding)
                HStack {
                    Text("ASTARA")
                        .font(AstaraTypography.heroLabel)
                        .foregroundStyle(AstaraColors.gold)
                        .tracking(4)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(AstaraColors.gold)
                }
                .padding(.horizontal, AstaraSpacing.xl)
                .padding(.top, AstaraSpacing.xxxl)

                Spacer()

                // Brutal Body
                VStack(spacing: AstaraSpacing.lg) {
                    Text(horoscope.sign.turkishName.uppercased())
                        .font(AstaraTypography.heroDisplay)
                        .foregroundStyle(AstaraColors.textPrimary)
                        .shadow(color: AstaraColors.goldGlow, radius: 4)

                    OrnamentalDivider(opacity: 0.3)

                    Text(horoscope.text)
                        .font(AstaraTypography.bodyLarge)
                        .foregroundStyle(AstaraColors.textSecondary)
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AstaraSpacing.md)

                    // Brutal Tip
                    HStack(spacing: AstaraSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AstaraColors.ember400)
                        Text(horoscope.tip)
                            .font(AstaraTypography.sectionMark)
                            .foregroundStyle(AstaraColors.textPrimary)
                    }
                    .padding(AstaraSpacing.md)
                    .background(AstaraColors.ember400.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                            .stroke(AstaraColors.ember400.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(AstaraSpacing.xl)
                .astaraLiquidGlass(style: .deep, cornerRadius: AstaraSpacing.cornerRadiusXl)
                .padding(.horizontal, AstaraSpacing.lg)

                Spacer()

                // Footer CTA
                Text("@getastara")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .padding(.bottom, AstaraSpacing.xxxl)
            }
        }
        .frame(width: 1080 / 3, height: 1920 / 3) // Standard 9:16 aspect ratio for IG stories (downscaled for rendering speed)
        .ignoresSafeArea()
    }
}

/// Helper extension to convert any view into a UIImage for sharing
extension View {
    @MainActor
    func snapshot() -> UIImage {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}
