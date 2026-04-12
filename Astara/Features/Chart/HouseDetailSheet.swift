import SwiftUI

struct HouseDetailSheet: View {
    let chart: BirthChart
    let houseNumber: Int

    private var house: House? {
        chart.house(houseNumber)
    }

    private var planetsInHouse: [Planet] {
        chart.planets.filter { chart.houseForPlanet($0.key) == houseNumber }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.lg) {
                    if let house {
                        header(house: house)
                        detailsCard(house: house)
                    }

                    if !planetsInHouse.isEmpty {
                        planetsCard
                    }
                }
                .padding(AstaraSpacing.lg)
            }
        }
    }

    // MARK: - Header

    private func header(house: House) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            Text(house.romanNumeral)
                .font(AstaraTypography.displayLarge)
                .foregroundStyle(AstaraColors.gold)

            Text(house.meaning)
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textSecondary)
        }
    }

    // MARK: - Details

    private func detailsCard(house: House) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            detailRow(
                label: String(localized: "sign_on_cusp"),
                value: "\(house.sign.symbol) \(house.sign.turkishName)"
            )

            detailRow(
                label: String(localized: "degree"),
                value: house.formattedDegree
            )

            detailRow(
                label: String(localized: "element"),
                value: house.sign.element.localizedName
            )
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
            Spacer()
            Text(value)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
        }
    }

    // MARK: - Planets in House

    private var planetsCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "planets_in_house"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            ForEach(planetsInHouse) { planet in
                HStack {
                    Text(planet.key.symbol)
                        .font(.system(size: 20))
                        .frame(width: 28)

                    Text(planet.key.turkishName)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Spacer()

                    Text("\(planet.sign.turkishName) \(planet.formattedDegree)")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textSecondary)

                    if planet.isRetrograde {
                        Text("R")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.ember400)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }
}

#Preview {
    HouseDetailSheet(chart: .preview, houseNumber: 1)
}
