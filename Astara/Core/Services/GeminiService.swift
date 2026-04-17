import Foundation
import ComposableArchitecture

// MARK: - Errors

enum GeminiError: Error, LocalizedError {
    case keyMissing
    case badURL
    case badResponse(status: Int)
    case parseFailure
    case empty

    var errorDescription: String? {
        switch self {
        case .keyMissing: "Gemini API anahtarı tanımlı değil."
        case .badURL: "Gemini endpoint URL'si oluşturulamadı."
        case .badResponse(let status): "Gemini servisi \(status) döndürdü."
        case .parseFailure: "Gemini yanıtı çözümlenemedi."
        case .empty: "Gemini boş yanıt döndürdü."
        }
    }
}

// MARK: - Configuration

struct GeminiConfig: Sendable, Equatable {
    /// Upper bound for the generated response. 200 tokens ≈ 3-4 short paragraphs.
    var maxOutputTokens: Int = 200
    /// 0.0 = deterministic, 1.0 = chaotic. 0.8 is the sweet spot for Astara's voice.
    var temperature: Double = 0.8
    /// If set, ``CacheService`` is consulted before hitting the API, and the
    /// successful response is written back under this key.
    var cacheKey: String?
    /// Cache policy to use when ``cacheKey`` is provided. Defaults to ``.aiResponse`` (6h).
    var cachePolicy: CachePolicy = .aiResponse
    /// Currently informational — the prompt builder is responsible for locale.
    /// Kept on the config so future server-side locale enforcement can plug in
    /// without another signature change.
    var locale: String = "tr"

    static let `default` = GeminiConfig()
}

// MARK: - Service

/// Thin, shared Gemini client used by Ask Astara, chart interpretations, and
/// the weekly guidance AI mode.
///
/// The service is the single source of truth for:
/// - API key validation (treats `REPLACE_WITH_REAL_GEMINI_KEY` as missing)
/// - Request construction (User-Agent, timeout, JSON body shape)
/// - Response parsing (Gemini's nested `candidates[].content.parts[].text`)
/// - Optional cache integration via ``CacheService``
///
/// Fallback behaviour (mock copy, template text) is intentionally **not** part
/// of this client. Callers decide whether to degrade or bubble the error.
@DependencyClient
struct GeminiService {
    var generate: @Sendable (_ prompt: String, _ config: GeminiConfig) async throws -> String = { _, _ in "" }
}

extension GeminiService: DependencyKey {
    static let liveValue: GeminiService = {
        @Dependency(\.cacheService) var cacheService

        return GeminiService(
            generate: { prompt, config in
                let apiKey = APIEnvironment.current.geminiAPIKey
                guard !apiKey.isEmpty,
                      !apiKey.hasPrefix("YOUR_"),
                      !apiKey.contains("REPLACE_WITH") else {
                    throw GeminiError.keyMissing
                }

                // Cache hit? Return early, no network.
                if let key = config.cacheKey,
                   let cached = await cacheService.get(key, config.cachePolicy),
                   let text = String(data: cached, encoding: .utf8),
                   !text.isEmpty {
                    return text
                }

                let text = try await Self.callGemini(prompt: prompt, apiKey: apiKey, config: config)

                if let key = config.cacheKey, let data = text.data(using: .utf8) {
                    await cacheService.set(key, data, config.cachePolicy)
                }

                return text
            }
        )
    }()

    static let previewValue = GeminiService(
        generate: { _, _ in "Preview Gemini cevabı." }
    )

    static let testValue = GeminiService(
        generate: { _, _ in "Test Gemini cevabı." }
    )
}

// MARK: - Network

private extension GeminiService {

    static func callGemini(
        prompt: String,
        apiKey: String,
        config: GeminiConfig
    ) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.badURL
        }

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": config.maxOutputTokens,
                "temperature": config.temperature
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.badResponse(status: -1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw GeminiError.badResponse(status: httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.parseFailure
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GeminiError.empty
        }
        return trimmed
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var geminiService: GeminiService {
        get { self[GeminiService.self] }
        set { self[GeminiService.self] = newValue }
    }
}
