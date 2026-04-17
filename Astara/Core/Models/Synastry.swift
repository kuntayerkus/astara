import Foundation

/// Result of a synastry comparison between the user's chart and a partner chart.
///
/// Two axes of fidelity:
/// 1. **Full synastry** — both charts have trustworthy birth times; cross-aspect
///    grid is populated and the compatibility score factors those aspects in.
/// 2. **Sign-only fallback** — partner birth time is unknown; we fall back to
///    the legacy sun-sign pair scoring and surface `isSignOnlyFallback = true`
///    so the UI can warn the user.
struct Synastry: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let partnerId: UUID
    let userChart: BirthChart
    let partnerChart: BirthChart
    let crossAspects: [CrossAspect]
    let compatibility: Compatibility
    let dominantThemes: [String]
    let isSignOnlyFallback: Bool
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        partnerId: UUID,
        userChart: BirthChart,
        partnerChart: BirthChart,
        crossAspects: [CrossAspect],
        compatibility: Compatibility,
        dominantThemes: [String],
        isSignOnlyFallback: Bool,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.partnerId = partnerId
        self.userChart = userChart
        self.partnerChart = partnerChart
        self.crossAspects = crossAspects
        self.compatibility = compatibility
        self.dominantThemes = dominantThemes
        self.isSignOnlyFallback = isSignOnlyFallback
        self.generatedAt = generatedAt
    }
}

/// A single cross-chart aspect. `userPlanet` always belongs to the user chart,
/// `partnerPlanet` to the partner chart — order matters for rendering labels.
struct CrossAspect: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let userPlanet: PlanetKey
    let partnerPlanet: PlanetKey
    let type: AspectType
    /// Exactness deviation in degrees (0 = perfectly exact).
    let orb: Double
    /// Normalized 0...1 strength (1 = exact, 0 = at orb edge).
    let strength: Double

    init(
        id: UUID = UUID(),
        userPlanet: PlanetKey,
        partnerPlanet: PlanetKey,
        type: AspectType,
        orb: Double,
        strength: Double
    ) {
        self.id = id
        self.userPlanet = userPlanet
        self.partnerPlanet = partnerPlanet
        self.type = type
        self.orb = orb
        self.strength = strength
    }
}

// MARK: - Preview Data

extension Synastry {
    static let preview = Synastry(
        partnerId: UUID(),
        userChart: .preview,
        partnerChart: .preview,
        crossAspects: [
            CrossAspect(userPlanet: .gunes, partnerPlanet: .ay, type: .trine, orb: 1.2, strength: 0.85),
            CrossAspect(userPlanet: .venus, partnerPlanet: .mars, type: .sextile, orb: 2.4, strength: 0.6),
            CrossAspect(userPlanet: .ay, partnerPlanet: .saturn, type: .square, orb: 3.1, strength: 0.55)
        ],
        compatibility: .preview,
        dominantThemes: ["Duygusal rezonans", "Yaratıcı çekim"],
        isSignOnlyFallback: false
    )
}
