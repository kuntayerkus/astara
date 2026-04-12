import Foundation
import ComposableArchitecture

@DependencyClient
struct GeoService {
    var searchCities: @Sendable (_ query: String) async throws -> [GeoCity]
    var fetchTimezone: @Sendable (_ lat: Double, _ lng: Double) async throws -> String
}

extension GeoService: DependencyKey {
    static let liveValue: GeoService = {
        @Dependency(\.apiClient) var apiClient
        @Dependency(\.cacheService) var cacheService

        return GeoService(
            searchCities: { query in
                let cacheKey = "geo_\(query.lowercased())"

                // Check cache
                if let cached = await cacheService.get(cacheKey, .geoSearch),
                   let cities = try? JSONDecoder().decode([GeoCity].self, from: cached) {
                    return cities
                }

                // Fetch from VPS
                let endpoint = Endpoint(
                    path: "/api/geo",
                    queryItems: [URLQueryItem(name: "q", value: query)],
                    cachePolicy: .geoSearch,
                    isVPS: true
                )

                let data = try await apiClient.request(endpoint)
                let cities = try JSONDecoder().decode([GeoCity].self, from: data)

                // Cache the result
                await cacheService.set(cacheKey, data, .geoSearch)

                return cities
            },
            fetchTimezone: { lat, lng in
                let cacheKey = "tz_\(lat)_\(lng)"

                // Check cache
                if let cached = await cacheService.get(cacheKey, .timezone),
                   let tz = String(data: cached, encoding: .utf8) {
                    return tz
                }

                // Fetch from VPS
                let endpoint = Endpoint(
                    path: "/api/timezone",
                    queryItems: [
                        URLQueryItem(name: "lat", value: String(lat)),
                        URLQueryItem(name: "lng", value: String(lng))
                    ],
                    cachePolicy: .timezone,
                    isVPS: true
                )

                let data = try await apiClient.request(endpoint)

                // Try to decode as { "timezone": "..." } or plain string
                struct TimezoneResponse: Decodable {
                    let timezone: String
                }

                let timezone: String
                if let response = try? JSONDecoder().decode(TimezoneResponse.self, from: data) {
                    timezone = response.timezone
                } else if let plain = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) {
                    timezone = plain
                } else {
                    throw APIError.decodingError
                }

                // Validate IANA format
                guard IANATimezone.isValid(timezone) else {
                    throw APIError.decodingError
                }

                // Cache
                if let tzData = timezone.data(using: .utf8) {
                    await cacheService.set(cacheKey, tzData, .timezone)
                }

                return timezone
            }
        )
    }()

    static let previewValue = GeoService(
        searchCities: { _ in
            [
                GeoCity(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: "Europe/Istanbul"),
                GeoCity(name: "Ankara", country: "Turkey", latitude: 39.9334, longitude: 32.8597, timezone: "Europe/Istanbul"),
            ]
        },
        fetchTimezone: { _, _ in "Europe/Istanbul" }
    )
}

extension DependencyValues {
    var geoService: GeoService {
        get { self[GeoService.self] }
        set { self[GeoService.self] = newValue }
    }
}
