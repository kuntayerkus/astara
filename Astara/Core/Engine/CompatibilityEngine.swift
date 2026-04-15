import Foundation
import ComposableArchitecture

@DependencyClient
struct CompatibilityEngineClient {
    var calculate: @Sendable (ZodiacSign, ZodiacSign) async -> Compatibility = { sign1, sign2 in
        Compatibility(sign1: sign1, sign2: sign2, overallScore: 0, loveScore: 0, friendshipScore: 0, workScore: 0, description: "")
    }
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
