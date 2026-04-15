import SwiftUI

// MARK: - Solar Fire-Style Natal Chart Wheel

struct ChartWheelView: View {
    let chart: BirthChart
    var onPlanetTap: ((PlanetKey) -> Void)?
    var onHouseTap: ((Int) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerR = size / 2 - 2
            let zodiacWidth: CGFloat = size * 0.1
            let zodiacInnerR = outerR - zodiacWidth
            let planetRingR = zodiacInnerR - size * 0.06
            let houseInnerR = zodiacInnerR - size * 0.22
            let aspectR = houseInnerR - 2
            let ascDeg = chart.ascendant?.degree ?? 0

            ZStack {
                // 1: Outer border circle
                Circle()
                    .stroke(AstaraColors.gold.opacity(0.4), lineWidth: 1.5)
                    .shadow(color: AstaraColors.goldGlow, radius: 8)
                    .frame(width: outerR * 2, height: outerR * 2)
                    .position(center)

                // 2: Zodiac ring (12 colored segments + symbols + tick marks)
                zodiacRing(center: center, outerR: outerR, innerR: zodiacInnerR, ascDeg: ascDeg, size: size)

                // 3: Inner zodiac border
                Circle()
                    .stroke(AstaraColors.gold.opacity(0.35), lineWidth: 1)
                    .frame(width: zodiacInnerR * 2, height: zodiacInnerR * 2)
                    .position(center)

                // 4: House cusps (lines from zodiac inner to house inner)
                houseCusps(center: center, outerR: zodiacInnerR, innerR: houseInnerR, ascDeg: ascDeg, size: size)

                // 5: Inner circle border
                Circle()
                    .stroke(AstaraColors.gold.opacity(0.25), lineWidth: 1)
                    .frame(width: houseInnerR * 2, height: houseInnerR * 2)
                    .position(center)

                // 6: Aspect web (inside the inner circle)
                aspectLines(center: center, radius: aspectR, ascDeg: ascDeg)

                // 7: Center aura
                RadialGradient(
                    colors: [
                        AstaraColors.goldGlow.opacity(0.25),
                        AstaraColors.amethyst.opacity(0.1),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: houseInnerR * 0.7
                )
                .frame(width: houseInnerR, height: houseInnerR)
                .position(center)

                // 8: Planet glyphs (between zodiac inner and house inner)
                planetGlyphs(center: center, ringOuter: zodiacInnerR, ringInner: houseInnerR, ascDeg: ascDeg, size: size)

                // 9: House numbers (inside house ring)
                houseNumbers(center: center, radius: houseInnerR + (zodiacInnerR - houseInnerR) * 0.15, ascDeg: ascDeg, size: size)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Angle Helpers

    /// Converts ecliptic longitude to canvas angle.
    /// ASC sits at 9 o'clock (180°). Zodiac advances counterclockwise.
    /// MC lands at 12 o'clock (90°), IC at 6 o'clock (270°), DSC at 3 o'clock (0°).
    private func canvasAngle(for eclipticDeg: Double, ascDeg: Double) -> Double {
        eclipticDeg - ascDeg + 180.0
    }

    private func point(center: CGPoint, radius: CGFloat, angleDeg: Double) -> CGPoint {
        let rad = angleDeg * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(CGFloat(rad)),
            y: center.y - radius * sin(CGFloat(rad))
        )
    }

    // MARK: - Zodiac Ring

    private func zodiacRing(center: CGPoint, outerR: CGFloat, innerR: CGFloat, ascDeg: Double, size: CGFloat) -> some View {
        Canvas { ctx, _ in
            let tickR = outerR - (outerR - innerR) * 0.25

            for (i, sign) in ZodiacSign.allCases.enumerated() {
                let startEcl = Double(i) * 30.0
                let endEcl = startEcl + 30.0
                let startA = canvasAngle(for: startEcl, ascDeg: ascDeg)
                let endA = canvasAngle(for: endEcl, ascDeg: ascDeg)

                // Filled segment
                var seg = Path()
                seg.addArc(center: center, radius: outerR, startAngle: .degrees(-startA), endAngle: .degrees(-endA), clockwise: false)
                seg.addArc(center: center, radius: innerR, startAngle: .degrees(-endA), endAngle: .degrees(-startA), clockwise: true)
                seg.closeSubpath()

                let elemColor = elementColor(sign.element)
                
                // Antik pusula hissi için element renklerini çok kıstık, altını öne çıkardık
                ctx.fill(seg, with: .color(elemColor.opacity(0.04)))
                ctx.stroke(seg, with: .color(AstaraColors.gold.opacity(0.35)), lineWidth: 0.8)

                // 5° tick marks inside the zodiac ring
                for tick in stride(from: startEcl, to: endEcl, by: 5) {
                    let a = canvasAngle(for: tick, ascDeg: ascDeg)
                    let isMain = Int(tick) % 10 == 0
                    let from = point(center: center, radius: outerR, angleDeg: a)
                    let to = point(center: center, radius: isMain ? tickR : tickR + (outerR - tickR) * 0.4, angleDeg: a)
                    var line = Path()
                    line.move(to: from)
                    line.addLine(to: to)
                    ctx.stroke(line, with: .color(AstaraColors.gold.opacity(isMain ? 0.3 : 0.15)), lineWidth: 0.5)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay {
            // Zodiac symbols centered in each segment
            ForEach(Array(ZodiacSign.allCases.enumerated()), id: \.element) { i, sign in
                let midEcl = Double(i) * 30.0 + 15.0
                let a = canvasAngle(for: midEcl, ascDeg: ascDeg)
                let symR = (outerR + innerR) / 2
                let pt = point(center: center, radius: symR, angleDeg: a)

                Text(sign.symbol)
                    .font(.system(size: size * 0.038, weight: .light))
                    .foregroundStyle(AstaraColors.gold.opacity(0.85)) // Altın yansıma
                    .shadow(color: AstaraColors.goldGlow, radius: 2)
                    .position(pt)
            }
        }
    }

    // MARK: - House Cusps

    private func houseCusps(center: CGPoint, outerR: CGFloat, innerR: CGFloat, ascDeg: Double, size: CGFloat) -> some View {
        Canvas { ctx, _ in
            for house in chart.houses {
                let a = canvasAngle(for: house.degree, ascDeg: ascDeg)
                let outerPt = point(center: center, radius: outerR, angleDeg: a)
                let innerPt = point(center: center, radius: innerR, angleDeg: a)

                var line = Path()
                line.move(to: outerPt)
                line.addLine(to: innerPt)

                let isAngular = house.number == 1 || house.number == 4 || house.number == 7 || house.number == 10
                let lw: CGFloat = isAngular ? 1.5 : 0.5
                let opacity: Double = isAngular ? 0.6 : 0.2
                ctx.stroke(line, with: .color(AstaraColors.gold.opacity(opacity)), lineWidth: lw)

                // Derece etiketleri (veri tablosu görünümü yaratmaması için) kaldırıldı.
                // Sadece mistik çizgiler kaldı.
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - House Numbers

    private func houseNumbers(center: CGPoint, radius: CGFloat, ascDeg: Double, size: CGFloat) -> some View {
        ForEach(chart.houses, id: \.number) { house in
            let nextHouse = chart.houses.first { $0.number == (house.number % 12) + 1 }
            let nextDeg = nextHouse?.degree ?? (house.degree + 30)
            let midDeg = midpoint(from: house.degree, to: nextDeg)
            let a = canvasAngle(for: midDeg, ascDeg: ascDeg)
            let pt = point(center: center, radius: radius, angleDeg: a)

            Text(house.romanNumeral)
                .font(AstaraTypography.labelLarge) // Daha şık, editöryal Roman rakamları
                .foregroundStyle(AstaraColors.gold.opacity(0.5))
                .shadow(color: AstaraColors.goldGlow, radius: 1)
                .position(pt)
        }
    }

    // MARK: - Aspect Lines

    private func aspectLines(center: CGPoint, radius: CGFloat, ascDeg: Double) -> some View {
        Canvas { ctx, _ in
            for aspect in chart.aspects {
                guard let p1 = chart.planet(for: aspect.planet1),
                      let p2 = chart.planet(for: aspect.planet2) else { continue }

                let a1 = canvasAngle(for: p1.degree, ascDeg: ascDeg)
                let a2 = canvasAngle(for: p2.degree, ascDeg: ascDeg)
                let pt1 = point(center: center, radius: radius, angleDeg: a1)
                let pt2 = point(center: center, radius: radius, angleDeg: a2)

                var line = Path()
                line.move(to: pt1)
                line.addLine(to: pt2)

                let color = aspectColor(aspect.type)
                let strength = max(0.2, 1.0 - aspect.orb / aspect.type.defaultOrb)
                let style = StrokeStyle(
                    lineWidth: aspect.type.isHarmonious ? 0.8 : 1.0,
                    dash: aspect.type == .opposition ? [4, 3] : (aspect.type == .square ? [2, 2] : [])
                )
                ctx.stroke(line, with: .color(color.opacity(strength * 0.6)), style: style)
            }
        }
    }

    // MARK: - Planet Glyphs

    private func planetGlyphs(center: CGPoint, ringOuter: CGFloat, ringInner: CGFloat, ascDeg: Double, size: CGFloat) -> some View {
        let planets = spreadPlanets(chart.planets, ascDeg: ascDeg)
        let defaultR = ringOuter - (ringOuter - ringInner) * 0.45

        return ZStack {
            ForEach(planets) { entry in
                let a = canvasAngle(for: entry.displayDegree, ascDeg: ascDeg)
                let r = entry.isOffset ? defaultR - size * 0.04 : defaultR
                let pt = point(center: center, radius: r, angleDeg: a)

                // Thin line from actual position on zodiac ring to glyph
                let actualA = canvasAngle(for: entry.planet.degree, ascDeg: ascDeg)
                let zodiacPt = point(center: center, radius: ringOuter - 1, angleDeg: actualA)
                let glyphEdgePt = point(center: center, radius: r + size * 0.015, angleDeg: a)

                Canvas { ctx, _ in
                    var tick = Path()
                    tick.move(to: zodiacPt)
                    tick.addLine(to: glyphEdgePt)
                    ctx.stroke(tick, with: .color(AstaraColors.gold.opacity(0.15)), lineWidth: 0.5)
                }
                .frame(width: size, height: size)
                .allowsHitTesting(false)

                Button {
                    onPlanetTap?(entry.planet.key)
                } label: {
                    VStack(spacing: 0) {
                        Text(entry.planet.key.symbol)
                            .font(.system(size: size * 0.038, weight: .light))
                            .foregroundStyle(planetColor(entry.planet))
                            .shadow(color: planetColor(entry.planet).opacity(0.5), radius: 3)
                        
                        // Veri tablosu görünümünü engellemek için planet dereceleri (shortDegree) listeden okunacak şekilde çemberden kaldırıldı.
                    }
                }
                .buttonStyle(.plain)
                .position(pt)
            }
        }
    }

    // MARK: - Planet Spread (avoid overlaps)

    private struct SpreadEntry: Identifiable {
        var id: String { planet.id }
        let planet: Planet
        let displayDegree: Double
        let isOffset: Bool
    }

    private func spreadPlanets(_ planets: [Planet], ascDeg: Double) -> [SpreadEntry] {
        let sorted = planets.sorted { $0.degree < $1.degree }
        let minGap: Double = 8.0
        var entries: [SpreadEntry] = []

        for planet in sorted {
            var displayDeg = planet.degree
            var isOffset = false

            for existing in entries {
                let dist = abs(displayDeg - existing.displayDegree)
                let shortDist = min(dist, 360 - dist)
                if shortDist < minGap {
                    displayDeg = existing.displayDegree + minGap
                    if displayDeg >= 360 { displayDeg -= 360 }
                    isOffset = true
                }
            }

            entries.append(SpreadEntry(planet: planet, displayDegree: displayDeg, isOffset: isOffset))
        }

        return entries
    }

    // MARK: - Helpers

    private func midpoint(from start: Double, to end: Double) -> Double {
        if end >= start {
            return (start + end) / 2
        }
        let mid = (start + end + 360) / 2
        return mid.truncatingRemainder(dividingBy: 360)
    }

    private func shortDegree(_ planet: Planet) -> String {
        let deg = Int(planet.degree) % 30
        let retro = planet.isRetrograde ? "r" : ""
        return "\(deg)°\(retro)"
    }

    private func planetColor(_ planet: Planet) -> Color {
        if planet.isRetrograde {
            return AstaraColors.ember400
        }
        switch planet.key {
        case .gunes: return AstaraColors.gold
        case .ay: return AstaraColors.mist400
        case .merkur: return Color(hex: "#A8D8EA")
        case .venus: return AstaraColors.sage400
        case .mars: return AstaraColors.fire
        case .jupiter: return Color(hex: "#C9A96E")
        case .saturn: return Color(hex: "#8B7340")
        case .uranus: return AstaraColors.air
        case .neptun: return AstaraColors.water
        case .pluton: return Color(hex: "#9B59B6")
        case .yukselen: return AstaraColors.gold
        case .mc: return AstaraColors.goldLight
        case .vertex: return AstaraColors.textTertiary
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

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: AstaraColors.gold
        case .sextile: AstaraColors.sage400
        case .trine: AstaraColors.air
        case .square: AstaraColors.fire
        case .opposition: AstaraColors.ember400
        }
    }
}

#Preview {
    ZStack {
        GradientBackground(ambient: .chart)
        ChartWheelView(chart: .preview)
            .padding(16)
    }
}
