import Foundation
import ComposableArchitecture

@DependencyClient
struct HoroscopeService {
    var fetchDailyHoroscopes: @Sendable () async throws -> [DailyHoroscope]
    var fetchDailyEnergy: @Sendable () async throws -> [Element: Int]
    var fetchPlanetPositions: @Sendable () async throws -> [Planet]
    var fetchRetroCalendar: @Sendable () async throws -> [Retrograde]
}

extension HoroscopeService: DependencyKey {
    static let liveValue: HoroscopeService = {
        @Dependency(\.apiClient) var apiClient
        @Dependency(\.cacheService) var cacheService

        let todayKey = AstaraDateFormatters.apiDate.string(from: Date())

        return HoroscopeService(
            fetchDailyHoroscopes: {
                let cacheKey = "daily_horoscope_\(todayKey)"

                if let cached = await cacheService.get(cacheKey, .dailyHoroscope),
                   let horoscopes = try? JSONDecoder().decode([DailyHoroscope].self, from: cached) {
                    return horoscopes
                }

                let endpoint = Endpoint(
                    path: "/data/daily-horoscope.json",
                    cachePolicy: .dailyHoroscope,
                    isStaticData: true
                )

                let data = try await apiClient.request(endpoint)
                let response = try JSONDecoder().decode(DailyHoroscopeResponse.self, from: data)
                let horoscopes = response.toDailyHoroscopes()

                if let cacheData = try? JSONEncoder().encode(horoscopes) {
                    await cacheService.set(cacheKey, cacheData, .dailyHoroscope)
                }

                return horoscopes
            },
            fetchDailyEnergy: {
                let cacheKey = "daily_energy_\(todayKey)"

                if let cached = await cacheService.get(cacheKey, .dailyEnergy),
                   let energy = try? JSONDecoder().decode(DailyEnergyResponse.self, from: cached) {
                    return energy.toElementEnergy()
                }

                let endpoint = Endpoint(
                    path: "/data/daily-energy.json",
                    cachePolicy: .dailyEnergy,
                    isStaticData: true
                )

                let data = try await apiClient.request(endpoint)
                let response = try JSONDecoder().decode(DailyEnergyResponse.self, from: data)

                await cacheService.set(cacheKey, data, .dailyEnergy)

                return response.toElementEnergy()
            },
            fetchPlanetPositions: {
                let cacheKey = "planet_positions_\(todayKey)"

                if let cached = await cacheService.get(cacheKey, .planetPositions),
                   let planets = try? JSONDecoder().decode([Planet].self, from: cached) {
                    return planets
                }

                let endpoint = Endpoint(
                    path: "/data/planet-positions.json",
                    cachePolicy: .planetPositions,
                    isStaticData: true
                )

                let data = try await apiClient.request(endpoint)
                let response = try JSONDecoder().decode(PlanetPositionsResponse.self, from: data)
                let planets = response.toPlanets()

                if let cacheData = try? JSONEncoder().encode(planets) {
                    await cacheService.set(cacheKey, cacheData, .planetPositions)
                }

                return planets
            },
            fetchRetroCalendar: {
                let cacheKey = "retro_calendar"

                if let cached = await cacheService.get(cacheKey, .retroCalendar),
                   let retros = try? JSONDecoder().decode([Retrograde].self, from: cached) {
                    return retros
                }

                let endpoint = Endpoint(
                    path: "/data/retro-calendar.json",
                    cachePolicy: .retroCalendar,
                    isStaticData: true
                )

                let data = try await apiClient.request(endpoint)
                let response = try JSONDecoder().decode(RetroCalendarResponse.self, from: data)
                let retrogrades = response.toRetrogrades()

                if let cacheData = try? JSONEncoder().encode(retrogrades) {
                    await cacheService.set(cacheKey, cacheData, .retroCalendar)
                }

                return retrogrades
            }
        )
    }()

    static let previewValue = HoroscopeService(
        fetchDailyHoroscopes: { [.preview] },
        fetchDailyEnergy: { [.fire: 25, .earth: 35, .air: 15, .water: 25] },
        fetchPlanetPositions: { BirthChart.preview.planets },
        fetchRetroCalendar: { [.preview] }
    )
}

extension DependencyValues {
    var horoscopeService: HoroscopeService {
        get { self[HoroscopeService.self] }
        set { self[HoroscopeService.self] = newValue }
    }
}
