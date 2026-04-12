import Foundation
import ComposableArchitecture

// MARK: - Geo City (for city search)

struct GeoCity: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String // IANA format

    init(
        id: UUID = UUID(),
        name: String,
        country: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
    }
}

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

        // Chart
        var chart: BirthChart?
        var isLoading: Bool = false
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
        case selectCity(GeoCity)

        // Chart
        case calculateChart
        case chartCalculated(BirthChart)

        // Push
        case requestPushPermission
        case pushPermissionResult(Bool)

        // Completion
        case completeOnboarding
    }

    @Dependency(\.continuousClock) var clock

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
                // MVP: Return mock results. Real API integration in next sprint.
                let query = state.searchQuery.lowercased()
                let mockCities = Self.mockCities.filter {
                    $0.name.lowercased().contains(query)
                }
                return .run { send in
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.searchCitiesResponse(mockCities))
                }

            case .searchCitiesResponse(let cities):
                state.isSearching = false
                state.searchResults = cities
                return .none

            case .selectCity(let city):
                state.selectedCity = city
                state.searchQuery = city.name
                state.searchResults = []
                return .none

            case .calculateChart:
                state.isLoading = true
                // MVP: Use mock chart. Real VPS integration in next sprint.
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.chartCalculated(.preview))
                }

            case .chartCalculated(let chart):
                state.isLoading = false
                state.chart = chart
                state.currentStep = .chartReveal
                return .none

            case .requestPushPermission:
                // Stub — real implementation with UNUserNotificationCenter
                return .run { send in
                    await send(.pushPermissionResult(true))
                }

            case .pushPermissionResult:
                return .send(.completeOnboarding)

            case .completeOnboarding:
                return .none
            }
        }
    }

    // MARK: - Mock Cities

    private static let mockCities: [GeoCity] = [
        GeoCity(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: "Europe/Istanbul"),
        GeoCity(name: "Ankara", country: "Turkey", latitude: 39.9334, longitude: 32.8597, timezone: "Europe/Istanbul"),
        GeoCity(name: "Izmir", country: "Turkey", latitude: 38.4192, longitude: 27.1287, timezone: "Europe/Istanbul"),
        GeoCity(name: "Antalya", country: "Turkey", latitude: 36.8969, longitude: 30.7133, timezone: "Europe/Istanbul"),
        GeoCity(name: "Bursa", country: "Turkey", latitude: 40.1885, longitude: 29.0610, timezone: "Europe/Istanbul"),
        GeoCity(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London"),
        GeoCity(name: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060, timezone: "America/New_York"),
        GeoCity(name: "Los Angeles", country: "United States", latitude: 34.0522, longitude: -118.2437, timezone: "America/Los_Angeles"),
        GeoCity(name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050, timezone: "Europe/Berlin"),
        GeoCity(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, timezone: "Europe/Paris"),
    ]
}
