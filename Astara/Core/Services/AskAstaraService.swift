import Foundation
import ComposableArchitecture

@DependencyClient
struct AskAstaraService {
    var ask: @Sendable (_ question: String, _ sign: ZodiacSign, _ horoscope: DailyHoroscope?) async -> String = { _, _, _ in "" }
}

extension AskAstaraService: DependencyKey {
    static let liveValue = AskAstaraService(
        ask: { question, sign, horoscope in
            let apiKey = APIEnvironment.current.geminiAPIKey
            guard !apiKey.isEmpty, apiKey != "REPLACE_WITH_REAL_GEMINI_KEY" else {
                return Self.mockResponse(question: question, sign: sign, horoscope: horoscope)
            }

            let prompt = Self.buildPrompt(question: question, sign: sign, horoscope: horoscope)

            do {
                return try await Self.callGemini(prompt: prompt, apiKey: apiKey)
            } catch {
                return Self.mockResponse(question: question, sign: sign, horoscope: horoscope)
            }
        }
    )

    static let previewValue = AskAstaraService(
        ask: { _, _, _ in "Preview cevabı." }
    )
}

// MARK: - Private Helpers

private extension AskAstaraService {

    static func buildPrompt(question: String, sign: ZodiacSign, horoscope: DailyHoroscope?) -> String {
        let energy = horoscope?.energy ?? 50
        let theme = horoscope?.theme ?? "denge"
        let tip = horoscope?.tip ?? ""

        return """
        Sen Astara adlı bir astroloji uygulamasının yapay zeka asistanısın. \
        Samimi, biraz ironik ama kırıcı olmayan bir tonda cevap ver — sanki iyi bir arkadaşın astroloji biliyor.

        Kullanıcı bilgileri:
        - Güneş burcu: \(sign.turkishName)
        - Bugünkü enerji seviyesi: %\(energy)
        - Günün teması: \(theme)
        - Bugünkü ipucu: \(tip)

        Kullanıcının sorusu: \(question)

        Türkçe, en fazla 3 cümle, doğrudan ve samimi bir şekilde cevap ver. \
        Astroloji bilgisini somut bir tavsiyeyle birleştir. \
        "Astara olarak" veya "Ben bir yapay zekayım" gibi ifadeler kullanma.
        """
    }

    static func callGemini(prompt: String, apiKey: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 200,
                "temperature": 0.8
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Astara-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String,
              !text.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func mockResponse(question: String, sign: ZodiacSign, horoscope: DailyHoroscope?) -> String {
        let energy = horoscope?.energy ?? 50
        let theme = horoscope?.theme ?? "denge"
        let q = question.lowercased()

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

extension DependencyValues {
    var askAstaraService: AskAstaraService {
        get { self[AskAstaraService.self] }
        set { self[AskAstaraService.self] = newValue }
    }
}
