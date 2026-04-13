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
    }

    @Dependency(\.persistenceClient) var persistenceClient

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
                    if let user = await persistenceClient.loadUser(), user.onboardingCompleted {
                        await send(.setDestination(.home))
                    } else {
                        await send(.setDestination(.onboarding))
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
                // Persist user data via SwiftData
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

