import SwiftUI
import ComposableArchitecture

struct ChartRevealView: View {
    let store: StoreOf<OnboardingFeature>

    @State private var showSummary = false

    var body: some View {
        VStack(spacing: AstaraSpacing.xl) {
            Spacer()

            if let error = store.chartError {
                errorState(message: error)
            } else if store.isLoading || store.currentStep == .loading {
                loadingState
            } else if let chart = store.chart {
                revealState(chart: chart)
            }

            Spacer()

            if !store.isLoading && store.chart != nil && store.chartError == nil {
                AstaraButton(title: String(localized: "continue"), style: .primary) {
                    store.send(.nextStep)
                }
                .padding(.horizontal, AstaraSpacing.lg)
                .opacity(showSummary ? 1 : 0)
            }
        }
        .padding(.bottom, AstaraSpacing.xxl)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: AstaraSpacing.lg) {
            PulseAnimation(color: AstaraColors.gold, size: 60)
                .frame(width: 120, height: 120)

            Text(String(localized: "calculating_chart"))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textSecondary)

            Text(String(localized: "calculating_chart_subtitle"))
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
        }
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: AstaraSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AstaraColors.ember400)

            Text(String(localized: "chart_error_title"))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            Text(message)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AstaraSpacing.xl)

            VStack(spacing: AstaraSpacing.sm) {
                AstaraButton(title: String(localized: "retry"), style: .primary) {
                    store.send(.calculateChart)
                }

                AstaraButton(title: String(localized: "use_sample_chart"), style: .ghost) {
                    store.send(.chartCalculated(.preview))
                }
            }
            .padding(.horizontal, AstaraSpacing.lg)
        }
    }

    // MARK: - Reveal State

    private func revealState(chart: BirthChart) -> some View {
        VStack(spacing: AstaraSpacing.xl) {
            // Chart wheel animation
            ChartRevealAnimation()
                .frame(width: 280, height: 280)

            // Big Three summary card
            if showSummary {
                VStack(spacing: AstaraSpacing.md) {
                    Text(String(localized: "your_chart"))
                        .font(AstaraTypography.displayMedium)
                        .foregroundStyle(AstaraColors.gold)

                    VStack(spacing: AstaraSpacing.sm) {
                        if let sun = chart.sunSign {
                            bigThreeRow(
                                label: String(localized: "sun_sign"),
                                sign: sun,
                                emoji: "\u{2609}"
                            )
                        }
                        if let moon = chart.moonSign {
                            bigThreeRow(
                                label: String(localized: "moon_sign"),
                                sign: moon,
                                emoji: "\u{263D}"
                            )
                        }
                        if let rising = chart.risingSign {
                            bigThreeRow(
                                label: String(localized: "rising_sign"),
                                sign: rising,
                                emoji: "ASC"
                            )
                        }
                    }
                }
                .padding(AstaraSpacing.lg)
                .astaraCard()
                .padding(.horizontal, AstaraSpacing.lg)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(2.2)) {
                showSummary = true
            }
        }
    }

    private func bigThreeRow(label: String, sign: ZodiacSign, emoji: String) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 30)

            Text(label)
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.textSecondary)

            Spacer()

            HStack(spacing: AstaraSpacing.xxs) {
                Text(sign.symbol)
                Text(sign.turkishName)
                    .font(AstaraTypography.bodyLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
            }
        }
    }
}

#Preview("Loading") {
    ZStack {
        GradientBackground()
        StarfieldView()
        ChartRevealView(
            store: Store(
                initialState: OnboardingFeature.State(currentStep: .loading, isLoading: true)
            ) {
                OnboardingFeature()
            }
        )
    }
}

#Preview("Revealed") {
    ZStack {
        GradientBackground()
        StarfieldView()
        ChartRevealView(
            store: Store(
                initialState: OnboardingFeature.State(
                    currentStep: .chartReveal,
                    chart: .preview,
                    isLoading: false
                )
            ) {
                OnboardingFeature()
            }
        )
    }
}

#Preview("Error") {
    ZStack {
        GradientBackground()
        StarfieldView()
        ChartRevealView(
            store: Store(
                initialState: OnboardingFeature.State(
                    currentStep: .loading,
                    isLoading: false,
                    chartError: "Network connection failed. Please check your internet."
                )
            ) {
                OnboardingFeature()
            }
        )
    }
}
