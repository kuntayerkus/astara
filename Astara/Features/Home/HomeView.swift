import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
                .tag(HomeFeature.Tab.home)
                .tabItem {
                    Label(HomeFeature.Tab.home.title, systemImage: HomeFeature.Tab.home.icon)
                }

            ChartView(store: store.scope(state: \.chart, action: \.chart))
                .tag(HomeFeature.Tab.chart)
                .tabItem {
                    Label(HomeFeature.Tab.chart.title, systemImage: HomeFeature.Tab.chart.icon)
                }

            DailyHoroscopeView(store: store.scope(state: \.daily, action: \.daily))
                .tag(HomeFeature.Tab.daily)
                .tabItem {
                    Label(HomeFeature.Tab.daily.title, systemImage: HomeFeature.Tab.daily.icon)
                }

            CompatibilityView(store: store.scope(state: \.compatibility, action: \.compatibility))
                .tag(HomeFeature.Tab.compatibility)
                .tabItem {
                    Label(HomeFeature.Tab.compatibility.title, systemImage: HomeFeature.Tab.compatibility.icon)
                }

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tag(HomeFeature.Tab.profile)
                .tabItem {
                    Label(HomeFeature.Tab.profile.title, systemImage: HomeFeature.Tab.profile.icon)
                }
        }
        .tint(AstaraColors.gold)
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.md) {
                    // Header
                    header
                        .padding(.horizontal, AstaraSpacing.lg)

                    // Retro alert
                    if !store.activeRetrogrades.isEmpty {
                        RetroAlertBanner(retrogrades: store.activeRetrogrades)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Daily energy card
                    if let horoscope = store.dailyHoroscope {
                        DailyCardView(horoscope: horoscope)
                            .padding(.horizontal, AstaraSpacing.lg)
                    } else if store.isLoading {
                        ShimmerView()
                            .frame(height: 200)
                            .padding(.horizontal, AstaraSpacing.lg)
                    } else if let errorMessage = store.errorMessage {
                        errorBanner(message: errorMessage)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Element energy
                    if !store.elementEnergy.isEmpty {
                        elementEnergySection
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Planet positions
                    if !store.planetPositions.isEmpty {
                        PlanetPositionsView(planets: store.planetPositions)
                            .padding(.horizontal, AstaraSpacing.lg)
                    }

                    // Last updated
                    if let lastUpdated = store.lastUpdated {
                        Text("\(String(localized: "last_updated")): \(AstaraDateFormatters.timeOnly.string(from: lastUpdated))")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                            .padding(.top, AstaraSpacing.sm)
                    }
                }
                .padding(.top, AstaraSpacing.md)
                .padding(.bottom, AstaraSpacing.xxxl)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(AstaraColors.gold)

            Text(message)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)

            AstaraButton(title: String(localized: "retry"), style: .secondary) {
                store.send(.retryDailyData)
            }
            .frame(maxWidth: 160)
        }
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                Text(String(localized: "good_morning"))
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textSecondary)

                Text("ASTARA")
                    .font(.custom("CormorantGaramond-Bold", size: 28))
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(4)
            }

            Spacer()

            // Profile button
            Button {
                store.send(.selectTab(.profile))
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(AstaraColors.gold)
            }
        }
    }

    // MARK: - Element Energy

    private var elementEnergySection: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "element_energy"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            VStack(spacing: AstaraSpacing.xs) {
                elementBar(element: .fire, value: store.elementEnergy[.fire] ?? 0)
                elementBar(element: .earth, value: store.elementEnergy[.earth] ?? 0)
                elementBar(element: .air, value: store.elementEnergy[.air] ?? 0)
                elementBar(element: .water, value: store.elementEnergy[.water] ?? 0)
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func elementBar(element: Element, value: Int) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Text(elementEmoji(element))
                .frame(width: 24)

            Text(element.localizedName)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AstaraColors.cardBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(elementColor(element))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 8)

            Text("\(value)%")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
                .frame(width: 35, alignment: .trailing)
        }
    }

    private func elementColor(_ element: Element) -> Color {
        switch element {
        case .fire: AstaraColors.fire
        case .earth: AstaraColors.earth
        case .air: AstaraColors.air
        case .water: AstaraColors.water
        }
    }

    private func elementEmoji(_ element: Element) -> String {
        switch element {
        case .fire: "🔥"
        case .earth: "🌿"
        case .air: "💨"
        case .water: "💧"
        }
    }

}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
