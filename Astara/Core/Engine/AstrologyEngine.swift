import Foundation
import ComposableArchitecture

/// Validates and sanity-checks chart data from VPS.
/// Full Keplerian fallback calculations planned for v2.
@DependencyClient
struct AstrologyEngineClient {
    /// Validate that a BirthChart from VPS has sensible data
    var validateChart: @Sendable (BirthChart) -> Bool
    /// Get zodiac sign for a given ecliptic degree (0-360)
    var signForDegree: @Sendable (Double) -> ZodiacSign
}

extension AstrologyEngineClient: DependencyKey {
    static let liveValue = AstrologyEngineClient(
        validateChart: { chart in
            // Sanity checks:
            // 1. Must have at least the classical planets (Sun through Saturn)
            guard chart.planets.count >= 7 else { return false }
            // 2. All degrees must be 0-360
            for planet in chart.planets {
                guard (0...360).contains(planet.degree) else { return false }
            }
            // 3. Must have 12 houses
            guard chart.houses.count == 12 else { return false }
            return true
        },
        signForDegree: { degree in
            let normalized = degree.truncatingRemainder(dividingBy: 360)
            let index = Int(normalized / 30)
            return ZodiacSign.allCases[min(index, 11)]
        }
    )

    static let previewValue = AstrologyEngineClient(
        validateChart: { _ in true },
        signForDegree: { _ in .aries }
    )
}

extension DependencyValues {
    var astrologyEngine: AstrologyEngineClient {
        get { self[AstrologyEngineClient.self] }
        set { self[AstrologyEngineClient.self] = newValue }
    }
}
