import Foundation
import ComposableArchitecture

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Endpoint

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let body: (any Encodable)?
    let cachePolicy: CachePolicy?
    let isVPS: Bool
    let isStaticData: Bool

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil,
        cachePolicy: CachePolicy? = nil,
        isVPS: Bool = false,
        isStaticData: Bool = false
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.cachePolicy = cachePolicy
        self.isVPS = isVPS
        self.isStaticData = isStaticData
    }
}

// MARK: - API Error

enum APIError: Error, Equatable {
    case networkError
    case decodingError
    case serverError(Int)
    case unauthorized
    case rateLimited
    case invalidURL

    var localizedDescription: String {
        switch self {
        case .networkError: String(localized: "error_network")
        case .decodingError: String(localized: "error_decoding")
        case .serverError(let code): String(localized: "error_server_\(code)")
        case .unauthorized: String(localized: "error_unauthorized")
        case .rateLimited: String(localized: "error_rate_limited")
        case .invalidURL: String(localized: "error_invalid_url")
        }
    }
}

// MARK: - API Client

@DependencyClient
struct APIClient {
    var request: @Sendable (_ endpoint: Endpoint) async throws -> Data
}

extension APIClient: DependencyKey {
    static let liveValue: APIClient = {
        let session = URLSession.shared
        let environment = APIEnvironment.current
        let encoder = JSONEncoder()

        return APIClient(
            request: { endpoint in
                let baseURL: URL
                if endpoint.isVPS {
                    baseURL = environment.vpsURL
                } else if endpoint.isStaticData {
                    baseURL = environment.staticDataURL
                } else {
                    baseURL = environment.baseURL
                }

                guard var components = URLComponents(
                    url: baseURL.appendingPathComponent(endpoint.path),
                    resolvingAgainstBaseURL: false
                ) else {
                    throw APIError.invalidURL
                }

                components.queryItems = endpoint.queryItems

                guard let url = components.url else {
                    throw APIError.invalidURL
                }

                var request = URLRequest(url: url)
                request.httpMethod = endpoint.method.rawValue
                request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                // Add VPS API key for VPS requests
                if endpoint.isVPS {
                    request.setValue(environment.vpsAPIKey, forHTTPHeaderField: "X-API-Key")
                }

                // Encode body if present
                if let body = endpoint.body {
                    request.httpBody = try encoder.encode(AnyEncodable(body))
                }

                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 429:
                    throw APIError.rateLimited
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
        )
    }()

    static let previewValue = APIClient(
        request: { _ in Data() }
    )
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self._encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Convenience Extension

extension APIClient {
    func decode<T: Decodable>(_ type: T.Type, from endpoint: Endpoint) async throws -> T {
        let data = try await request(endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
