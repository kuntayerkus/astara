import SwiftUI
import ComposableArchitecture

struct ChartView: View {
    @Bindable var store: StoreOf<ChartFeature>

    var body: some View {
        ZStack {
            GradientBackground()

            if let chart = store.chart {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "natal_chart"))
                                    .font(AstaraTypography.displayMedium)
                                    .foregroundStyle(AstaraColors.textPrimary)
                                Text(String(localized: "birth_chart_subtitle"))
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(AstaraColors.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, AstaraSpacing.lg)

                        // Big Three header
                        bigThreeHeader(chart: chart)
                            .padding(.horizontal, AstaraSpacing.lg)

                        // Chart wheel
                        ChartWheelView(
                            chart: chart,
                            onPlanetTap: { key in
                                store.send(.selectPlanet(key))
                            },
                            onHouseTap: { number in
                                store.send(.selectHouse(number))
                            }
                        )
                        .padding(.horizontal, AstaraSpacing.sm)

                        // Element distribution
                        elementDistribution(chart: chart)
                            .padding(.horizontal, AstaraSpacing.lg)

                        // Planet list
                        planetList(chart: chart)
                            .padding(.horizontal, AstaraSpacing.lg)

                        // Aspects button
                        AstaraButton(title: String(localized: "view_aspects"), style: .secondary) {
                            store.send(.toggleAspectGrid)
                        }
                        .padding(.horizontal, AstaraSpacing.lg)
                    }
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            } else {
                emptyState
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.showPlanetDetail },
                set: { if !$0 { store.send(.dismissPlanetDetail) } }
            )
        ) {
            if let key = store.selectedPlanet, let chart = store.chart {
                PlanetDetailSheet(chart: chart, planetKey: key)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.showHouseDetail },
                set: { if !$0 { store.send(.dismissHouseDetail) } }
            )
        ) {
            if let number = store.selectedHouse, let chart = store.chart {
                HouseDetailSheet(chart: chart, houseNumber: number)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.showAspectGrid },
                set: { if !$0 { store.send(.toggleAspectGrid) } }
            )
        ) {
            if let chart = store.chart {
                AspectGridView(chart: chart)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Big Three Header

    private func bigThreeHeader(chart: BirthChart) -> some View {
        HStack(spacing: 0) {
            if let sun = chart.sunSign {
                bigThreeItem(
                    symbol: "\u{2609}",
                    label: String(localized: "sun_short"),
                    sign: sun,
                    degree: chart.planet(for: .gunes)?.formattedDegree ?? "",
                    color: AstaraColors.gold
                )
            }
            separator
            if let moon = chart.moonSign {
                bigThreeItem(
                    symbol: "\u{263D}",
                    label: String(localized: "moon_short"),
                    sign: moon,
                    degree: chart.planet(for: .ay)?.formattedDegree ?? "",
                    color: AstaraColors.mist400
                )
            }
            separator
            if let rising = chart.risingSign {
                bigThreeItem(
                    symbol: "ASC",
                    label: String(localized: "rising_short"),
                    sign: rising,
                    degree: chart.planet(for: .yukselen)?.formattedDegree ?? "",
                    color: AstaraColors.goldLight
                )
            }
        }
        .padding(.vertical, AstaraSpacing.md)
        .astaraCard()
    }

    private func bigThreeItem(symbol: String, label: String, sign: ZodiacSign, degree: String, color: Color) -> some View {
        VStack(spacing: AstaraSpacing.xxs) {
            Text(symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
            Text(sign.symbol)
                .font(.system(size: 24))
            Text(sign.turkishName)
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(degree)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(color.opacity(0.7))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var separator: some View {
        Rectangle()
            .fill(AstaraColors.cardBorder)
            .frame(width: 1, height: 64)
    }

    // MARK: - Element Distribution

    private func elementDistribution(chart: BirthChart) -> some View {
        let dist = chart.elementDistribution

        return HStack(spacing: AstaraSpacing.sm) {
            ForEach(Element.allCases, id: \.self) { element in
                let count = dist[element] ?? 0
                VStack(spacing: AstaraSpacing.xxs) {
                    Text(elementEmoji(element))
                        .font(.system(size: 16))
                    Text("\(count)")
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.textPrimary)
                    Text(element.localizedName)
                        .font(.system(size: 10))
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AstaraSpacing.sm)
                .background(elementBarColor(element).opacity(Double(count) * 0.03 + 0.03))
                .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusSm))
            }
        }
        .padding(AstaraSpacing.sm)
        .astaraCard()
    }

    // MARK: - Planet List

    private func planetList(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "planets"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            LazyVStack(spacing: 1) {
                ForEach(chart.planets.filter { $0.key.isPlanet }) { planet in
                    Button {
                        store.send(.selectPlanet(planet.key))
                    } label: {
                        planetRow(planet: planet, chart: chart)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusSm))
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func planetRow(planet: Planet, chart: BirthChart) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Text(planet.key.symbol)
                .font(.system(size: 20))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(planet.key.turkishName)
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                HStack(spacing: AstaraSpacing.xxs) {
                    Text(planet.sign.symbol)
                        .font(.system(size: 12))
                    Text("\(planet.sign.turkishName) \(planet.formattedDegree)")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textSecondary)
                }
            }

            Spacer()

            if planet.isRetrograde {
                Text("℞")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AstaraColors.ember400)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AstaraColors.ember400.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let house = chart.houseForPlanet(planet.key) {
                Text("H\(house)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(.vertical, AstaraSpacing.sm)
        .padding(.horizontal, AstaraSpacing.xs)
        .background(AstaraColors.cardBackground.opacity(0.3))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Image(systemName: "circle.grid.cross.fill")
                .font(.system(size: 56))
                .foregroundStyle(AstaraColors.gold.opacity(0.2))

            Text(String(localized: "no_chart_data"))
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textTertiary)

            Text(String(localized: "chart_empty_hint"))
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AstaraSpacing.xxl)
        }
    }

    // MARK: - Helpers

    private func elementEmoji(_ element: Element) -> String {
        switch element {
        case .fire: "🔥"
        case .earth: "🌿"
        case .air: "💨"
        case .water: "💧"
        }
    }

    private func elementBarColor(_ element: Element) -> Color {
        switch element {
        case .fire: AstaraColors.fire
        case .earth: AstaraColors.earth
        case .air: AstaraColors.air
        case .water: AstaraColors.water
        }
    }
}

#Preview {
    ChartView(
        store: Store(
            initialState: ChartFeature.State(chart: .preview)
        ) {
            ChartFeature()
        }
    )
}
