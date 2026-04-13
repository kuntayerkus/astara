import Foundation

/// Determines zodiac sign on each house cusp and which house a planet falls in.
/// Full Placidus house system calculation is planned for v2 (requires complex spherical trig).
/// MVP relies on VPS for house cusps.
enum HouseCalculator {
    /// Determine which zodiac sign is on a house cusp given its degree
    static func signOnCusp(degree: Double) -> ZodiacSign {
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let index = Int(normalized / 30)
        return ZodiacSign.allCases[min(index, 11)]
    }

    /// Determine which house a planet falls in, given sorted house cusp degrees
    static func houseForPlanet(planetDegree: Double, houseCusps: [Double]) -> Int {
        guard houseCusps.count == 12 else { return 1 }

        let deg = planetDegree.truncatingRemainder(dividingBy: 360)

        for i in 0..<12 {
            let cusp = houseCusps[i]
            let nextCusp = houseCusps[(i + 1) % 12]

            if nextCusp > cusp {
                // Normal case: cusp doesn't wrap around 360°
                if deg >= cusp && deg < nextCusp {
                    return i + 1
                }
            } else {
                // Wrap-around case (e.g., cusp at 350°, next at 20°)
                if deg >= cusp || deg < nextCusp {
                    return i + 1
                }
            }
        }

        return 1
    }

    /// Degree within sign (0-30)
    static func degreeInSign(_ degree: Double) -> Double {
        degree.truncatingRemainder(dividingBy: 30)
    }

    /// Format degree as "15° 23' Koç" style
    static func formatDegree(_ degree: Double) -> String {
        let sign = signOnCusp(degree: degree)
        let inSign = degreeInSign(degree)
        let deg = Int(inSign)
        let min = Int((inSign - Double(deg)) * 60)
        return "\(deg)° \(min)' \(sign.turkishName)"
    }
}
