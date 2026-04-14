import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(
            name: .astaraDidRegisterDeviceToken,
            object: nil,
            userInfo: ["token": token]
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let deepLink = userInfo["deep_link"] as? String, let url = URL(string: deepLink) {
            NotificationCenter.default.post(name: .astaraDidOpenDeepLink, object: url)
        } else if let type = userInfo["type"] as? String {
            let path: String
            switch type {
            case "daily_energy":
                path = AppConstants.DeepLink.dailyPath
            default:
                path = AppConstants.DeepLink.chartPath
            }

            if let url = URL(string: "\(AppConstants.DeepLink.scheme)://\(path)") {
                NotificationCenter.default.post(name: .astaraDidOpenDeepLink, object: url)
            }
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let astaraDidRegisterDeviceToken = Notification.Name("astara.didRegisterDeviceToken")
    static let astaraDidOpenDeepLink = Notification.Name("astara.didOpenDeepLink")
}
