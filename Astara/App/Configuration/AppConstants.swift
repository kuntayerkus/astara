import Foundation

enum AppConstants {
    static let bundleID = "com.getastara.app"
    static let userAgent = "Astara-iOS/1.0"
    static let appName = "Astara"
    static let tagline = "Ad astra per aspera"

    /// App Group identifier shared between the host app and the widget extension.
    /// Both targets must have `com.apple.security.application-groups` capability
    /// enabled with this identifier in their entitlements.
    static let appGroup = "group.com.getastara.app"

    // MARK: - Cache TTLs (seconds)
    enum CacheTTL {
        static let dailyHoroscope: TimeInterval = 6 * 3600       // 6 hours
        static let planetPositions: TimeInterval = 6 * 3600      // 6 hours
        static let dailyEnergy: TimeInterval = 6 * 3600          // 6 hours
        static let retroCalendar: TimeInterval = 7 * 86400       // 7 days
        static let birthChart: TimeInterval = .infinity           // Never expires
        static let geoSearch: TimeInterval = 24 * 3600           // 24 hours
        static let timezone: TimeInterval = 7 * 86400            // 7 days
        static let blogArticles: TimeInterval = 3 * 86400        // 3 days
        static let aiResponse: TimeInterval = 6 * 3600           // 6 hours (Ask Astara / time travel)
        static let chartInterpretation: TimeInterval = .infinity // Chart never changes
        static let synastry: TimeInterval = .infinity            // Synastry invalidated manually when birth data changes
    }

    // MARK: - Rate Limits
    enum RateLimit {
        static let chartMaxPerMinute = 30
        static let horoscopeMaxPerHour = 10
        static let geoMaxPerSecond = 3
        static let geoDebounceMs = 300
    }

    // MARK: - Deep Links
    enum DeepLink {
        static let scheme = "astara"
        static let chartPath = "chart"
        static let dailyPath = "daily"
        static let compatibilityPath = "compatibility"
    }

    // MARK: - Notifications
    enum Notification {
        static let maxPerWeek = 5
        static let quietHoursStart = 23 // 23:00
        static let quietHoursEnd = 7    // 07:00
    }
}
