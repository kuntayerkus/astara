import UIKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        setupAppearance()
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Frosted glass effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        let activeColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0) // Gold
        let inactiveColor = UIColor.white.withAlphaComponent(0.4)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = inactiveColor
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
        
        itemAppearance.selected.iconColor = activeColor
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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
            case "friend_accepted", "friend_request":
                // Payload may include the friend's handle so we can jump straight
                // to their profile sheet. Fall back to the friends tab if missing.
                if let handle = userInfo["handle"] as? String,
                   AstaraSupabase.isHandleValid(handle) {
                    path = "\(AppConstants.DeepLink.friendPath)/\(handle)"
                } else {
                    path = AppConstants.DeepLink.friendPath
                }
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
