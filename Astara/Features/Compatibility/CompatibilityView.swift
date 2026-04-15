import SwiftUI
import ComposableArchitecture

struct CompatibilityView: View {
    @Bindable var store: StoreOf<CompatibilityFeature>

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, AstaraSpacing.lg)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Sign pair selector
                        signPairSelector

                        // Result
                        if store.isCalculating {
                            ShimmerView()
                                .frame(height: 200)
                                .padding(.horizontal, AstaraSpacing.lg)
                        } else if let result = store.result {
                            resultCard(result)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                    }
                    .padding(.bottom, AstaraSpacing.xxxl)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: store.result)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showDetail },
            set: { if !$0 { store.send(.toggleDetail) } }
        )) {
            if let result = store.result {
                CompatibilityDetailView(
                    compatibility: result,
                    isPremium: store.isPremium,
                    onGoPremium: { store.send(.requestPremium) }
                )
            }
        }
        .onAppear {
            store.send(.onAppear(userSign: store.sign1))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "compatibility").uppercased())
                    .font(AstaraTypography.heroLabel)
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(2)

                Text(String(localized: "compatibility_subtitle"))
                    .font(AstaraTypography.bodyLarge)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundStyle(AstaraColors.fire.opacity(0.6))
        }
    }

    // MARK: - Sign Pair Selector

    private var signPairSelector: some View {
        VStack(spacing: AstaraSpacing.md) {
            HStack(spacing: AstaraSpacing.md) {
                // Sign 1
                signPickerButton(sign: store.sign1, label: String(localized: "first_sign")) { sign in
                    store.send(.selectSign1(sign))
                }

                // Swap button
                Button {
                    store.send(.swapSigns)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16))
                        .foregroundStyle(AstaraColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(AstaraColors.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AstaraColors.cardBorder, lineWidth: 1))
                }

                // Sign 2
                signPickerButton(sign: store.sign2, label: String(localized: "second_sign")) { sign in
                    store.send(.selectSign2(sign))
                }
            }
            .padding(.horizontal, AstaraSpacing.lg)
        }
    }

    private func signPickerButton(sign: ZodiacSign, label: String, onSelect: @escaping (ZodiacSign) -> Void) -> some View {
        Menu {
            ForEach(ZodiacSign.allCases) { s in
                Button {
                    onSelect(s)
                } label: {
                    Label("\(s.symbol) \(s.turkishName)", systemImage: "")
                }
            }
        } label: {
            VStack(spacing: AstaraSpacing.xs) {
                Text(label)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .tracking(1)
                    .textCase(.uppercase)

                Text(sign.symbol)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(AstaraColors.gold)
                    .shadow(color: AstaraColors.goldGlow, radius: 2)

                Text(sign.turkishName)
                    .font(AstaraTypography.heroLabel)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text(sign.element.localizedName)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(elementColor(sign.element))
            }
            .frame(maxWidth: .infinity)
            .padding(AstaraSpacing.md)
            .microCard()
        }
    }

    // MARK: - Result Card

    private func resultCard(_ result: Compatibility) -> some View {
        VStack(spacing: AstaraSpacing.lg) {
            // Overall score prominent
            VStack(spacing: AstaraSpacing.sm) {
                ScoreRingView(score: result.overallScore, label: String(localized: "overall"), size: 120, lineWidth: 8)

                Text(compatibilityLabel(result.overallScore).uppercased())
                    .font(AstaraTypography.heroLabel)
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(AstaraSpacing.xl)
            .chronicleCard()

            // Description excerpt
            Text(result.description)
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(AstaraColors.textSecondary)
                .lineSpacing(8)
                .multilineTextAlignment(.center)
                .padding(AstaraSpacing.lg)
                .astaraCard()

            // Sub scores
            HStack(spacing: AstaraSpacing.md) {
                miniScore(score: result.loveScore, label: String(localized: "love"), icon: "heart.fill")
                miniScore(score: result.friendshipScore, label: String(localized: "friendship"), icon: "person.2.fill")
                miniScore(score: result.workScore, label: String(localized: "work"), icon: "briefcase.fill")
            }
            .padding(.horizontal, AstaraSpacing.lg)

            // Detail button
            AstaraButton(title: String(localized: "see_full_analysis"), style: .secondary) {
                store.send(.toggleDetail)
            }
            .padding(.horizontal, AstaraSpacing.lg)
        }
        .padding(.horizontal, AstaraSpacing.lg)
    }

    private func miniScore(score: Int, label: String, icon: String) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AstaraColors.textTertiary)

            Text("\(score)")
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            Text(label)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.md)
        .microCard()
    }

    private func elementColor(_ element: Element) -> Color {
        switch element {
        case .fire: AstaraColors.fire
        case .earth: AstaraColors.earth
        case .air: AstaraColors.air
        case .water: AstaraColors.water
        }
    }

    private func compatibilityLabel(_ score: Int) -> String {
        switch score {
        case 0..<30: String(localized: "compatibility_low")
        case 30..<50: String(localized: "compatibility_medium")
        case 50..<70: String(localized: "compatibility_good")
        case 70..<85: String(localized: "compatibility_high")
        default: String(localized: "compatibility_excellent")
        }
    }
}

#Preview {
    CompatibilityView(
        store: Store(initialState: CompatibilityFeature.State(
            sign1: .pisces,
            sign2: .scorpio,
            result: .preview
        )) {
            CompatibilityFeature()
        }
    )
}
