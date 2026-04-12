import Foundation
import ComposableArchitecture

@DependencyClient
struct ChartService {
    var calculateChart: @Sendable (
        _ date: String,
        _ time: String,
        _ lat: Double,
        _ lng: Double,
        _ timezone: String
    ) async throws -> BirthChart
}

extension ChartService: DependencyKey {
    static let liveValue: ChartService = {
        @Dependency(\.apiClient) var apiClient
        @Dependency(\.cacheService) var cacheService

        return ChartService(
            calculateChart: { date, time, lat, lng, timezone in
                // Validate IANA timezone before sending to VPS
                guard IANATimezone.isValid(timezone) else {
                    throw APIError.invalidURL
                }

                let cacheKey = "chart_\(date)_\(time)_\(lat)_\(lng)_\(timezone)"

                // Check cache (birthChart has infinite TTL)
                if let cached = await cacheService.get(cacheKey, .birthChart) {
                    if let chart = try? JSONDecoder().decode(BirthChart.self, from: cached) {
                        return chart
                    }
                }

                // Fetch from VPS
                let endpoint = Endpoint(
                    path: "/api/harita",
                    queryItems: [
                        URLQueryItem(name: "date", value: date),
                        URLQueryItem(name: "time", value: time),
                        URLQueryItem(name: "lat", value: String(lat)),
                        URLQueryItem(name: "lng", value: String(lng)),
                        URLQueryItem(name: "timezone", value: timezone)
                    ],
                    cachePolicy: .birthChart,
                    isVPS: true
                )

                let data = try await apiClient.request(endpoint)

                // Decode VPS response → map to BirthChart
                let vpsResponse: VPSChartResponse
                do {
                    vpsResponse = try JSONDecoder().decode(VPSChartResponse.self, from: data)
                } catch {
                    throw APIError.decodingError
                }

                let chart = vpsResponse.toBirthChart()

                // Cache the domain model (not raw VPS response)
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
