import Foundation
import ComposableArchitecture

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        var userName: String = ""
        var birthCity: String = ""
        var birthDate: Date = Date()
        var birthTime: Date?
        var birthTimeUnknown: Bool = false
        var birthLatitude: Double = 0
        var birthLongitude: Double = 0
        var birthTimezone: String = "Europe/Istanbul"
        var isPremium: Bool = false
        var subscriptionStatus: SubscriptionStatus = .unknown
        var notificationsEnabled: Bool = false
        var dailyNotificationHour: Int = 8
        var showEditBirthData: Bool = false
        var showSubscription: Bool = false
        var isLoadingSubscription: Bool = false
        var purchaseErrorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loadUserData
        case userDataLoaded(UserDTO)
        case checkNotificationStatus
        case notificationStatusResult(Bool)
        case checkSubscriptionStatus
        case subscriptionStatusResult(SubscriptionStatus)
        case toggleNotifications(Bool)
        case setDailyNotificationHour(Int)
        case showEditBirthData
        case dismissEditBirthData
        case birthDataSaved
        case setSubscriptionPresented(Bool)
        case purchaseMonthly
        case purchaseYearly
        case restorePurchases
        case purchaseFinished(SubscriptionStatus)
        case purchaseFailed(String)
    }

    @Dependency(\.notificationService) var notificationService
    @Dependency(\.subscriptionService) var subscriptionService
    @Dependency(\.persistenceClient) var persistenceClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadUserData),
                    .send(.checkNotificationStatus),
                    .send(.checkSubscriptionStatus)
                )

            case .loadUserData:
                return .run { send in
                    if let user = await persistenceClient.loadUser() {
                        await send(.userDataLoaded(user))
                    }
                }

            case .userDataLoaded(let user):
                state.userName = user.name
                state.birthCity = user.birthCity
                state.birthDate = user.birthDate
                state.birthTime = user.birthTime
                state.birthTimeUnknown = user.birthTimeUnknown
                state.birthLatitude = user.birthLatitude
                state.birthLongitude = user.birthLongitude
                state.birthTimezone = user.birthTimezone
                state.isPremium = user.isPremium
                return .none

            case .checkNotificationStatus:
                return .run { send in
                    let authorized = await notificationService.isAuthorized()
                    await send(.notificationStatusResult(authorized))
                }

            case .notificationStatusResult(let enabled):
                state.notificationsEnabled = enabled
                return .none

            case .checkSubscriptionStatus:
                state.isLoadingSubscription = true
                return .run { send in
                    let status = await subscriptionService.status()
                    await send(.subscriptionStatusResult(status))
                }

            case .subscriptionStatusResult(let status):
                state.isLoadingSubscription = false
                state.subscriptionStatus = status
                state.isPremium = {
                    if case .premium = status { return true }
                    return false
                }()
                return .none

            case .toggleNotifications(let enable):
                state.notificationsEnabled = enable
                let hour = state.dailyNotificationHour
                return .run { send in
                    if enable {
                        let granted = await notificationService.requestPermission()
                        if granted {
                            await notificationService.scheduleDaily(hour, 0)
                        }
                        await send(.notificationStatusResult(granted))
                    } else {
                        await notificationService.cancelAll()
                        await send(.notificationStatusResult(false))
                    }
                }

            case .setDailyNotificationHour(let hour):
                state.dailyNotificationHour = hour
                if state.notificationsEnabled {
                    return .run { _ in
                        await notificationService.scheduleDaily(hour, 0)
                    }
                }
                return .none

            case .showEditBirthData:
                state.showEditBirthData = true
                return .none

            case .dismissEditBirthData:
                state.showEditBirthData = false
                return .send(.loadUserData)

            case .birthDataSaved:
                state.showEditBirthData = false
                return .send(.loadUserData)

            case .setSubscriptionPresented(let isPresented):
                state.showSubscription = isPresented
                if isPresented {
                    state.purchaseErrorMessage = nil
                }
                return .none

            case .purchaseMonthly:
                state.isLoadingSubscription = true
                state.purchaseErrorMessage = nil
                return .run { send in
                    do {
                        let status = try await subscriptionService.purchase(.monthlyPremium)
                        await send(.purchaseFinished(status))
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }

            case .purchaseYearly:
                state.isLoadingSubscription = true
                state.purchaseErrorMessage = nil
                return .run { send in
                    do {
                        let status = try await subscriptionService.purchase(.yearlyPremium)
                        await send(.purchaseFinished(status))
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }

            case .restorePurchases:
                state.isLoadingSubscription = true
                state.purchaseErrorMessage = nil
                return .run { send in
                    do {
                        let status = try await subscriptionService.restore()
                        await send(.purchaseFinished(status))
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }

            case .purchaseFinished(let status):
                state.isLoadingSubscription = false
                state.subscriptionStatus = status
                state.isPremium = {
                    if case .premium = status { return true }
                    return false
                }()
                state.showSubscription = false
                let isPremium = state.isPremium
                return .run { _ in
                    await persistenceClient.setPremiumStatus(isPremium)
                }

            case .purchaseFailed(let message):
                state.isLoadingSubscription = false
                state.purchaseErrorMessage = message
                return .none
            }
        }
    }
}
