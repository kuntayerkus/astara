import Foundation
import SwiftData

/// Persistent partner profile used for synastry comparisons.
///
/// A partner is either **manually added** by the user (Feature 3) or
/// **linked** from a real Astara friend (Feature 4). Birth data follows
/// the same IANA-raw timezone rule as ``User`` — we never convert to UTC;
/// the VPS applies DST-aware conversion itself.
@Model
final class Partner {
    var id: UUID
    var ownerUserId: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthTimeUnknown: Bool
    var birthCity: String
    var birthLatitude: Double
    var birthLongitude: Double
    /// CRITICAL: Always IANA format (e.g. "Europe/Istanbul"). NEVER convert to UTC.
    var birthTimezone: String
    /// JSON-encoded ``BirthChart`` snapshot — avoids re-hitting the VPS for
    /// every synastry comparison. Invalidated when birth data changes.
    var cachedChartJSON: String?
    /// JSON-encoded ``Synastry`` snapshot keyed against the current owner
    /// chart. Invalidated when either chart changes.
    var cachedSynastryJSON: String?
    var lastSyncedAt: Date?
    /// "manual" for user-entered partners, "friend" for Supabase-linked friends (v2).
    var source: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        ownerUserId: UUID,
        name: String,
        birthDate: Date,
        birthTime: Date? = nil,
        birthTimeUnknown: Bool = false,
        birthCity: String = "",
        birthLatitude: Double = 0,
        birthLongitude: Double = 0,
        birthTimezone: String = "Europe/Istanbul",
        cachedChartJSON: String? = nil,
        cachedSynastryJSON: String? = nil,
        lastSyncedAt: Date? = nil,
        source: String = "manual",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthTimeUnknown = birthTimeUnknown
        self.birthCity = birthCity
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthTimezone = birthTimezone
        self.cachedChartJSON = cachedChartJSON
        self.cachedSynastryJSON = cachedSynastryJSON
        self.lastSyncedAt = lastSyncedAt
        self.source = source
        self.createdAt = createdAt
    }
}

// MARK: - Sendable DTO for TCA state

/// Sendable snapshot of a ``Partner`` used inside TCA reducers. ``Partner``
/// itself is a SwiftData `@Model` (reference type) and cannot cross actor
/// boundaries safely.
struct PartnerDTO: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var ownerUserId: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthTimeUnknown: Bool
    var birthCity: String
    var birthLatitude: Double
    var birthLongitude: Double
    var birthTimezone: String
    var lastSyncedAt: Date?
    var source: String
    var createdAt: Date

    /// Convenience: expected sun sign inferred from birth date (western
    /// tropical, ignoring year). Used for sign-only fallback scoring when no
    /// full chart is available yet.
    var approximateSunSign: ZodiacSign {
        ZodiacSign.forDate(birthDate)
    }

    /// If the user didn't provide a birth time we cannot trust Asc/Moon/House
    /// positions. UI should surface this.
    var hasTrustworthyChart: Bool { !birthTimeUnknown }
}

extension PartnerDTO {
    static let previewDiana = PartnerDTO(
        id: UUID(),
        ownerUserId: UUID(),
        name: "Diana",
        birthDate: Date(timeIntervalSince1970: -266_889_600), // 1961-07-01
        birthTime: nil,
        birthTimeUnknown: false,
        birthCity: "Sandringham, UK",
        birthLatitude: 52.83,
        birthLongitude: 0.52,
        birthTimezone: "Europe/London",
        lastSyncedAt: nil,
        source: "manual",
        createdAt: Date()
    )
}
