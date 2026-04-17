import Foundation
import ComposableArchitecture

// MARK: - Service

/// AI-powered natal chart interpretation.
///
/// Given a ``BirthChart``, generates a short (≤280 words) personality summary
/// in the user's locale. The result is aggressively cached per user + chart
/// signature because a natal chart never changes — interpretation is
/// effectively permanent content, hence ``CachePolicy.chartInterpretation``.
@DependencyClient
struct ChartInterpretationService {
    var interpret: @Sendable (
        _ chart: BirthChart,
        _ userId: String,
        _ locale: String
    ) async throws -> String = { _, _, _ in "" }
}

extension ChartInterpretationService: DependencyKey {
    static let liveValue: ChartInterpretationService = {
        @Dependency(\.geminiService) var geminiService

        return ChartInterpretationService(
            interpret: { chart, userId, locale in
                let prompt = Self.buildPrompt(chart: chart, locale: locale)
                let cacheKey = Self.cacheKey(userId: userId, chart: chart, locale: locale)

                // Chart interpretations are long-form — raise the token ceiling.
                let config = GeminiConfig(
                    maxOutputTokens: 500,
                    temperature: 0.7,
                    cacheKey: cacheKey,
                    cachePolicy: .chartInterpretation,
                    locale: locale
                )

                return try await geminiService.generate(prompt, config)
            }
        )
    }()

    static let previewValue = ChartInterpretationService(
        interpret: { _, _, _ in
            "Sen pisces bir Güneş ile derinden hissediyor, leo bir Ay ile büyük sahneden besleniyorsun. Yükselenin Yengeç olduğu için dışa dönük ışığın sıcak — ama sınırların dik. Bugün ritim: içine çekilmeden dışa pay ver."
        }
    )

    static let testValue = ChartInterpretationService(
        interpret: { _, _, _ in "Test chart reading." }
    )
}

// MARK: - Prompt Builder

private extension ChartInterpretationService {

    /// Build a locale-specific prompt capturing the astrological skeleton of a chart.
    /// We only include the heavyweight signals (Sun, Moon, Asc, dominant element,
    /// top 3 aspects by tightness) to keep Gemini cost predictable.
    static func buildPrompt(chart: BirthChart, locale: String) -> String {
        let sun = chart.planet(for: .gunes)
        let moon = chart.planet(for: .ay)
        let asc = chart.planet(for: .yukselen)
        let dominant = chart.elementDistribution.max(by: { $0.value < $1.value })?.key
        let topAspects = chart.aspects
            .sorted { $0.orb < $1.orb }
            .prefix(3)

        switch locale.prefix(2) {
        case "en":
            return englishPrompt(
                sun: sun,
                moon: moon,
                asc: asc,
                dominant: dominant,
                aspects: Array(topAspects)
            )
        default:
            return turkishPrompt(
                sun: sun,
                moon: moon,
                asc: asc,
                dominant: dominant,
                aspects: Array(topAspects)
            )
        }
    }

    static func turkishPrompt(
        sun: Planet?,
        moon: Planet?,
        asc: Planet?,
        dominant: Element?,
        aspects: [Aspect]
    ) -> String {
        let sunHouse = sun.map { "\(Int($0.degree / 30) + 1). ev" } ?? "—"
        let moonHouse = moon.map { "\(Int($0.degree / 30) + 1). ev" } ?? "—"

        let aspectLines = aspects.map { aspect in
            "\(aspect.planet1.turkishName) \(aspect.type.rawValue) \(aspect.planet2.turkishName) (orb \(String(format: "%.1f", aspect.orb))°)"
        }.joined(separator: ", ")

        return """
        Kullanıcının doğum haritası:
        - Güneş: \(sun?.sign.turkishName ?? "—") \(sunHouse), \(sun.map { "\(Int($0.degree))°" } ?? "—")
        - Ay: \(moon?.sign.turkishName ?? "—") \(moonHouse)
        - Yükselen: \(asc?.sign.turkishName ?? "—")
        - Baskın element: \(dominant.map { element in element.turkishName } ?? "—")
        - Öne çıkan açılar: \(aspectLines.isEmpty ? "—" : aspectLines)

        280 kelimeyi geçmeden, samimi ama profesyonel bir tonda kişilik özeti yaz.
        Astroloji jargonunu kontrollü kullan. "Ben bir AI'yim" deme.
        Türkçe yaz. Kullanıcıya "sen" diye hitap et.
        """
    }

    static func englishPrompt(
        sun: Planet?,
        moon: Planet?,
        asc: Planet?,
        dominant: Element?,
        aspects: [Aspect]
    ) -> String {
        let sunHouse = sun.map { "house \(Int($0.degree / 30) + 1)" } ?? "—"
        let moonHouse = moon.map { "house \(Int($0.degree / 30) + 1)" } ?? "—"

        let aspectLines = aspects.map { aspect in
            "\(aspect.planet1.rawValue) \(aspect.type.rawValue) \(aspect.planet2.rawValue) (orb \(String(format: "%.1f", aspect.orb))°)"
        }.joined(separator: ", ")

        return """
        User's natal chart:
        - Sun: \(sun?.sign.rawValue.capitalized ?? "—") in \(sunHouse), \(sun.map { "\(Int($0.degree))°" } ?? "—")
        - Moon: \(moon?.sign.rawValue.capitalized ?? "—") in \(moonHouse)
        - Rising: \(asc?.sign.rawValue.capitalized ?? "—")
        - Dominant element: \(dominant?.rawValue.capitalized ?? "—")
        - Notable aspects: \(aspectLines.isEmpty ? "—" : aspectLines)

        Write a personality summary under 280 words, warm but professional.
        Use astrology jargon sparingly. Never say "I am an AI".
        Address the user as "you".
        """
    }
}

// MARK: - Cache Key

private extension ChartInterpretationService {

    /// Stable per-user per-chart cache key. Chart never changes, so this is
    /// effectively permanent content. `chartSignature` guards against the
    /// extremely rare case where a user corrects their birth data.
    static func cacheKey(userId: String, chart: BirthChart, locale: String) -> String {
        "chart_interp_\(userId)_\(locale.prefix(2))_\(chartSignature(chart))"
    }

    /// Cheap structural signature: sun/moon/asc degrees rounded to 1° buckets.
    /// Enough to detect "the chart was recomputed with corrected data".
    static func chartSignature(_ chart: BirthChart) -> String {
        let sun = chart.planet(for: .gunes).map { Int($0.degree) } ?? 0
        let moon = chart.planet(for: .ay).map { Int($0.degree) } ?? 0
        let asc = chart.planet(for: .yukselen).map { Int($0.degree) } ?? 0
        return "\(sun)_\(moon)_\(asc)"
    }
}

// MARK: - Element display helpers

private extension Element {
    var turkishName: String {
        switch self {
        case .fire: "Ateş"
        case .earth: "Toprak"
        case .air: "Hava"
        case .water: "Su"
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var chartInterpretationService: ChartInterpretationService {
        get { self[ChartInterpretationService.self] }
        set { self[ChartInterpretationService.self] = newValue }
    }
}
