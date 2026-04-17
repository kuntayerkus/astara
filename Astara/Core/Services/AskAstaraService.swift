import Foundation
import CryptoKit
import ComposableArchitecture

// MARK: - Service

/// Ask Astara — the user-facing "ask me anything" chat.
///
/// This service owns prompt construction (locale-aware), delegates the actual
/// LLM call to ``GeminiService``, and falls back to a deterministic mock
/// response when the key is missing or the network fails. Caching is keyed on
/// sign + question hash + today so re-asking the same question on the same day
/// doesn't burn API budget.
@DependencyClient
struct AskAstaraService {
    var ask: @Sendable (
        _ question: String,
        _ sign: ZodiacSign,
        _ horoscope: DailyHoroscope?,
        _ chart: BirthChart?,
        _ locale: String
    ) async -> String = { _, _, _, _, _ in "" }
}

extension AskAstaraService: DependencyKey {
    static let liveValue: AskAstaraService = {
        @Dependency(\.geminiService) var geminiService

        return AskAstaraService(
            ask: { question, sign, horoscope, chart, locale in
                let sanitized = PromptSanitizer.sanitizeUserInput(question)
                guard !sanitized.isEmpty, PromptSanitizer.validateSign(sign) else {
                    return Self.mockResponse(question: question, sign: sign, horoscope: horoscope, locale: locale)
                }

                let prompt = Self.buildPrompt(
                    question: sanitized,
                    sign: sign,
                    horoscope: horoscope,
                    chart: chart,
                    locale: locale
                )

                let cacheKey = Self.cacheKey(sign: sign, question: sanitized, locale: locale)
                let config = GeminiConfig(
                    maxOutputTokens: 200,
                    temperature: 0.8,
                    cacheKey: cacheKey,
                    cachePolicy: .aiResponse,
                    locale: locale
                )

                do {
                    return try await geminiService.generate(prompt, config)
                } catch {
                    return Self.mockResponse(question: question, sign: sign, horoscope: horoscope, locale: locale)
                }
            }
        )
    }()

    static let previewValue = AskAstaraService(
        ask: { _, _, _, _, _ in "Preview cevabı." }
    )
}

// MARK: - Prompt Builder

private extension AskAstaraService {

    static func buildPrompt(
        question: String,
        sign: ZodiacSign,
        horoscope: DailyHoroscope?,
        chart: BirthChart?,
        locale: String
    ) -> String {
        let energy = horoscope?.energy ?? 50
        let theme = horoscope?.theme ?? "denge"
        let tip = horoscope?.tip ?? ""
        let chartBlock = chart.map { chartContext($0, locale: locale) } ?? ""

        switch locale.prefix(2) {
        case "en":
            return englishPrompt(question: question, sign: sign, energy: energy, theme: theme, tip: tip, chartBlock: chartBlock)
        default:
            return turkishPrompt(question: question, sign: sign, energy: energy, theme: theme, tip: tip, chartBlock: chartBlock)
        }
    }

    static func turkishPrompt(
        question: String,
        sign: ZodiacSign,
        energy: Int,
        theme: String,
        tip: String,
        chartBlock: String
    ) -> String {
        """
        Sen Astara adlı bir astroloji uygulamasının yapay zeka asistanısın. \
        Samimi, biraz ironik ama kırıcı olmayan bir tonda cevap ver — sanki iyi bir arkadaşın astroloji biliyor.

        Kullanıcının doğum haritası ve bugünkü durumu:
        - Güneş burcu: \(sign.turkishName)
        - Bugünkü enerji seviyesi: %\(energy)
        - Günün teması: \(theme)
        - Bugünkü ipucu: \(tip)
        \(chartBlock.isEmpty ? "" : "\n\(chartBlock)")
        Kullanıcının sorusu: \(question)

        Türkçe, en fazla 3 cümle, doğrudan ve samimi bir şekilde cevap ver. \
        Harita bilgilerini kullanarak kişiye özel yorum yap; genel geçer klişelerden kaçın. \
        "Astara olarak" veya "Ben bir yapay zekayım" gibi ifadeler kullanma.
        """
    }

    static func englishPrompt(
        question: String,
        sign: ZodiacSign,
        energy: Int,
        theme: String,
        tip: String,
        chartBlock: String
    ) -> String {
        """
        You are the AI assistant of an astrology app called Astara. \
        Reply in a warm, slightly witty tone — like a friend who happens to know astrology.

        User's birth chart and today's context:
        - Sun sign: \(sign.rawValue.capitalized)
        - Today's energy: \(energy)%
        - Today's theme: \(theme)
        - Today's tip: \(tip)
        \(chartBlock.isEmpty ? "" : "\n\(chartBlock)")
        User question: \(question)

        In English, 3 sentences max, direct and personal. \
        Draw on the chart data for a specific, non-generic interpretation. \
        Never say "as Astara" or "as an AI".
        """
    }

    // MARK: - Chart Context Serializer

    static func chartContext(_ chart: BirthChart, locale: String) -> String {
        let isEnglish = locale.hasPrefix("en")

        let planetLines = chart.planets
            .map { p -> String in
                let name = isEnglish ? p.key.rawValue.capitalized : p.key.turkishName
                let sign = isEnglish ? p.sign.rawValue.capitalized : p.sign.turkishName
                let retro = p.isRetrograde ? " ℞" : ""
                return "  \(name): \(sign) \(p.formattedDegree)\(retro)"
            }
            .joined(separator: "\n")

        let topAspects = chart.aspects
            .sorted { $0.orb < $1.orb }
            .prefix(5)
            .map { a -> String in
                let p1 = isEnglish ? a.planet1.rawValue.capitalized : a.planet1.turkishName
                let p2 = isEnglish ? a.planet2.rawValue.capitalized : a.planet2.turkishName
                return "  \(p1) \(a.type.symbol) \(p2) (\(String(format: "%.1f", a.orb))°)"
            }
            .joined(separator: "\n")

        if isEnglish {
            return """
            Natal chart:
            \(planetLines)
            Key aspects:
            \(topAspects.isEmpty ? "  (none)" : topAspects)
            """
        } else {
            return """
            Natal harita:
            \(planetLines)
            Öne çıkan açılar:
            \(topAspects.isEmpty ? "  (yok)" : topAspects)
            """
        }
    }
}

// MARK: - Cache Key

private extension AskAstaraService {

    /// Stable per-day cache key so the same question on the same day returns
    /// the cached answer instead of burning another Gemini call.
    static func cacheKey(sign: ZodiacSign, question: String, locale: String) -> String {
        let todayKey = Self.todayKey()
        let digest = SHA256.hash(data: Data(question.utf8))
        let hex = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        return "ask_\(sign.rawValue)_\(locale.prefix(2))_\(todayKey)_\(hex)"
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Mock Fallback

private extension AskAstaraService {

    static func mockResponse(
        question: String,
        sign: ZodiacSign,
        horoscope: DailyHoroscope?,
        locale: String
    ) -> String {
        let energy = horoscope?.energy ?? 50
        let theme = horoscope?.theme ?? "denge"
        let q = question.lowercased()

        if locale.hasPrefix("en") {
            if q.contains("love") || q.contains("relationship") || q.contains("date") {
                return "For \(sign.rawValue.capitalized), the relational tempo is high today. Holding the \(theme) thread keeps communication clean."
            }
            if q.contains("work") || q.contains("career") || q.contains("money") {
                return "Work-wise: clarity first, speed after — energy is at \(energy)%. Pick one critical task and land it."
            }
            if q.contains("today") || q.contains("should i") {
                return "Best move for \(sign.rawValue.capitalized) today: clear scattered loose ends and make one decisive call."
            }
            return "Good question. Your \(sign.rawValue.capitalized) energy is anchored in \(theme) today — focus on what matters, not what's loud."
        }

        if q.contains("aşk") || q.contains("ilişki") || q.contains("sev") {
            return "\(sign.turkishName) için bugün ilişkilerde tempo yüksek. \(theme) temasını korursan iletişim daha temiz akar."
        }
        if q.contains("iş") || q.contains("kariyer") || q.contains("para") {
            return "İş tarafında önce netlik sonra hız: enerji %\(energy). Kısa bir plan yapıp tek kritik işi bitir."
        }
        if q.contains("ne yap") || q.contains("bugün") {
            return "Bugün \(sign.turkishName) için en iyi hamle: dağınık işleri toplamak ve bir konuda net karar vermek."
        }
        return "Soru güzel. \(sign.turkishName) enerjinde bugün ana tema \(theme). Fazla değil, doğru olana odaklan."
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var askAstaraService: AskAstaraService {
        get { self[AskAstaraService.self] }
        set { self[AskAstaraService.self] = newValue }
    }
}
