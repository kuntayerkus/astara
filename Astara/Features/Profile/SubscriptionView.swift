import SwiftUI
import StoreKit
import ComposableArchitecture

struct SubscriptionView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: AstaraProduct = .yearlyPremium
    @State private var featuresRevealed: Bool = false
    @State private var yearlyDisplayPrice: String?
    @State private var monthlyDisplayPrice: String?

    // Feature list — all strings localized, brand-voiced
    private let features: [(icon: String, key: String)] = [
        ("sun.and.horizon.fill", "premium_feature_rising_daily"),
        ("sparkles", "premium_feature_ai_interpretation"),
        ("calendar.badge.clock", "premium_feature_week360"),
        ("questionmark.bubble.fill", "premium_feature_ask_astara"),
        ("arrow.triangle.2.circlepath", "premium_feature_transits"),
        ("heart.fill", "premium_feature_compatibility"),
        ("circle.grid.2x2.fill", "premium_feature_synastry"),
        ("clock.arrow.circlepath", "premium_feature_archive"),
        ("square.and.arrow.up", "premium_feature_share_cards"),
    ]

    var body: some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 45)
                .opacity(0.16)

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {

                        // MARK: - Hero
                        VStack(spacing: AstaraSpacing.sm) {
                            // Clipped animated chart reveal as hero visual
                            ChartRevealAnimation()
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AstaraColors.gold.opacity(0.25), lineWidth: 1)
                                )

                            VStack(spacing: 4) {
                                Text(String(localized: "premium_hero_title"))
                                    .font(AstaraTypography.displayMedium)
                                    .foregroundStyle(AstaraColors.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text(String(localized: "premium_hero_hook"))
                                    .font(AstaraTypography.bodyMedium)
                                    .foregroundStyle(AstaraColors.gold)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, AstaraSpacing.xl)
                        }

                        // MARK: - Feature List (staggered reveal)
                        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                HStack(spacing: AstaraSpacing.md) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(AstaraColors.gold)
                                        .frame(width: 24)

                                    Text(String(localized: String.LocalizationValue(feature.key)))
                                        .font(AstaraTypography.bodyMedium)
                                        .foregroundStyle(AstaraColors.textSecondary)
                                }
                                .opacity(featuresRevealed ? 1 : 0)
                                .offset(x: featuresRevealed ? 0 : -16)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.05),
                                    value: featuresRevealed
                                )
                            }
                        }
                        .padding(AstaraSpacing.lg)
                        .astaraCard()
                        .padding(.horizontal, AstaraSpacing.lg)

                        // MARK: - Pricing
                        VStack(spacing: AstaraSpacing.sm) {
                            pricingOption(
                                title: String(localized: "yearly_plan"),
                                price: yearlyDisplayPrice ?? "₺599.99 / yıl",
                                badge: String(localized: "premium_most_popular"),
                                isHighlighted: selectedPlan == .yearlyPremium
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedPlan = .yearlyPremium
                                }
                                Haptics.selection()
                            }

                            pricingOption(
                                title: String(localized: "monthly_plan"),
                                price: monthlyDisplayPrice ?? "₺79.99 / ay",
                                badge: nil,
                                isHighlighted: selectedPlan == .monthlyPremium
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedPlan = .monthlyPremium
                                }
                                Haptics.selection()
                            }
                        }
                        .padding(.horizontal, AstaraSpacing.lg)

                        // MARK: - CTA
                        AstaraButton(title: String(localized: "start_premium"), style: .primary) {
                            if selectedPlan == .yearlyPremium {
                                store.send(.purchaseYearly)
                            } else {
                                store.send(.purchaseMonthly)
                            }
                        }
                        .opacity(store.isLoadingSubscription ? 0.7 : 1)
                        .disabled(store.isLoadingSubscription)
                        .padding(.horizontal, AstaraSpacing.lg)

                        if let errorMessage = store.purchaseErrorMessage {
                            HStack(spacing: AstaraSpacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AstaraColors.ember400)
                                Text(errorMessage)
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(AstaraColors.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(AstaraSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AstaraColors.ember600.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
                            .padding(.horizontal, AstaraSpacing.lg)
                        }

                        // MARK: - Restore + Legal
                        VStack(spacing: AstaraSpacing.xs) {
                            Button(String(localized: "restore_purchases")) {
                                store.send(.restorePurchases)
                            }
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                            .disabled(store.isLoadingSubscription)

                            Text(String(localized: "subscription_legal"))
                                .font(AstaraTypography.caption)
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                featuresRevealed = true
            }
            Task { await loadDisplayPrices() }
        }
        .onChange(of: store.showSubscription) { _, isShown in
            if !isShown {
                dismiss()
            }
        }
    }

    @MainActor
    private func loadDisplayPrices() async {
        let ids = [AstaraProduct.yearlyPremium.rawValue, AstaraProduct.monthlyPremium.rawValue]
        guard let products = try? await Product.products(for: ids) else { return }
        for product in products {
            if product.id == AstaraProduct.yearlyPremium.rawValue {
                yearlyDisplayPrice = product.displayPrice
            } else if product.id == AstaraProduct.monthlyPremium.rawValue {
                monthlyDisplayPrice = product.displayPrice
            }
        }
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
                            .font(AstaraTypography.caption)
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

            ZStack {
                if isHighlighted {
                    GlowingRing(color: AstaraColors.gold, lineWidth: 1.5, glowRadius: 8)
                        .frame(width: 28, height: 28)
                }
                Image(systemName: isHighlighted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isHighlighted ? AstaraColors.gold : AstaraColors.textTertiary)
            }
        }
        .padding(AstaraSpacing.md)
        .background(isHighlighted ? AstaraColors.gold.opacity(0.08) : AstaraColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg)
                .stroke(isHighlighted ? AstaraColors.gold.opacity(0.4) : AstaraColors.cardBorder, lineWidth: isHighlighted ? 1.5 : 1)
        )
        .shadow(
            color: isHighlighted ? AstaraColors.gold.opacity(0.25) : .clear,
            radius: isHighlighted ? 16 : 0,
            y: isHighlighted ? 6 : 0
        )
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            SubscriptionView(
                store: Store(initialState: ProfileFeature.State()) {
                    ProfileFeature()
                }
            )
        }
}
