import Foundation
import UserNotifications
import UIKit
import ComposableArchitecture

@DependencyClient
struct NotificationService {
    var requestPermission: @Sendable () async -> Bool = { false }
    var scheduleDaily: @Sendable (_ hour: Int, _ minute: Int) async -> Void
    var scheduleTransitAlert: @Sendable (_ title: String, _ body: String, _ afterSeconds: TimeInterval) async -> Void
    var cancelAll: @Sendable () async -> Void
    var isAuthorized: @Sendable () async -> Bool = { false }
    var syncDeviceToken: @Sendable (_ token: String) async throws -> Void
}

extension NotificationService: DependencyKey {
    static let liveValue = NotificationService(
        requestPermission: {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                return granted
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

        scheduleTransitAlert: { title, body, afterSeconds in
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["type": "transit_alert"]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, afterSeconds), repeats: false)
            let request = UNNotificationRequest(identifier: "astara.transit.\(UUID().uuidString)", content: content, trigger: trigger)
            try? await center.add(request)
        },

        cancelAll: {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        },

        isAuthorized: {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        },

        syncDeviceToken: { token in
            @Dependency(\.apiClient) var apiClient

            struct NotificationTokenRequest: Encodable {
                let apnsToken: String
                let platform: String
            }

            let endpoint = Endpoint(
                path: "notifications/token",
                method: .post,
                body: NotificationTokenRequest(apnsToken: token, platform: "ios")
            )

            _ = try await apiClient.request(endpoint)
        }
    )

    static let previewValue = NotificationService(
        requestPermission: { true },
        scheduleDaily: { _, _ in },
        scheduleTransitAlert: { _, _, _ in },
        cancelAll: {},
        isAuthorized: { true },
        syncDeviceToken: { _ in }
    )
}

extension DependencyValues {
    var notificationService: NotificationService {
        get { self[NotificationService.self] }
        set { self[NotificationService.self] = newValue }
    }
}
