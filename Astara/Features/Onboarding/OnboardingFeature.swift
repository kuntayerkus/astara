import Foundation
import ComposableArchitecture

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable, Equatable {
    case splash
    case intro
    case birthDate
    case birthTime
    case birthCity
    case loading
    case chartReveal
    case summary
    case pushPermission
}

// MARK: - Onboarding Feature

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: OnboardingStep = .splash
        var introSlideIndex: Int = 0

        // Birth data
        var birthDate: Date = Calendar.current.date(
            from: DateComponents(year: 1995, month: 1, day: 1)
        ) ?? Date()
        var birthTime: Date = Calendar.current.date(
            from: DateComponents(hour: 12, minute: 0)
        ) ?? Date()
        var birthTimeUnknown: Bool = false

        // City search
        var searchQuery: String = ""
        var searchResults: [GeoCity] = []
        var selectedCity: GeoCity?
        var isSearching: Bool = false
        var searchError: String?

        // Chart
        var chart: BirthChart?
        var isLoading: Bool = false
        var chartError: String?
    }

    enum Action: Equatable {
        case splashTimerFired
        case nextStep
        case previousStep
        case setIntroSlide(Int)

        // Birth data
        case setBirthDate(Date)
        case setBirthTime(Date)
        case toggleBirthTimeUnknown

        // City search
        case setSearchQuery(String)
        case searchCities
        case searchCitiesResponse([GeoCity])
        case searchCitiesFailed
        case selectCity(GeoCity)

        // Chart
        case calculateChart
        case chartCalculated(BirthChart)
        case chartCalculationFailed(String)

        // Push
        case requestPushPermission
        case pushPermissionResult(Bool)

        // Completion
        case completeOnboarding
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.geoService) var geoService
    @Dependency(\.chartService) var chartService
    @Dependency(\.notificationService) var notificationService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .splashTimerFired:
                state.currentStep = .intro
                return .none

            case .nextStep:
                guard let nextIndex = OnboardingStep.allCases.firstIndex(of: state.currentStep),
                      nextIndex + 1 < OnboardingStep.allCases.count else { return .none }
                let next = OnboardingStep.allCases[nextIndex + 1]

                // Skip loading/chartReveal transition — handled by calculateChart
                if next == .loading {
                    state.currentStep = .loading
                    return .send(.calculateChart)
                }

                state.currentStep = next
                return .none

            case .previousStep:
                guard let currentIndex = OnboardingStep.allCases.firstIndex(of: state.currentStep),
                      currentIndex > 0 else { return .none }
                state.currentStep = OnboardingStep.allCases[currentIndex - 1]
                return .none

            case .setIntroSlide(let index):
                state.introSlideIndex = index
                return .none

            case .setBirthDate(let date):
                state.birthDate = date
                return .none

            case .setBirthTime(let time):
                state.birthTime = time
                return .none

            case .toggleBirthTimeUnknown:
                state.birthTimeUnknown.toggle()
                if state.birthTimeUnknown {
                    state.birthTime = Calendar.current.date(
                        from: DateComponents(hour: 12, minute: 0)
                    ) ?? Date()
                }
                return .none

            case .setSearchQuery(let query):
                state.searchQuery = query
                state.selectedCity = nil
                state.searchError = nil
                guard query.count >= 2 else {
                    state.searchResults = []
                    return .none
                }
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchCities)
                }

            case .searchCities:
                state.isSearching = true
                state.searchError = nil
                let query = state.searchQuery
                return .run { send in
                    do {
                        let cities = try await geoService.searchCities(query)
                        await send(.searchCitiesResponse(cities))
                    } catch {
                        await send(.searchCitiesFailed)
                    }
                }

            case .searchCitiesResponse(let cities):
                state.isSearching = false
                state.searchResults = cities
                return .none

            case .searchCitiesFailed:
                state.isSearching = false
                state.searchResults = []
                state.searchError = String(localized: "search_error")
                return .none

            case .selectCity(let city):
                state.selectedCity = city
                state.searchQuery = city.name
                state.searchResults = []
                state.searchError = nil
                return .none

            case .calculateChart:
                state.isLoading = true
                state.chartError = nil
                guard let city = state.selectedCity else { return .none }
                let dateStr = AstaraDateFormatters.apiDate.string(from: state.birthDate)
                let timeStr = AstaraDateFormatters.birthTime.string(from: state.birthTime)
                let timezone = city.timezone
                let lat = city.latitude
                let lng = city.longitude
                return .run { send in
                    do {
                        let chart = try await chartService.calculateChart(
                            dateStr, timeStr, lat, lng, timezone
                        )
                        await send(.chartCalculated(chart))
                    } catch {
                        await send(.chartCalculationFailed(
                            error.localizedDescription
                        ))
                    }
                }

            case .chartCalculated(let chart):
                state.isLoading = false
                state.chartError = nil
                state.chart = chart
                state.currentStep = .chartReveal
                return .none

            case .chartCalculationFailed(let message):
                state.isLoading = false
                state.chartError = message
                return .none

            case .requestPushPermission:
                return .run { send in
                    let granted = await notificationService.requestPermission()
                    await send(.pushPermissionResult(granted))
                }

            case .pushPermissionResult:
                return .send(.completeOnboarding)

            case .completeOnboarding:
                return .none
            }
        }
    }
}
