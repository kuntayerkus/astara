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

    @Dependency(\.userDefaults) var userDefaults

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
                let completed = userDefaults.bool("onboarding_completed")
                state.destination = completed ? .home : .onboarding
                return .none

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
                return .run { _ in
                    await userDefaults.setBool(true, forKey: "onboarding_completed")
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

// MARK: - UserDefaults Dependency

struct UserDefaultsClient {
    var bool: @Sendable (String) -> Bool
    var setBool: @Sendable (Bool, String) async -> Void
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        bool: { key in
            UserDefaults.standard.bool(forKey: key)
        },
        setBool: { value, key in
            UserDefaults.standard.set(value, forKey: key)
        }
    )

    static let previewValue = UserDefaultsClient(
        bool: { _ in false },
        setBool: { _, _ in }
    )
}

extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
