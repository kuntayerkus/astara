import Foundation
import UserNotifications
import ComposableArchitecture

@DependencyClient
struct NotificationService {
    var requestPermission: @Sendable () async -> Bool = { false }
    var scheduleDaily: @Sendable (_ hour: Int, _ minute: Int) async -> Void
    var cancelAll: @Sendable () async -> Void
    var isAuthorized: @Sendable () async -> Bool = { false }
}

extension NotificationService: DependencyKey {
    static let liveValue = NotificationService(
        requestPermission: {
            let center = UNUserNotificationCenter.current()
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                return false
            }
        },

        scheduleDaily: { hour, minute in
            let center = UNUserNotificationCenter.current()

            // Remove existing daily trigger
            center.removePendingNotificationRequests(withIdentifiers: ["astara.daily"])

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification_daily_title")
            content.body = String(localized: "notification_daily_body")
            content.sound = .default
            // No personal data in payload — only a trigger type
            content.userInfo = ["type": "daily_energy"]

            var components = DateComponents()
            components.hour = hour
            components.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "astara.daily", content: content, trigger: trigger)

            try? await center.add(request)
        },

        cancelAll: {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        },

        isAuthorized: {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    )

    static let previewValue = NotificationService(
        requestPermission: { true },
        scheduleDaily: { _, _ in },
        cancelAll: {},
        isAuthorized: { true }
    )
}

extension DependencyValues {
    var notificationService: NotificationService {
        get { self[NotificationService.self] }
        set { self[NotificationService.self] = newValue }
    }
}
