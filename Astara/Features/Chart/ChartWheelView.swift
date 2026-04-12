import SwiftUI

struct ChartWheelView: View {
    let chart: BirthChart
    var onPlanetTap: ((PlanetKey) -> Void)?
    var onHouseTap: ((Int) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = size / 2 - 4
            let zodiacRingWidth: CGFloat = size * 0.12
            let innerZodiacRadius = outerRadius - zodiacRingWidth
            let houseRingWidth: CGFloat = size * 0.28
            let innerHouseRadius = innerZodiacRadius - houseRingWidth
            let planetRingRadius = innerZodiacRadius - houseRingWidth * 0.5
            let ascDegree = chart.ascendant?.degree ?? 0

            ZStack {
                // Layer 1: Zodiac ring (12 segments)
                zodiacRing(
                    center: center,
                    outerRadius: outerRadius,
                    innerRadius: innerZodiacRadius,
                    ascDegree: ascDegree,
                    size: size
                )

                // Layer 2: House cusps
                houseCusps(
                    center: center,
                    outerRadius: innerZodiacRadius,
                    innerRadius: innerHouseRadius,
                    ascDegree: ascDegree,
                    size: size
                )

                // Layer 3: Aspect lines
                aspectLines(
                    center: center,
                    radius: innerHouseRadius * 0.95,
                    ascDegree: ascDegree
                )

                // Layer 4: Planet glyphs
                planetGlyphs(
                    center: center,
                    radius: planetRingRadius,
                    ascDegree: ascDegree,
                    size: size
                )

                // Layer 5: Center glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AstaraColors.gold.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: innerHouseRadius * 0.5
                        )
                    )
                    .frame(width: innerHouseRadius, height: innerHouseRadius)
                    .position(center)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Angle Calculation

    /// ASC at 9 o'clock (left). Astrology charts go counterclockwise.
    private func canvasAngle(for eclipticDegree: Double, ascDegree: Double) -> Double {
        180.0 + ascDegree - eclipticDegree
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angleDegrees: Double) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(CGFloat(radians)),
            y: center.y - radius * sin(CGFloat(radians)) // Y flipped in SwiftUI
        )
    }

    // MARK: - Zodiac Ring

    private func zodiacRing(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, ascDegree: Double, size: CGFloat) -> some View {
        Canvas { context, _ in
            for (index, sign) in ZodiacSign.allCases.enumerated() {
                let startDeg = Double(index) * 30.0
                let endDeg = startDeg + 30.0

                let startAngle = canvasAngle(for: startDeg, ascDegree: ascDegree)
                let endAngle = canvasAngle(for: endDeg, ascDegree: ascDegree)

                // Draw segment
                var path = Path()
                path.addArc(center: center, radius: outerRadius, startAngle: .degrees(-startAngle), endAngle: .degrees(-endAngle), clockwise: true)
                path.addArc(center: center, radius: innerRadius, startAngle: .degrees(-endAngle), endAngle: .degrees(-startAngle), clockwise: false)
                path.closeSubpath()

                let elementColor = colorForElement(sign.element)
                context.fill(path, with: .color(elementColor.opacity(0.15)))
                context.stroke(path, with: .color(AstaraColors.gold.opacity(0.3)), lineWidth: 0.5)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            // Zodiac symbols
            ForEach(Array(ZodiacSign.allCases.enumerated()), id: \.element) { index, sign in
                let midDegree = Double(index) * 30.0 + 15.0
                let angle = canvasAngle(for: midDegree, ascDegree: ascDegree)
                let symbolRadius = (outerRadius + innerRadius) / 2
                let point = pointOnCircle(center: center, radius: symbolRadius, angleDegrees: angle)

                Text(sign.symbol)
                    .font(.system(size: size * 0.035))
                    .foregroundStyle(colorForElement(sign.element))
                    .position(point)
            }
        }
    }

    // MARK: - House Cusps

    private func houseCusps(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, ascDegree: Double, size: CGFloat) -> some View {
        Canvas { context, _ in
            for house in chart.houses {
                let angle = canvasAngle(for: house.degree, ascDegree: ascDegree)
                let outer = pointOnCircle(center: center, radius: outerRadius, angleDegrees: angle)
                let inner = pointOnCircle(center: center, radius: innerRadius, angleDegrees: angle)

                var line = Path()
                line.move(to: outer)
                line.addLine(to: inner)

                let isAngle = house.number == 1 || house.number == 4 || house.number == 7 || house.number == 10
                let lineWidth: CGFloat = isAngle ? 1.5 : 0.5
                let opacity: Double = isAngle ? 0.6 : 0.25

                context.stroke(line, with: .color(AstaraColors.gold.opacity(opacity)), lineWidth: lineWidth)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            // House numbers
            ForEach(chart.houses, id: \.number) { house in
                let nextHouse = chart.houses.first(where: { $0.number == (house.number % 12) + 1 })
                let nextDegree = nextHouse?.degree ?? (house.degree + 30)
                let midDegree = midpointDegree(from: house.degree, to: nextDegree)
                let angle = canvasAngle(for: midDegree, ascDegree: ascDegree)
                let labelRadius = innerRadius + (outerRadius - innerRadius) * 0.2
                let point = pointOnCircle(center: center, radius: labelRadius, angleDegrees: angle)

                Text(house.romanNumeral)
                    .font(.system(size: size * 0.025))
                    .foregroundStyle(AstaraColors.textTertiary)
                    .position(point)
            }
        }
    }

    // MARK: - Aspect Lines

    private func aspectLines(center: CGPoint, radius: CGFloat, ascDegree: Double) -> some View {
        Canvas { context, _ in
            for aspect in chart.aspects {
                guard let p1 = chart.planet(for: aspect.planet1),
                      let p2 = chart.planet(for: aspect.planet2) else { continue }

                let angle1 = canvasAngle(for: p1.degree, ascDegree: ascDegree)
                let angle2 = canvasAngle(for: p2.degree, ascDegree: ascDegree)

                let point1 = pointOnCircle(center: center, radius: radius, angleDegrees: angle1)
                let point2 = pointOnCircle(center: center, radius: radius, angleDegrees: angle2)

                var line = Path()
                line.move(to: point1)
                line.addLine(to: point2)

                let color = colorForAspect(aspect.type)
                let style = StrokeStyle(
                    lineWidth: 0.8,
                    dash: aspect.isApplying ? [4, 3] : []
                )
                context.stroke(line, with: .color(color.opacity(0.5)), style: style)
            }
        }
    }

    // MARK: - Planet Glyphs

    private func planetGlyphs(center: CGPoint, radius: CGFloat, ascDegree: Double, size: CGFloat) -> some View {
        let planets = resolveOverlaps(chart.planets, ascDegree: ascDegree)

        return ZStack {
            ForEach(planets) { planet in
                let angle = canvasAngle(for: planet.degree, ascDegree: ascDegree)
                let point = pointOnCircle(center: center, radius: radius, angleDegrees: angle)

                Button {
                    onPlanetTap?(planet.key)
                } label: {
                    VStack(spacing: 0) {
                        Text(planet.key.symbol)
                            .font(.system(size: size * 0.04, weight: .medium))
                            .foregroundStyle(planet.isRetrograde ? AstaraColors.ember400 : AstaraColors.gold)

                        if planet.isRetrograde {
                            Text("R")
                                .font(.system(size: size * 0.018, weight: .bold))
                                .foregroundStyle(AstaraColors.ember400)
                        }
                    }
                }
                .buttonStyle(.plain)
                .position(point)
            }
        }
    }

    // MARK: - Overlap Resolution

    private func resolveOverlaps(_ planets: [Planet], ascDegree: Double) -> [Planet] {
        // For now return as-is — visual overlap is acceptable at this scale.
        // Future enhancement: radially offset planets within 5° of each other.
        planets
    }

    // MARK: - Helpers

    private func midpointDegree(from start: Double, to end: Double) -> Double {
        if end >= start {
            return (start + end) / 2
        } else {
            let mid = (start + end + 360) / 2
            return mid.truncatingRemainder(dividingBy: 360)
        }
    }

    private func colorForElement(_ element: Element) -> Color {
        switch element {
        case .fire: AstaraColors.fire
        case .earth: AstaraColors.earth
        case .air: AstaraColors.air
        case .water: AstaraColors.water
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
    ZStack {
        GradientBackground()
        ChartWheelView(chart: .preview)
            .padding(24)
    }
}
