import SwiftUI

struct AspectGridView: View {
    let chart: BirthChart

    private var planets: [Planet] {
        chart.planets.filter { $0.key.isPlanet }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: AstaraSpacing.md) {
                Text(String(localized: "aspect_grid"))
                    .font(AstaraTypography.titleLarge)
                    .foregroundStyle(AstaraColors.gold)
                    .padding(.top, AstaraSpacing.lg)

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    grid
                        .padding(AstaraSpacing.md)
                }

                // Legend
                legend
                    .padding(.horizontal, AstaraSpacing.lg)
                    .padding(.bottom, AstaraSpacing.lg)
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        let cellSize: CGFloat = 30

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: cellSize, height: cellSize)

                ForEach(planets) { planet in
                    Text(planet.key.symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(AstaraColors.gold)
                        .frame(width: cellSize, height: cellSize)
                }
            }

            // Data rows (triangular grid)
            ForEach(Array(planets.enumerated()), id: \.element.id) { rowIndex, rowPlanet in
                HStack(spacing: 0) {
                    // Row header
                    Text(rowPlanet.key.symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(AstaraColors.gold)
                        .frame(width: cellSize, height: cellSize)

                    ForEach(Array(planets.enumerated()), id: \.element.id) { colIndex, colPlanet in
                        if colIndex < rowIndex {
                            // Find aspect between these two planets
                            let aspect = chart.aspects.first {
                                ($0.planet1 == rowPlanet.key && $0.planet2 == colPlanet.key) ||
                                ($0.planet1 == colPlanet.key && $0.planet2 == rowPlanet.key)
                            }

                            aspectCell(aspect: aspect, size: cellSize)
                        } else if colIndex == rowIndex {
                            // Diagonal — empty
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    Rectangle()
                                        .stroke(AstaraColors.cardBorder, lineWidth: 0.5)
                                )
                        } else {
                            // Upper triangle — empty
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func aspectCell(aspect: Aspect?, size: CGFloat) -> some View {
        ZStack {
            if let aspect {
                Rectangle()
                    .fill(colorForAspect(aspect.type).opacity(0.12))

                Text(aspect.type.symbol)
                    .font(.system(size: 11))
                    .foregroundStyle(colorForAspect(aspect.type))
            }

            Rectangle()
                .stroke(AstaraColors.cardBorder, lineWidth: 0.5)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: AstaraSpacing.md) {
            ForEach(AspectType.allCases, id: \.rawValue) { type in
                HStack(spacing: AstaraSpacing.xxs) {
                    Circle()
                        .fill(colorForAspect(type))
                        .frame(width: 8, height: 8)
                    Text(type.symbol)
                        .font(.system(size: 12))
                    Text(type.rawValue.prefix(3).capitalized)
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
            }
        }
    }

    private func colorForAspect(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: AstaraColors.gold
        case .sextile, .trine: AstaraColors.sage400
        case .square, .opposition: AstaraColors.fire
        }
    }
}

#Preview {
    AspectGridView(chart: .preview)
}
