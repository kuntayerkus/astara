import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 60)

            Group {
                switch store.currentStep {
                case .splash:
                    SplashView(store: store)

                case .intro:
                    IntroSlidesView(store: store)

                case .birthDate, .birthTime, .birthCity:
                    BirthDataInputView(store: store)

                case .loading, .chartReveal:
                    ChartRevealView(store: store)

                case .summary:
                    summaryView

                case .pushPermission:
                    pushPermissionView
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.4), value: store.currentStep)
        .preferredColorScheme(.dark)
    }

    // MARK: - Summary View

    private var summaryView: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Spacer()

            if let chart = store.chart {
                Text(String(localized: "your_big_three"))
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.gold)

                VStack(spacing: AstaraSpacing.md) {
                    if let sun = chart.sunSign {
                        summaryRow(title: String(localized: "sun"), sign: sun)
                    }
                    if let moon = chart.moonSign {
                        summaryRow(title: String(localized: "moon"), sign: moon)
                    }
                    if let rising = chart.risingSign {
                        summaryRow(title: String(localized: "rising"), sign: rising)
                    }
                }
                .padding(AstaraSpacing.lg)
                .astaraCard()
            }

            Spacer()

            AstaraButton(title: String(localized: "continue"), style: .primary) {
                store.send(.nextStep)
            }
            .padding(.horizontal, AstaraSpacing.lg)
        }
        .padding(.bottom, AstaraSpacing.xxl)
    }

    private func summaryRow(title: String, sign: ZodiacSign) -> some View {
        HStack {
            Text(title)
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textSecondary)

            Spacer()

            HStack(spacing: AstaraSpacing.xs) {
                ZodiacIcon(sign: sign, size: 24)
                Text(sign.turkishName)
                    .font(AstaraTypography.bodyLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
            }
        }
    }

    // MARK: - Push Permission View

    private var pushPermissionView: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(AstaraColors.gold)

            Text(String(localized: "push_title"))
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "push_subtitle"))
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AstaraSpacing.xl)

            Spacer()

            VStack(spacing: AstaraSpacing.sm) {
                AstaraButton(title: String(localized: "allow_notifications"), style: .primary) {
                    store.send(.requestPushPermission)
                }

                AstaraButton(title: String(localized: "maybe_later"), style: .ghost) {
                    store.send(.completeOnboarding)
                }
            }
            .padding(.horizontal, AstaraSpacing.lg)
        }
        .padding(.bottom, AstaraSpacing.xxl)
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
