import Foundation
import ComposableArchitecture

// date: "YYYY-MM-DD", time: "HH:mm", timezone: IANA e.g. "Europe/Istanbul"
@DependencyClient
struct ChartService {
    var calculateChart: @Sendable (_ date: String, _ time: String, _ lat: Double, _ lng: Double, _ timezone: String) async throws -> BirthChart
}

extension ChartService: DependencyKey {
    static let liveValue: ChartService = {
        @Dependency(\.cacheService) var cacheService
        @Dependency(\.astrologyEngine) var astrologyEngine

        return ChartService(
            calculateChart: { date, time, lat, lng, timezone in
                guard IANATimezone.isValid(timezone) else {
                    throw APIError.invalidURL
                }

                let cacheKey = "chart_\(date)_\(time)_\(lat)_\(lng)_\(timezone)"
                if let cached = await cacheService.get(cacheKey, .birthChart),
                   let chart = try? JSONDecoder().decode(BirthChart.self, from: cached) {
                    return chart
                }

                let params = try ChartRequestParams(date: date, time: time, lat: lat, lng: lng, timezone: timezone)

                // Primary: swiss.grio.works (owned VPS — direct, no proxy)
                // Fallback: merkurmagduru.com (same backend via proxy, no key needed)
                // Final fallback: local approximation engine (legacy-compatible low-precision model)
                let chart: BirthChart
                do {
                    let remote = try await fetchFromVPS(params: params)
                    chart = astrologyEngine.validateChart(remote)
                        ? remote
                        : try astrologyEngine.fallbackChart(date, time, lat, lng, timezone)
                } catch {
                    do {
                        let remote = try await fetchFromLegacy(params: params)
                        chart = astrologyEngine.validateChart(remote)
                            ? remote
                            : try astrologyEngine.fallbackChart(date, time, lat, lng, timezone)
                    } catch {
                        chart = try astrologyEngine.fallbackChart(date, time, lat, lng, timezone)
                    }
                }

                if let chartData = try? JSONEncoder().encode(chart) {
                    await cacheService.set(cacheKey, chartData, .birthChart)
                }

                return chart
            }
        )
    }()

    static let previewValue = ChartService(
        calculateChart: { _, _, _, _, _ in .preview }
    )
}

extension DependencyValues {
    var chartService: ChartService {
        get { self[ChartService.self] }
        set { self[ChartService.self] = newValue }
    }
}

// MARK: - Request Parameters

private struct ChartRequestParams {
    let yil: Int
    let ay: Int
    let gun: Int
    let saat: Double
    let enlem: Double
    let boylam: Double
    let timezone: String

    init(date: String, time: String, lat: Double, lng: Double, timezone: String) throws {
        let dateParts = date.split(separator: "-").compactMap { Int($0) }
        guard dateParts.count == 3 else { throw APIError.invalidURL }
        self.yil    = dateParts[0]
        self.ay     = dateParts[1]
        self.gun    = dateParts[2]

        let timeParts = time.split(separator: ":").compactMap { Double($0) }
        guard timeParts.count == 2 else { throw APIError.invalidURL }
        self.saat   = timeParts[0] + timeParts[1] / 60.0

        self.enlem    = lat
        self.boylam   = lng
        self.timezone = timezone
    }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "yil",      value: "\(yil)"),
            URLQueryItem(name: "ay",       value: "\(ay)"),
            URLQueryItem(name: "gun",      value: "\(gun)"),
            URLQueryItem(name: "saat",     value: String(format: "%.4f", saat)),
            URLQueryItem(name: "enlem",    value: String(format: "%.4f", enlem)),
            URLQueryItem(name: "boylam",   value: String(format: "%.4f", boylam)),
            URLQueryItem(name: "timezone", value: timezone)
        ]
    }
}

// MARK: - Fetchers

/// Primary: swiss.grio.works/harita (owned VPS, requires X-API-Key)
private func fetchFromVPS(params: ChartRequestParams) async throws -> BirthChart {
    let environment = APIEnvironment.current
    guard !environment.vpsAPIKey.isEmpty else { throw APIError.unauthorized }

    var components = URLComponents(url: environment.vpsURL.appendingPathComponent("harita"),
                                   resolvingAgainstBaseURL: false)!
    components.queryItems = params.queryItems
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue(environment.vpsAPIKey, forHTTPHeaderField: "X-API-Key")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw APIError.networkError
    }

    return try JSONDecoder().decode(VPSChartResponse.self, from: data).toBirthChart()
}

/// Fallback: merkurmagduru.com/api/harita (proxies same VPS, no key needed)
/// Remove this function once swiss.grio.works API key is confirmed working.
private func fetchFromLegacy(params: ChartRequestParams) async throws -> BirthChart {
    var components = URLComponents(string: "https://merkurmagduru.com/api/harita")!
    components.queryItems = params.queryItems
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw APIError.networkError
    }

    return try JSONDecoder().decode(VPSChartResponse.self, from: data).toBirthChart()
}
