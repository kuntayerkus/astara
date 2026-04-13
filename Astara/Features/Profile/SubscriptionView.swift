import SwiftUI

struct SubscriptionView: View {
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, text: String)] = [
        ("sun.and.horizon.fill", "Yükselen burç günlük yorumu"),
        ("sparkles", "AI kişisel yorum (Gemini)"),
        ("arrow.triangle.2.circlepath", "Tam transit takibi"),
        ("heart.fill", "Sınırsız uyum testi"),
        ("circle.grid.2x2.fill", "Synastry — iki harita"),
        ("clock.arrow.circlepath", "Geçmiş gün arşivi"),
        ("square.and.arrow.up", "Özel paylaşım kartları"),
    ]

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Hero
                        VStack(spacing: AstaraSpacing.sm) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(AstaraColors.gold)

                            Text("Astara Premium")
                                .font(AstaraTypography.displayMedium)
                                .foregroundStyle(AstaraColors.textPrimary)

                            Text(String(localized: "premium_hero_subtitle"))
                                .font(AstaraTypography.bodyMedium)
                                .foregroundStyle(AstaraColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AstaraSpacing.xl)
                        }

                        // Feature list
                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            ForEach(features, id: \.icon) { feature in
                                HStack(spacing: AstaraSpacing.md) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(AstaraColors.gold)
                                        .frame(width: 24)

                                    Text(feature.text)
                                        .font(AstaraTypography.bodyMedium)
                                        .foregroundStyle(AstaraColors.textSecondary)
                                }
                            }
                        }
                        .padding(AstaraSpacing.lg)
                        .astaraCard()
                        .padding(.horizontal, AstaraSpacing.lg)

                        // Pricing
                        VStack(spacing: AstaraSpacing.sm) {
                            pricingOption(
                                title: String(localized: "yearly_plan"),
                                price: "₺599.99 / yıl",
                                badge: String(localized: "best_value"),
                                isHighlighted: true
                            )

                            pricingOption(
                                title: String(localized: "monthly_plan"),
                                price: "₺79.99 / ay",
                                badge: nil,
                                isHighlighted: false
                            )
                        }
                        .padding(.horizontal, AstaraSpacing.lg)

                        // CTA
                        AstaraButton(title: String(localized: "start_premium"), style: .primary) {
                            dismiss()
                        }
                        .padding(.horizontal, AstaraSpacing.lg)

                        // Restore + legal
                        VStack(spacing: AstaraSpacing.xs) {
                            Button(String(localized: "restore_purchases")) {}
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.textTertiary)

                            Text(String(localized: "subscription_legal"))
                                .font(.system(size: 10))
                                .foregroundStyle(AstaraColors.textTertiary.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AstaraSpacing.xl)
                        }
                    }
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func pricingOption(title: String, price: String, badge: String?, isHighlighted: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AstaraSpacing.sm) {
                    Text(title)
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.textPrimary)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 10))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AstaraColors.gold)
                            .clipShape(Capsule())
                    }
                }

                Text(price)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
            }

            Spacer()

            Image(systemName: isHighlighted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isHighlighted ? AstaraColors.gold : AstaraColors.textTertiary)
        }
        .padding(AstaraSpacing.md)
        .background(isHighlighted ? AstaraColors.gold.opacity(0.08) : AstaraColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                .stroke(isHighlighted ? AstaraColors.gold.opacity(0.3) : AstaraColors.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            SubscriptionView(isPremium: false)
        }
}
