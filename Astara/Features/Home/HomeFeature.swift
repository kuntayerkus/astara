import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var dailyHoroscope: DailyHoroscope?
        var elementEnergy: [Element: Int] = [:]
        var activeRetrogrades: [Retrograde] = []
        var selectedTab: Tab = .home
        var isLoading: Bool = false
        var lastUpdated: Date?
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
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadDailyData)

            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            case .loadDailyData:
                state.isLoading = true
                // MVP: Load mock data
                return .run { send in
                    try await Task.sleep(for: .milliseconds(800))
                    await send(.dailyDataLoaded(
                        .preview,
                        [.fire: 25, .earth: 35, .air: 15, .water: 25],
                        [.preview]
                    ))
                }

            case .dailyDataLoaded(let horoscope, let energy, let retrogrades):
                state.isLoading = false
                state.dailyHoroscope = horoscope
                state.elementEnergy = energy
                state.activeRetrogrades = retrogrades
                state.lastUpdated = Date()
                return .none
            }
        }
    }
}
