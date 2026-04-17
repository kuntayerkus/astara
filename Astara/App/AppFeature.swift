import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var destination: Destination = .onboarding
        var onboarding: OnboardingFeature.State = .init()
        var home: HomeFeature.State = .init()
        /// Set when a `astara://friend/{handle}` deep link arrives. The Home tab's
        /// Friends feature reads & clears this to present the profile sheet.
        var pendingFriendHandle: String?
        /// Set when `astara://qr` is opened — surfaces the QR scanner sheet.
        var pendingQRScan: Bool = false
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
                state.home.compatibility.userChart = chart
                if let sunSign = chart.sunSign {
                    state.home.userSunSign = sunSign
                    state.home.compatibility.sign1 = sunSign
                }
                return .none

            case .userChartFailed:
                return .none

            case .handleDeepLink(let url):
                switch Self.resolveDeepLink(url) {
                case .tab(let tab):
                    state.destination = .home
                    state.home.selectedTab = tab
                case .friendProfile(let handle):
                    state.destination = .home
                    state.pendingFriendHandle = handle
                    return .send(.home(.friends(.resolveHandle(handle))))
                case .qrScanner:
                    state.destination = .home
                    state.pendingQRScan = true
                    return .send(.home(.friends(.showQRScanner(true))))
                case .none:
                    break
                }
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
                    state.home.compatibility.userChart = chart
                    if let sunSign = chart.sunSign {
                        state.home.userSunSign = sunSign
                        state.home.compatibility.sign1 = sunSign
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
    enum DeepLinkDestination: Equatable {
        case tab(HomeFeature.Tab)
        case friendProfile(handle: String)
        case qrScanner
    }

    static func resolveDeepLink(_ url: URL) -> DeepLinkDestination? {
        guard url.scheme?.lowercased() == AppConstants.DeepLink.scheme else { return nil }

        var segments: [String] = []
        if let host = url.host, !host.isEmpty {
            segments.append(host.lowercased())
        }
        segments.append(contentsOf: url.pathComponents.filter { $0 != "/" }.map { $0.lowercased() })

        guard let first = segments.first else { return nil }

        switch first {
        case AppConstants.DeepLink.chartPath:
            return .tab(.chart)
        case AppConstants.DeepLink.dailyPath:
            return .tab(.daily)
        case AppConstants.DeepLink.compatibilityPath:
            return .tab(.compatibility)
        case AppConstants.DeepLink.friendPath:
            guard segments.count >= 2,
                  AstaraSupabase.isHandleValid(segments[1]) else { return nil }
            return .friendProfile(handle: segments[1])
        case AppConstants.DeepLink.qrPath:
            return .qrScanner
        default:
            return nil
        }
    }

    /// Legacy helper — kept for any call site still expecting a tab.
    static func mapDeepLinkToTab(_ url: URL) -> HomeFeature.Tab? {
        if case .tab(let tab) = resolveDeepLink(url) { return tab }
        return nil
    }
}
