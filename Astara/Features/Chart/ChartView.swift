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
                        .padding(.horizontal, AstaraSpacing.md)

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
        HStack(spacing: AstaraSpacing.md) {
            if let sun = chart.sunSign {
                bigThreeItem(label: String(localized: "sun_short"), sign: sun, symbol: "\u{2609}")
            }
            if let moon = chart.moonSign {
                bigThreeItem(label: String(localized: "moon_short"), sign: moon, symbol: "\u{263D}")
            }
            if let rising = chart.risingSign {
                bigThreeItem(label: String(localized: "rising_short"), sign: rising, symbol: "ASC")
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func bigThreeItem(label: String, sign: ZodiacSign, symbol: String) -> some View {
        VStack(spacing: AstaraSpacing.xxs) {
            Text(symbol)
                .font(.system(size: 18))
                .foregroundStyle(AstaraColors.gold)
            Text(sign.symbol)
                .font(.system(size: 20))
            Text(label)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Planet List

    private func planetList(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "planets"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            LazyVStack(spacing: AstaraSpacing.xs) {
                ForEach(chart.planets.filter { $0.key.isPlanet }) { planet in
                    Button {
                        store.send(.selectPlanet(planet.key))
                    } label: {
                        planetRow(planet: planet, chart: chart)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func planetRow(planet: Planet, chart: BirthChart) -> some View {
        HStack {
            Text(planet.key.symbol)
                .font(.system(size: 20))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(planet.key.turkishName)
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text("\(planet.sign.turkishName) \(planet.formattedDegree)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
            }

            Spacer()

            if planet.isRetrograde {
                Text("R")
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.ember400)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AstaraColors.ember400.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let house = chart.houseForPlanet(planet.key) {
                Text("H\(house)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .padding(.vertical, AstaraSpacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AstaraSpacing.md) {
            Image(systemName: "circle.grid.cross.fill")
                .font(.system(size: 48))
                .foregroundStyle(AstaraColors.gold.opacity(0.3))
            Text(String(localized: "no_chart_data"))
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textTertiary)
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
