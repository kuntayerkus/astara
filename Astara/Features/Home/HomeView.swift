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

            placeholderTab(title: String(localized: "tab_chart"), icon: "circle.grid.cross.fill")
                .tag(HomeFeature.Tab.chart)
                .tabItem {
                    Label(HomeFeature.Tab.chart.title, systemImage: HomeFeature.Tab.chart.icon)
                }

            placeholderTab(title: String(localized: "tab_daily"), icon: "sun.max.fill")
                .tag(HomeFeature.Tab.daily)
                .tabItem {
                    Label(HomeFeature.Tab.daily.title, systemImage: HomeFeature.Tab.daily.icon)
                }

            placeholderTab(title: String(localized: "tab_compatibility"), icon: "heart.fill")
                .tag(HomeFeature.Tab.compatibility)
                .tabItem {
                    Label(HomeFeature.Tab.compatibility.title, systemImage: HomeFeature.Tab.compatibility.icon)
                }

            placeholderTab(title: String(localized: "tab_profile"), icon: "person.fill")
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
                        retroAlert
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
                    }

                    // Element energy
                    if !store.elementEnergy.isEmpty {
                        elementEnergySection
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

    // MARK: - Retro Alert

    private var retroAlert: some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AstaraColors.ember400)

            VStack(alignment: .leading, spacing: 2) {
                if let retro = store.activeRetrogrades.first {
                    Text("\(retro.planet.turkishName) Retrosu Aktif")
                        .font(AstaraTypography.labelMedium)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Text("\(retro.startDate) - \(retro.endDate)")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(AstaraSpacing.md)
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
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

    // MARK: - Placeholder Tab

    private func placeholderTab(title: String, icon: String) -> some View {
        ZStack {
            GradientBackground()
            VStack(spacing: AstaraSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(AstaraColors.gold.opacity(0.3))
                Text(title)
                    .font(AstaraTypography.titleLarge)
                    .foregroundStyle(AstaraColors.textTertiary)
                Text(String(localized: "coming_soon"))
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
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
