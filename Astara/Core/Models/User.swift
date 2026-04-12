import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthTimeUnknown: Bool

    // Birth location
    var birthCity: String
    var birthLatitude: Double
    var birthLongitude: Double

    // CRITICAL: Always IANA format (e.g. "Europe/Istanbul"). NEVER convert to UTC.
    var birthTimezone: String

    // State
    var isPremium: Bool
    var locale: String
    var onboardingCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        birthDate: Date = Date(),
        birthTime: Date? = nil,
        birthTimeUnknown: Bool = false,
        birthCity: String = "",
        birthLatitude: Double = 0,
        birthLongitude: Double = 0,
        birthTimezone: String = "Europe/Istanbul",
        isPremium: Bool = false,
        locale: String = "tr",
        onboardingCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthTimeUnknown = birthTimeUnknown
        self.birthCity = birthCity
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthTimezone = birthTimezone
        self.isPremium = isPremium
        self.locale = locale
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
    }
}
