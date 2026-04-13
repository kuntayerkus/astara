import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var dailyHoroscope: DailyHoroscope?
        var elementEnergy: [Element: Int] = [:]
        var activeRetrogrades: [Retrograde] = []
        var planetPositions: [Planet] = []
        var selectedTab: Tab = .home
        var isLoading: Bool = false
        var errorMessage: String?
        var lastUpdated: Date?

        // User data (set from onboarding)
        var userSunSign: ZodiacSign = .aries
        var userChart: BirthChart?

        // Child features
        var chart: ChartFeature.State = .init()
        var daily: DailyHoroscopeFeature.State = .init()
        var compatibility: CompatibilityFeature.State = .init()
        var profile: ProfileFeature.State = .init()
    }

    enum Tab: String, CaseIterable, Equatable {
        case home, chart, daily, compatibility, profile

        var icon: String {
            switch self {
            case .home: "house.fill"
            case .chart: "circle.grid.cross.fill"
            case .daily: "sun.max.fill"
            case .compatibility: "heart.fill"
            case .profile: "person.fill"
            }
        }

        var title: String {
            switch self {
            case .home: String(localized: "tab_home")
            case .chart: String(localized: "tab_chart")
            case .daily: String(localized: "tab_daily")
            case .compatibility: String(localized: "tab_compatibility")
            case .profile: String(localized: "tab_profile")
            }
        }
    }

    enum Action: Equatable {
        case onAppear
        case selectTab(Tab)
        case loadDailyData
        case dailyDataLoaded(DailyHoroscope, [Element: Int], [Retrograde])
        case dailyDataLoadFailed
        case retryDailyData
        case loadPlanetPositions
        case planetPositionsLoaded([Planet])

        // Child features
        case chart(ChartFeature.Action)
        case daily(DailyHoroscopeFeature.Action)
        case compatibility(CompatibilityFeature.Action)
        case profile(ProfileFeature.Action)
    }

    @Dependency(\.horoscopeService) var horoscopeService

    var body: some ReducerOf<Self> {
        Scope(state: \.chart, action: \.chart) {
            ChartFeature()
        }

        Scope(state: \.daily, action: \.daily) {
            DailyHoroscopeFeature()
        }

        Scope(state: \.compatibility, action: \.compatibility) {
            CompatibilityFeature()
        }

        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadDailyData),
                    .send(.loadPlanetPositions)
                )

            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            case .retryDailyData:
                state.errorMessage = nil
                return .send(.loadDailyData)

            case .loadDailyData:
                state.isLoading = true
                state.errorMessage = nil
                let sign = state.userSunSign
                return .run { send in
                    async let horoscopes = horoscopeService.fetchDailyHoroscopes()
                    async let energy = horoscopeService.fetchDailyEnergy()
                    async let retros = horoscopeService.fetchRetroCalendar()
                    do {
                        let (h, e, r) = try await (horoscopes, energy, retros)
                        let daily = h.first(where: { $0.sign == sign }) ?? h.first
                        if let daily {
                            await send(.dailyDataLoaded(daily, e, r))
                        } else {
                            await send(.dailyDataLoadFailed)
                        }
                    } catch {
                        await send(.dailyDataLoadFailed)
                    }
                }

            case .dailyDataLoaded(let horoscope, let energy, let retrogrades):
                state.isLoading = false
                state.dailyHoroscope = horoscope
                state.elementEnergy = energy
                state.activeRetrogrades = retrogrades
                state.lastUpdated = Date()
                // Sync user's sign into child features
                state.daily.selectedSign = state.userSunSign
                state.compatibility.sign1 = state.userSunSign
                return .none

            case .dailyDataLoadFailed:
                state.isLoading = false
                state.errorMessage = String(localized: "error_load_failed")
                return .none

            case .loadPlanetPositions:
                return .run { send in
                    do {
                        let positions = try await horoscopeService.fetchPlanetPositions()
                        await send(.planetPositionsLoaded(positions))
                    } catch {
                        // Silently fail — planet positions are supplementary
                    }
                }

            case .planetPositionsLoaded(let planets):
                state.planetPositions = planets
                return .none

            case .chart:
                return .none

            case .daily:
                return .none

            case .compatibility:
                return .none

            case .profile:
                return .none
            }
        }
    }
}
