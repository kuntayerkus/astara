import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var destination: Destination = .onboarding
        var onboarding: OnboardingFeature.State = .init()
        var home: HomeFeature.State = .init()
    }

    enum Destination: Equatable {
        case onboarding
        case home
    }

    enum Action: Equatable {
        case onboarding(OnboardingFeature.Action)
        case home(HomeFeature.Action)
        case checkOnboardingStatus
        case setDestination(Destination)
        case userChartLoaded(BirthChart)
        case userChartFailed
        case handleDeepLink(URL)
        case syncDeviceToken(String)
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.chartService) var chartService
    @Dependency(\.notificationService) var notificationService

    var body: some ReducerOf<Self> {
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Reduce { state, action in
            switch action {
            case .checkOnboardingStatus:
                return .run { send in
                    guard let user = await persistenceClient.loadUser(),
                          user.onboardingCompleted else {
                        await send(.setDestination(.onboarding))
                        return
                    }
                    await send(.setDestination(.home))
                    // Recalculate chart from saved birth data (hits cache if available)
                    let dateStr = AstaraDateFormatters.apiDate.string(from: user.birthDate)
                    let timeStr: String
                    if let birthTime = user.birthTime {
                        timeStr = AstaraDateFormatters.birthTime.string(from: birthTime)
                    } else {
                        timeStr = "12:00"
                    }
                    do {
                        let chart = try await chartService.calculateChart(
                            dateStr, timeStr,
                            user.birthLatitude, user.birthLongitude,
                            user.birthTimezone
                        )
                        await send(.userChartLoaded(chart))
                    } catch {
                        await send(.userChartFailed)
                    }
                }

            case .userChartLoaded(let chart):
                state.home.userChart = chart
                state.home.chart = ChartFeature.State(chart: chart)
                if let sunSign = chart.sunSign {
                    state.home.userSunSign = sunSign
                }
                return .none

            case .userChartFailed:
                return .none

            case .handleDeepLink(let url):
                guard let tab = Self.mapDeepLinkToTab(url) else {
                    return .none
                }
                state.destination = .home
                state.home.selectedTab = tab
                return .none

            case .syncDeviceToken(let token):
                return .run { _ in
                    do {
                        try await notificationService.syncDeviceToken(token)
                    } catch {
                        print("Failed to sync APNs token: \(error.localizedDescription)")
                    }
                }

            case .onboarding(.completeOnboarding):
                // Transfer chart data from onboarding to home
                if let chart = state.onboarding.chart {
                    state.home.userChart = chart
                    state.home.chart = ChartFeature.State(chart: chart)
                    if let sunSign = chart.sunSign {
                        state.home.userSunSign = sunSign
                    }
                }
                state.destination = .home
                let onboarding = state.onboarding
                return .run { _ in
                    guard let city = onboarding.selectedCity else { return }
                    let time = onboarding.birthTimeUnknown ? nil : onboarding.birthTime
                    await persistenceClient.saveUser(
                        onboarding.birthDate,
                        time,
                        onboarding.birthTimeUnknown,
                        city.name,
                        city.latitude,
                        city.longitude,
                        city.timezone
                    )
                }

            case .setDestination(let destination):
                state.destination = destination
                return .none

            case .onboarding, .home:
                return .none
            }
        }
    }
}

extension AppFeature {
    static func mapDeepLinkToTab(_ url: URL) -> HomeFeature.Tab? {
        let slug: String
        if let host = url.host, !host.isEmpty {
            slug = host.lowercased()
        } else {
            slug = url.pathComponents.dropFirst().first?.lowercased() ?? ""
        }

        switch slug {
        case AppConstants.DeepLink.chartPath:
            return .chart
        case AppConstants.DeepLink.dailyPath:
            return .daily
        case AppConstants.DeepLink.compatibilityPath:
            return .compatibility
        default:
            return nil
        }
    }
}
