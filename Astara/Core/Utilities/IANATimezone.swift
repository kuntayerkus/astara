import Foundation

// CRITICAL: This utility ONLY passes through IANA timezone identifiers.
// It NEVER converts times to UTC. The VPS handles all DST-aware conversions via pytz.
// Format: "Europe/Istanbul", "America/New_York", etc.

enum IANATimezone {
    /// Returns the device's current IANA timezone identifier
    static var current: String {
        TimeZone.current.identifier
    }

    /// Validates that a string is a known IANA timezone identifier
    static func isValid(_ identifier: String) -> Bool {
        TimeZone(identifier: identifier) != nil
    }

    /// Returns a TimeZone from an IANA identifier, or nil if invalid
    static func timeZone(for identifier: String) -> TimeZone? {
        TimeZone(identifier: identifier)
    }
}
