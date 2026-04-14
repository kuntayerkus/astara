import Foundation
import ComposableArchitecture

@DependencyClient
struct GeoService {
    var searchCities: @Sendable (_ query: String) async throws -> [GeoCity]
    var fetchTimezone: @Sendable (_ lat: Double, _ lng: Double) async throws -> String
}

// MARK: - GeoNames API Response Models (private)

private struct GeoNamesSearchResponse: Decodable {
    let geonames: [GeoNamesCity]
}

private struct GeoNamesCity: Decodable {
    let name: String
    let countryName: String
    let lat: String
    let lng: String
    let adminName1: String?
    let timezone: GeoNamesTimezone?

    struct GeoNamesTimezone: Decodable {
        let timeZoneId: String
    }
}

extension GeoService: DependencyKey {
    static let liveValue: GeoService = {
        @Dependency(\.cacheService) var cacheService
        let session = URLSession.shared
        let environment = APIEnvironment.current

        return GeoService(
            searchCities: { query in
                let cacheKey = "geo_\(query.lowercased())"

                if let cached = await cacheService.get(cacheKey, .geoSearch),
                   let cities = try? JSONDecoder().decode([GeoCity].self, from: cached) {
                    return cities
                }

                // Direct GeoNames API call — VPS /api/geo endpoint is not available
                let username = environment.geonamesUsername.isEmpty ? "demo" : environment.geonamesUsername
                var components = URLComponents(string: "https://secure.geonames.org/searchJSON")!
                components.queryItems = [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "maxRows", value: "10"),
                    URLQueryItem(name: "style", value: "FULL"),
                    URLQueryItem(name: "featureClass", value: "P"),
                    URLQueryItem(name: "orderby", value: "population"),
                    URLQueryItem(name: "username", value: username)
                ]

                guard let url = components.url else { throw APIError.invalidURL }

                var request = URLRequest(url: url)
                request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.networkError
                }

                let geoResponse = try JSONDecoder().decode(GeoNamesSearchResponse.self, from: data)
                let cities = geoResponse.geonames.compactMap { item -> GeoCity? in
                    guard let lat = Double(item.lat), let lng = Double(item.lng) else { return nil }
                    let tz = item.timezone?.timeZoneId ?? "UTC"
                    let displayCountry = item.adminName1.map { "\($0), \(item.countryName)" } ?? item.countryName
                    return GeoCity(
                        name: item.name,
                        country: displayCountry,
                        latitude: lat,
                        longitude: lng,
                        timezone: tz
                    )
                }

                if let encoded = try? JSONEncoder().encode(cities) {
                    await cacheService.set(cacheKey, encoded, .geoSearch)
                }

                return cities
            },
            fetchTimezone: { lat, lng in
                let cacheKey = "tz_\(lat)_\(lng)"

                if let cached = await cacheService.get(cacheKey, .timezone),
                   let tz = String(data: cached, encoding: .utf8) {
                    return tz
                }

                // Primary: VPS /timezone (local TimezoneFinder, no external deps)
                // Fallback: GeoNames (when VPS key not yet configured)
                let timezone: String
                if let tz = try? await fetchTimezoneFromVPS(lat: lat, lng: lng, session: session, environment: environment) {
                    timezone = tz
                } else {
                    timezone = try await fetchTimezoneFromGeoNames(lat: lat, lng: lng, session: session, environment: environment)
                }

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

// MARK: - Timezone Fetchers

/// Primary: VPS /timezone uses local TimezoneFinder — no external dependency
private func fetchTimezoneFromVPS(
    lat: Double, lng: Double,
    session: URLSession, environment: APIEnvironment
) async throws -> String {
    guard !environment.vpsAPIKey.isEmpty else { throw APIError.unauthorized }

    var components = URLComponents(url: environment.vpsURL.appendingPathComponent("timezone"),
                                   resolvingAgainstBaseURL: false)!
    components.queryItems = [
        URLQueryItem(name: "enlem", value: String(lat)),
        URLQueryItem(name: "boylam", value: String(lng))
    ]
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue(environment.vpsAPIKey, forHTTPHeaderField: "X-API-Key")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw APIError.networkError
    }

    struct VPSTimezoneResponse: Decodable { let timezone: String }
    let result = try JSONDecoder().decode(VPSTimezoneResponse.self, from: data)
    guard IANATimezone.isValid(result.timezone) else { throw APIError.decodingError }
    return result.timezone
}

/// Fallback: GeoNames (third-party, used when VPS key not yet configured)
private func fetchTimezoneFromGeoNames(
    lat: Double, lng: Double,
    session: URLSession, environment: APIEnvironment
) async throws -> String {
    var components = URLComponents(string: "https://secure.geonames.org/timezoneJSON")!
    components.queryItems = [
        URLQueryItem(name: "lat",      value: String(lat)),
        URLQueryItem(name: "lng",      value: String(lng)),
        URLQueryItem(name: "username", value: environment.geonamesUsername.isEmpty ? "demo" : environment.geonamesUsername)
    ]
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw APIError.networkError
    }

    struct GeoNamesResponse: Decodable { let timezoneId: String }
    guard let result = try? JSONDecoder().decode(GeoNamesResponse.self, from: data),
          IANATimezone.isValid(result.timezoneId) else {
        throw APIError.decodingError
    }
    return result.timezoneId
}
