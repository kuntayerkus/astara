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

// MARK: - AspectType extension for exact angles

extension AspectType {
    var exactAngle: Double { angle }
}
