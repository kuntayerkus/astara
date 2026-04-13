import Foundation
import ComposableArchitecture

@DependencyClient
struct CompatibilityEngineClient {
    var calculate: @Sendable (ZodiacSign, ZodiacSign) async -> Compatibility
}

extension CompatibilityEngineClient: DependencyKey {
    static let liveValue = CompatibilityEngineClient(
        calculate: { sign1, sign2 in
            let overall = CompatibilityCalculator.overallScore(sign1, sign2)
            let love = CompatibilityCalculator.loveScore(sign1, sign2)
            let friendship = CompatibilityCalculator.friendshipScore(sign1, sign2)
            let work = CompatibilityCalculator.workScore(sign1, sign2)
            let desc = CompatibilityCalculator.description(sign1, sign2)

            return Compatibility(
                sign1: sign1,
                sign2: sign2,
                overallScore: overall,
                loveScore: love,
                friendshipScore: friendship,
                workScore: work,
                description: desc
            )
        }
    )

    static let previewValue = CompatibilityEngineClient(
        calculate: { _, _ in .preview }
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
                ? "İki ateş burcu — tutkulu ve enerjik. Kıvılcımlar uçuşabilir, ama alevler de yakabilir. Enerjiyi doğru kanalize edin."
                : "İkisi de güçlü — egolar çarpışabilir. Birbirinize alan tanıyın."

        case "earth-earth":
            return "İki toprak burcu — istikrarlı ve güvenilir. Uzun vadeli bağlar için güçlü zemin. Değişime birlikte açık olun."

        case "air-air":
            return "İki hava burcu — zihinsel uyum üst düzey. Konuşmalarınız bitmez, fikirler uçuşur. Derinliği ihmal etmeyin."

        case "water-water":
            return "İki su burcu — derin duygusal bağ. Sezgisel anlayış kusursuz. Sınır çizmeyi öğrenin."

        case "fire-air", "air-fire":
            return "Ateş ve hava — birbirini besleyen güç. Hava, ateşi büyütür; ateş, havaya yön verir. Dinamik ve ilham verici bağ."

        case "earth-water", "water-earth":
            return "Toprak ve su — birbirini besleyen denge. Su toprağı besler, toprak suya yön verir. Besleme ve güven ön planda."

        case "fire-earth", "earth-fire":
            return "Ateş ve toprak — hız farkı olabilir. Ateş hızlı, toprak temkinli. Ortak ritim bulunursa sağlam ilerlenir."

        case "air-water", "water-air":
            return "Hava ve su — akıl ile duygu arası denge. Hava analiz eder, su hisseder. Birbirini anlama çabası gerektirir."

        default:
            return "\(a.turkishName) ve \(b.turkishName) — farklı enerjiler, ortak yolculuk. Farkları gücünüze çevirin."
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
