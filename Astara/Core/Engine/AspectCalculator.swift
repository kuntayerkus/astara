import Foundation

/// Calculates aspects (angular relationships) between planets.
enum AspectCalculator {
    /// Standard orb tolerances by aspect type
    static func orb(for type: AspectType) -> Double {
        type.defaultOrb
    }

    /// Calculate the shortest angular distance between two points on the ecliptic
    static func angularDistance(_ deg1: Double, _ deg2: Double) -> Double {
        let diff = abs(deg1 - deg2).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }

    /// Detect aspect type between two degrees, if any
    static func detectAspect(_ deg1: Double, _ deg2: Double) -> AspectType? {
        let dist = angularDistance(deg1, deg2)

        for aspectType in AspectType.allCases {
            let tolerance = orb(for: aspectType)
            if abs(dist - aspectType.exactAngle) <= tolerance {
                return aspectType
            }
        }
        return nil
    }

    /// Calculate aspect strength (1.0 = exact, 0.0 = at orb edge)
    static func strength(_ deg1: Double, _ deg2: Double, type: AspectType) -> Double {
        let dist = angularDistance(deg1, deg2)
        let deviation = abs(dist - type.exactAngle)
        let maxOrb = orb(for: type)
        return max(0, 1.0 - (deviation / maxOrb))
    }
}

// MARK: - Cross-chart (synastry) aspects

extension AspectCalculator {
    /// Planet keys we consider "personal" — these dominate synastry readings.
    /// Excluding MC/Vertex keeps the grid usable when partner chart has no
    /// house data (birth time unknown). Outer planets (Saturn+) still pulled
    /// in because generational aspects can be emotionally significant.
    static let synastryRelevantPlanets: [PlanetKey] = [
        .gunes, .ay, .merkur, .venus, .mars,
        .jupiter, .saturn, .yukselen
    ]

    /// Compute every detectable aspect between a user chart's planets and a
    /// partner chart's planets. Returns only aspects inside the default orb
    /// and never self-matches (user planet ≠ partner planet key is fine —
    /// we deliberately keep e.g. user.Sun ↔ partner.Sun).
    ///
    /// - Parameters:
    ///   - userPlanets: planets from the user chart.
    ///   - partnerPlanets: planets from the partner chart.
    ///   - keys: which planet keys to include on both sides. Defaults to
    ///           ``synastryRelevantPlanets``.
    static func calculateCross(
        userPlanets: [Planet],
        partnerPlanets: [Planet],
        keys: [PlanetKey] = synastryRelevantPlanets
    ) -> [CrossAspect] {
        let keySet = Set(keys)
        let userFiltered = userPlanets.filter { keySet.contains($0.key) }
        let partnerFiltered = partnerPlanets.filter { keySet.contains($0.key) }

        var out: [CrossAspect] = []
        out.reserveCapacity(userFiltered.count * partnerFiltered.count)

        for u in userFiltered {
            for p in partnerFiltered {
                guard let type = detectAspect(u.degree, p.degree) else { continue }
                let dist = angularDistance(u.degree, p.degree)
                let orb = abs(dist - type.exactAngle)
                let strength = strength(u.degree, p.degree, type: type)
                out.append(
                    CrossAspect(
                        userPlanet: u.key,
                        partnerPlanet: p.key,
                        type: type,
                        orb: orb,
                        strength: strength
                    )
                )
            }
        }
        // Strongest first — UI can truncate for display.
        return out.sorted { $0.strength > $1.strength }
    }
}

// MARK: - AspectType extension for exact angles

extension AspectType {
    var exactAngle: Double { angle }
}
