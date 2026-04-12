import SwiftUI

struct PlanetIcon: View {
    let planet: PlanetKey
    var size: CGFloat = AstaraSpacing.iconLg
    var color: Color = AstaraColors.gold

    var body: some View {
        Text(planet.symbol)
            .font(.system(size: size * 0.7))
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: AstaraSpacing.sm) {
        ForEach(PlanetKey.allCases, id: \.self) { planet in
            PlanetIcon(planet: planet, size: 32)
        }
    }
    .padding()
    .astaraBackground()
}
