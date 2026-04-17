import Foundation
import ComposableArchitecture

@DependencyClient
struct CompatibilityEngineClient {
    var calculate: @Sendable (ZodiacSign, ZodiacSign) async -> Compatibility = { sign1, sign2 in
        Compatibility(sign1: sign1, sign2: sign2, overallScore: 0, loveScore: 0, friendshipScore: 0, workScore: 0, description: "")
    }
    /// Full synastry-aware score. Falls back to sign-only math when
    /// `crossAspects` is empty (e.g. partner birth time unknown).
    var calculateFull: @Sendable (ZodiacSign, ZodiacSign, [CrossAspect]) async -> Compatibility = { sign1, sign2, _ in
        Compatibility(sign1: sign1, sign2: sign2, overallScore: 0, loveScore: 0, friendshipScore: 0, workScore: 0, description: "")
    }
}

extension CompatibilityEngineClient: DependencyKey {
    static let liveValue = CompatibilityEngineClient(
        calculate: { sign1, sign2 in
            CompatibilityCalculator.signOnly(sign1, sign2)
        },
        calculateFull: { sign1, sign2, aspects in
            CompatibilityCalculator.aspectAware(sign1, sign2, aspects: aspects)
        }
    )

    static let previewValue = CompatibilityEngineClient(
        calculate: { _, _ in .preview },
        calculateFull: { _, _, _ in .preview }
    )
}

extension DependencyValues {
    var compatibilityEngine: CompatibilityEngineClient {
        get { self[CompatibilityEngineClient.self] }
        set { self[CompatibilityEngineClient.self] = newValue }
    }
}

// MARK: - Calculator

private enum CompatibilityCalculator {

    // MARK: - Public facades

    /// Sign-only fallback used when no chart data is available.
    static func signOnly(_ a: ZodiacSign, _ b: ZodiacSign) -> Compatibility {
        Compatibility(
            sign1: a,
            sign2: b,
            overallScore: overallScore(a, b),
            loveScore: loveScore(a, b),
            friendshipScore: friendshipScore(a, b),
            workScore: workScore(a, b),
            description: description(a, b)
        )
    }

    /// Aspect-aware scoring. Starts from the sign-only baseline and applies
    /// deltas based on the strongest personal-planet cross-aspects.
    ///
    /// Weights follow the classical synastry priority:
    /// - Sun ↔ Moon: 30% (core ego/emotional compatibility)
    /// - Venus ↔ Mars: 25% (romantic / sexual chemistry)
    /// - Moon ↔ Moon: 15%
    /// - Asc ↔ Asc: 15%
    /// - Mercury ↔ Mercury: 15%
    ///
    /// Harmonious aspects (trine/sextile/conjunction) add up to +15 per
    /// weighted channel; hard aspects (square/opposition) subtract up to -10.
    /// Strength (exactness) scales the delta.
    static func aspectAware(
        _ a: ZodiacSign,
        _ b: ZodiacSign,
        aspects: [CrossAspect]
    ) -> Compatibility {
        let base = signOnly(a, b)
        guard !aspects.isEmpty else { return base }

        let overallDelta = synastryDelta(aspects: aspects, channel: .overall)
        let loveDelta = synastryDelta(aspects: aspects, channel: .love)
        let friendshipDelta = synastryDelta(aspects: aspects, channel: .friendship)
        let workDelta = synastryDelta(aspects: aspects, channel: .work)

        return Compatibility(
            sign1: a,
            sign2: b,
            overallScore: clamp(base.overallScore + overallDelta),
            loveScore: clamp(base.loveScore + loveDelta),
            friendshipScore: clamp(base.friendshipScore + friendshipDelta),
            workScore: clamp(base.workScore + workDelta),
            description: base.description
        )
    }

    // MARK: - Channels

    private enum SynastryChannel {
        case overall, love, friendship, work
    }

    /// Per-channel (user planet, partner planet) → weight table. Missing
    /// pairs contribute nothing to that channel.
    private static func weight(for channel: SynastryChannel, user: PlanetKey, partner: PlanetKey) -> Double {
        // Normalize so Sun↔Moon matches Moon↔Sun in the table.
        let sorted = [user, partner].sorted { $0.rawValue < $1.rawValue }
        let pair: (PlanetKey, PlanetKey) = (sorted[0], sorted[1])
        switch channel {
        case .overall:
            switch pair {
            case (.ay, .gunes): return 0.30
            case (.mars, .venus): return 0.25
            case (.ay, .ay): return 0.15
            case (.yukselen, .yukselen): return 0.15
            case (.merkur, .merkur): return 0.15
            default: return 0
            }
        case .love:
            switch pair {
            case (.mars, .venus): return 0.40
            case (.ay, .gunes): return 0.25
            case (.ay, .venus): return 0.15
            case (.gunes, .mars): return 0.10
            case (.yukselen, .yukselen): return 0.10
            default: return 0
            }
        case .friendship:
            switch pair {
            case (.ay, .ay): return 0.25
            case (.merkur, .merkur): return 0.25
            case (.jupiter, .jupiter): return 0.20
            case (.ay, .gunes): return 0.15
            case (.gunes, .jupiter), (.gunes, .gunes): return 0.15
            default: return 0
            }
        case .work:
            switch pair {
            case (.merkur, .merkur): return 0.30
            case (.mars, .saturn): return 0.20
            case (.jupiter, .saturn): return 0.20
            case (.gunes, .saturn): return 0.15
            case (.gunes, .gunes): return 0.15
            default: return 0
            }
        }
    }

    /// Raw polarity of an aspect for scoring:
    /// conjunction/trine/sextile → positive; square/opposition → negative.
    /// Conjunctions are treated as "flavor-amplifiers" (slightly less pure
    /// positive than trines) but still net positive.
    private static func polarity(_ type: AspectType) -> Double {
        switch type {
        case .trine: return 1.0
        case .sextile: return 0.8
        case .conjunction: return 0.7
        case .square: return -0.9
        case .opposition: return -0.7
        }
    }

    /// Sum weighted polarity×strength across all aspects, scaled into a
    /// signed integer delta applied on top of the sign-only baseline.
    private static func synastryDelta(aspects: [CrossAspect], channel: SynastryChannel) -> Int {
        var raw: Double = 0
        for aspect in aspects {
            let w = weight(for: channel, user: aspect.userPlanet, partner: aspect.partnerPlanet)
            guard w > 0 else { continue }
            raw += polarity(aspect.type) * aspect.strength * w
        }
        // raw is roughly in [-1, 1] after weighting. Scale into [-15, +15].
        let scaled = raw * 15
        return Int(scaled.rounded())
    }

    private static func clamp(_ value: Int) -> Int {
        max(10, min(99, value))
    }

    // MARK: - Legacy sign-only math (preserved verbatim)

    // Base compatibility matrix using element and modality
    static func overallScore(_ a: ZodiacSign, _ b: ZodiacSign) -> Int {
        let elementScore = elementCompatibility(a.element, b.element)
        let modalityScore = modalityCompatibility(a.modality, b.modality)
        let base = (elementScore * 2 + modalityScore) / 3
        // Add some sign-pair specific variance (±10)
        let variance = signPairVariance(a, b)
        return max(10, min(99, base + variance))
    }

    static func loveScore(_ a: ZodiacSign, _ b: ZodiacSign) -> Int {
        let base = overallScore(a, b)
        let waterBonus = (a.element == .water || b.element == .water) ? 5 : 0
        let fireBonus = (a.element == .fire && b.element == .air) ? 8 : 0
        return max(10, min(99, base + waterBonus + fireBonus - 3))
    }

    static func friendshipScore(_ a: ZodiacSign, _ b: ZodiacSign) -> Int {
        let base = overallScore(a, b)
        let airBonus = (a.element == .air || b.element == .air) ? 6 : 0
        return max(10, min(99, base + airBonus - 2))
    }

    static func workScore(_ a: ZodiacSign, _ b: ZodiacSign) -> Int {
        let base = overallScore(a, b)
        let earthBonus = (a.element == .earth || b.element == .earth) ? 7 : 0
        return max(10, min(99, base + earthBonus - 5))
    }

    static func description(_ a: ZodiacSign, _ b: ZodiacSign) -> String {
        let score = overallScore(a, b)
        let elementPair = "\(a.element.rawValue)-\(b.element.rawValue)"

        switch elementPair {
        case "fire-fire":
            return score > 70
                ? "İki ateş burcu. Ya dünyayı fethedeceksiniz ya da birbirinizin hayatını cehenneme çevireceksiniz. Ego savaşlarına girdiğinizde yangın söndürücünüzü yanınızda bulundurun."
                : "İkinizin de egosu bu odaya sığmaz. Evrenin hatası olan bir fırtına. Ya hemen kaçın ya da enkaz altında kalmaya hazırlanın."

        case "earth-earth":
            return "İki toprak burcu. Güvenilir, inatçı ve muhtemelen çok sıkıcı. İkiniz de haklı olduğunuzu kanıtlamaktan yorulmayacaksanız evlenebilirsiniz."

        case "air-air":
            return "İki hava burcu. Çok konuşuyorsunuz ama hiçbir şey çözmüyorsunuz. Pratik dünyayla bağlantınızı tamamen kaybedene kadar felsefe yapmaya devam edin."

        case "water-water":
            return "İki su burcu. Tebrikler, birlikte boğulmayı seçtiniz. Sürekli birbirinizin travmalarını tetikleyip bunu \"derin bir bağ\" zannedeceksiniz. Terapistleri zengin edersiniz."

        case "fire-air", "air-fire":
            return "Ateş ve hava. Biri yangın başlatır, diğeri körükler. Eğlenceli bir kaos ama rüzgar tersine döndüğünde herkes yanar."

        case "earth-water", "water-earth":
            return "Toprak ve su. Çamur oldunuz. Dünyanın en stabil, en yapışkan ve bırakması en zor bataklığı. Kurtulmak için yıllarınızı harcayabilirsiniz."

        case "fire-earth", "earth-fire":
            return "Ateş ve toprak. Biri hız ister, diğeri fren yapar. Sabrınız tükenene kadar birbirinizin sinirlerini yıpratmak için harika bir eşleşme."

        case "air-water", "water-air":
            return "Hava ve su. Mantık ve duygu çarpışması. Biri ağlarken diğeri bunu analiz edip duracak. İletişim kurduğunuzu sanıp sadece monolog yapıyorsunuz."

        default:
            return "\(a.turkishName) ve \(b.turkishName). Kozmik bir şaka. Neden hala birlikte olduğunuzu yıldızlar da bilmiyor ama acı çekmek ikinizin de seçimi."
        }
    }

    // MARK: - Helpers

    private static func elementCompatibility(_ a: Element, _ b: Element) -> Int {
        switch (a, b) {
        // Same element
        case (.fire, .fire), (.earth, .earth), (.air, .air), (.water, .water): return 80
        // Natural pairs
        case (.fire, .air), (.air, .fire): return 85
        case (.earth, .water), (.water, .earth): return 82
        // Challenging
        case (.fire, .water), (.water, .fire): return 40
        case (.earth, .air), (.air, .earth): return 45
        // Neutral
        default: return 60
        }
    }

    private static func modalityCompatibility(_ a: Modality, _ b: Modality) -> Int {
        switch (a, b) {
        case (.cardinal, .fixed): return 72
        case (.fixed, .cardinal): return 72
        case (.cardinal, .mutable): return 68
        case (.mutable, .cardinal): return 68
        case (.fixed, .mutable): return 65
        case (.mutable, .fixed): return 65
        case (.cardinal, .cardinal): return 58
        case (.fixed, .fixed): return 55
        case (.mutable, .mutable): return 78
        default: return 65
        }
    }

    private static func signPairVariance(_ a: ZodiacSign, _ b: ZodiacSign) -> Int {
        // Deterministic variance based on sign indices so same pair always yields same result
        let i1 = ZodiacSign.allCases.firstIndex(of: a) ?? 0
        let i2 = ZodiacSign.allCases.firstIndex(of: b) ?? 0
        let seed = (i1 * 12 + i2) % 21
        return seed - 10 // -10...10
    }
}
