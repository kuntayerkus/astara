import SwiftUI

struct PlanetPositionsView: View {
    let planets: [Planet]

    var body: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "current_sky"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AstaraSpacing.sm) {
                    ForEach(planets.filter { $0.key.isPlanet }) { planet in
                        planetCard(planet: planet)
                    }
                }
            }
        }
    }

    private func planetCard(planet: Planet) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            Text(planet.key.symbol)
                .font(.system(size: 22))
                .foregroundStyle(planet.isRetrograde ? AstaraColors.ember400 : AstaraColors.gold)

            Text(planet.sign.symbol)
                .font(.system(size: 16))

            Text(planet.formattedDegree)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)

            if planet.isRetrograde {
                Text("R")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AstaraColors.ember400)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(AstaraColors.ember400.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .frame(width: 64)
        .padding(.vertical, AstaraSpacing.sm)
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        PlanetPositionsView(planets: BirthChart.preview.planets)
            .padding()
    }
}
