import Foundation
import ComposableArchitecture

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        var userName: String = ""
        var birthCity: String = ""
        var birthDate: Date = Date()
        var isPremium: Bool = false
        var subscriptionStatus: SubscriptionStatus = .unknown
        var notificationsEnabled: Bool = false
        var dailyNotificationHour: Int = 8
        var showEditBirthData: Bool = false
        var showSubscription: Bool = false
        var isLoadingSubscription: Bool = false
    }

    enum Action: Equatable {
        case onAppear
        case checkNotificationStatus
        case notificationStatusResult(Bool)
        case checkSubscriptionStatus
        case subscriptionStatusResult(SubscriptionStatus)
        case toggleNotifications(Bool)
        case setDailyNotificationHour(Int)
        case toggleEditBirthData
        case toggleSubscription
    }

    @Dependency(\.notificationService) var notificationService
    @Dependency(\.subscriptionService) var subscriptionService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.checkNotificationStatus),
                    .send(.checkSubscriptionStatus)
                )

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

            case .toggleEditBirthData:
                state.showEditBirthData.toggle()
                return .none

            case .toggleSubscription:
                state.showSubscription.toggle()
                return .none
            }
        }
    }
}
