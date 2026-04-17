import Foundation
import ComposableArchitecture

/// Computes synastry between the user's chart and a partner profile.
///
/// Flow:
/// 1. Resolve partner ``BirthChart`` — either from ``PartnerDTO`` cached
///    JSON or freshly fetched via ``ChartService``. When the partner's
///    birth time is unknown we fall back to a 12:00 local "noon chart"
///    and mark the result `isSignOnlyFallback`.
/// 2. Cross-aspect grid via ``AspectCalculator.calculateCross``.
/// 3. Aspect-aware ``CompatibilityEngineClient.calculateFull`` scoring.
/// 4. Cached per (userId, partnerId) key — invalidate on partner edit.
@DependencyClient
struct SynastryService {
    var compare: @Sendable (_ userChart: BirthChart, _ partner: PartnerDTO) async throws -> Synastry
    /// Force a fresh computation even if a cached snapshot exists. Used when
    /// the user edits partner birth data.
    var invalidate: @Sendable (_ partnerId: UUID) async -> Void
}

extension SynastryService: DependencyKey {
    static let liveValue: SynastryService = {
        @Dependency(\.chartService) var chartService
        @Dependency(\.compatibilityEngine) var compatibilityEngine
        @Dependency(\.cacheService) var cacheService

        return SynastryService(
            compare: { userChart, partner in
                let cacheKey = "synastry_\(partner.id.uuidString)"

                if let cached = await cacheService.get(cacheKey, .synastry),
                   let decoded = try? JSONDecoder().decode(Synastry.self, from: cached) {
                    return decoded
                }

                let partnerChart = try await resolvePartnerChart(
                    partner: partner,
                    chartService: chartService
                )
                let isFallback = partner.birthTimeUnknown

                let crossAspects = AspectCalculator.calculateCross(
                    userPlanets: userChart.planets,
                    partnerPlanets: partnerChart.planets
                )

                let userSign = userChart.sunSign ?? partner.approximateSunSign
                let partnerSign = partnerChart.sunSign ?? partner.approximateSunSign

                let compatibility: Compatibility
                if isFallback || crossAspects.isEmpty {
                    compatibility = await compatibilityEngine.calculate(userSign, partnerSign)
                } else {
                    compatibility = await compatibilityEngine.calculateFull(
                        userSign,
                        partnerSign,
                        crossAspects
                    )
                }

                let themes = dominantThemes(from: crossAspects, isFallback: isFallback)

                let synastry = Synastry(
                    partnerId: partner.id,
                    userChart: userChart,
                    partnerChart: partnerChart,
                    crossAspects: crossAspects,
                    compatibility: compatibility,
                    dominantThemes: themes,
                    isSignOnlyFallback: isFallback
                )

                if let data = try? JSONEncoder().encode(synastry) {
                    await cacheService.set(cacheKey, data, .synastry)
                }
                return synastry
            },
            invalidate: { partnerId in
                await cacheService.invalidate("synastry_\(partnerId.uuidString)")
            }
        )
    }()

    static let previewValue = SynastryService(
        compare: { _, _ in .preview },
        invalidate: { _ in }
    )
}

extension DependencyValues {
    var synastryService: SynastryService {
        get { self[SynastryService.self] }
        set { self[SynastryService.self] = newValue }
    }
}

// MARK: - Helpers

private func resolvePartnerChart(
    partner: PartnerDTO,
    chartService: ChartService
) async throws -> BirthChart {
    // Noon fallback when the partner doesn't know their birth time —
    // mirrors the onboarding convention (see CLAUDE.md: "Saat bilmiyorum → 12:00").
    let time: Date
    if partner.birthTimeUnknown {
        time = partner.birthDate
    } else {
        time = partner.birthTime ?? partner.birthDate
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = TimeZone(identifier: partner.birthTimezone)
    let dateString = dateFormatter.string(from: partner.birthDate)

    let timeFormatter = DateFormatter()
    timeFormatter.timeZone = TimeZone(identifier: partner.birthTimezone)
    if partner.birthTimeUnknown {
        // 12:00 local
        return try await chartService.calculateChart(
            dateString,
            "12:00",
            partner.birthLatitude,
            partner.birthLongitude,
            partner.birthTimezone
        )
    } else {
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: time)
        return try await chartService.calculateChart(
            dateString,
            timeString,
            partner.birthLatitude,
            partner.birthLongitude,
            partner.birthTimezone
        )
    }
}

private func dominantThemes(from aspects: [CrossAspect], isFallback: Bool) -> [String] {
    guard !isFallback else {
        return ["Doğum saati olmadan yüzeyel eşleşme"]
    }
    var themes: [String] = []
    // Scan top 5 strongest aspects for classical synastry signatures.
    for aspect in aspects.prefix(5) {
        switch (aspect.userPlanet, aspect.partnerPlanet, aspect.type) {
        case (.gunes, .ay, _), (.ay, .gunes, _):
            themes.append("Güneş-Ay rezonansı: temel uyum güçlü")
        case (.venus, .mars, _), (.mars, .venus, _):
            if aspect.type.isHarmonious {
                themes.append("Venüs-Mars çekimi: romantik kimya")
            } else {
                themes.append("Venüs-Mars gerilimi: tutkulu ama volatil")
            }
        case (.ay, .saturn, _), (.saturn, .ay, _):
            themes.append("Ay-Satürn: duygusal sorumluluk / soğukluk teması")
        case (.merkur, .merkur, _):
            themes.append("Merkür-Merkür: iletişim ritmi \(aspect.type.isHarmonious ? "akışkan" : "zorlayıcı")")
        case (.yukselen, .yukselen, _):
            themes.append("Yükselen-Yükselen: ilk izlenim ve dış dünya uyumu")
        default: break
        }
    }
    // Deduplicate preserving order.
    var seen = Set<String>()
    return themes.filter { seen.insert($0).inserted }
}
