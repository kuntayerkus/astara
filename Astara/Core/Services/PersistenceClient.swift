import Foundation
import SwiftData
import ComposableArchitecture

// MARK: - Shared ModelContainer

extension ModelContainer {
    /// Main app + widget share this container via an App Group, so the widget
    /// timeline provider can read ``User`` (for premium flag, sun sign, etc.)
    /// without the host app being active.
    static let astara: ModelContainer = {
        let schema = Schema([User.self, Partner.self])
        let modelConfiguration = ModelConfiguration(schema: schema, url: sharedStoreURL(for: schema))

        // One-shot migration: if an older sandbox store exists but the App
        // Group store does not, copy the SQLite files over so pre-widget
        // TestFlight users don't lose their onboarding data.
        migrateSandboxStoreIfNeeded(to: modelConfiguration.url)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer initialization failed: \(error). Deleting store to recover.")
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to initialize ModelContainer even after clearing store: \(error)")
            }
        }
    }()
}

// MARK: - App Group storage + migration

/// App Group container URL for the SwiftData store. Falls back to the default
/// ``ModelConfiguration`` URL (sandbox Application Support) when the App Group
/// entitlement is missing — e.g. simulator builds without provisioning.
private func sharedStoreURL(for schema: Schema) -> URL {
    if let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: AppConstants.appGroup
    ) {
        return containerURL.appendingPathComponent("Astara.sqlite")
    }
    return ModelConfiguration(schema: schema).url
}

/// Copy the sandbox store into the App Group container once, so existing
/// users (pre-widget release) keep their profile and engagement data.
private func migrateSandboxStoreIfNeeded(to appGroupURL: URL) {
    // Nothing to migrate if we're already on the sandbox fallback path.
    guard appGroupURL.path.contains(AppConstants.appGroup) else { return }

    let defaults = UserDefaults(suiteName: AppConstants.appGroup) ?? .standard
    let migrationKey = "astara_sandbox_to_appgroup_migrated_v1"
    if defaults.bool(forKey: migrationKey) { return }

    let sandboxURL = ModelConfiguration(schema: Schema([User.self])).url
    let fm = FileManager.default

    // Only migrate if sandbox store exists AND App Group store doesn't yet.
    guard fm.fileExists(atPath: sandboxURL.path),
          !fm.fileExists(atPath: appGroupURL.path) else {
        defaults.set(true, forKey: migrationKey)
        return
    }

    // Copy SQLite main + WAL + SHM files. Missing sidecar files are OK.
    let suffixes = ["", "-wal", "-shm"]
    for suffix in suffixes {
        let src = URL(fileURLWithPath: sandboxURL.path + suffix)
        let dst = URL(fileURLWithPath: appGroupURL.path + suffix)
        if fm.fileExists(atPath: src.path) {
            try? fm.copyItem(at: src, to: dst)
        }
    }

    defaults.set(true, forKey: migrationKey)
}

// MARK: - PersistenceClient

@DependencyClient
struct PersistenceClient {
    var saveUser: @Sendable (
        _ birthDate: Date,
        _ birthTime: Date?,
        _ birthTimeUnknown: Bool,
        _ birthCity: String,
        _ latitude: Double,
        _ longitude: Double,
        _ timezone: String
    ) async -> Void
    var loadUser: @Sendable () async -> UserDTO? = { nil }
    var updateUser: @Sendable (
        _ birthDate: Date,
        _ birthTime: Date?,
        _ birthTimeUnknown: Bool,
        _ birthCity: String,
        _ latitude: Double,
        _ longitude: Double,
        _ timezone: String
    ) async -> Void
    var setPremiumStatus: @Sendable (_ isPremium: Bool) async -> Void
    var updateEngagement: @Sendable (_ engagement: UserEngagementState) async -> Void

    // MARK: - Friend System (v2)
    var setHandle: @Sendable (_ handle: String) async -> Void = { _ in }
    var setSupabaseUserId: @Sendable (_ id: UUID) async -> Void = { _ in }

    // MARK: - Partners (Synastry)
    var listPartners: @Sendable () async -> [PartnerDTO] = { [] }
    var addPartner: @Sendable (_ partner: PartnerDTO) async -> Void
    var updatePartner: @Sendable (_ partner: PartnerDTO) async -> Void
    var deletePartner: @Sendable (_ id: UUID) async -> Void
}

// MARK: - Sendable DTO for cross-isolation transfer
struct UserDTO: Sendable, Equatable {
    let id: UUID
    let name: String
    let birthDate: Date
    let birthTime: Date?
    let birthTimeUnknown: Bool
    let birthCity: String
    let birthLatitude: Double
    let birthLongitude: Double
    let birthTimezone: String
    let isPremium: Bool
    let locale: String
    let onboardingCompleted: Bool
    let createdAt: Date
    let engagement: UserEngagementState
    let handle: String?
    let supabaseUserId: UUID?
}

struct MoodEntry: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let date: Date
    let mood: Int
    let note: String

    init(id: UUID = UUID(), date: Date, mood: Int, note: String) {
        self.id = id
        self.date = date
        self.mood = mood
        self.note = note
    }
}

struct UserEngagementState: Equatable, Sendable {
    var streakCount: Int
    var longestStreak: Int
    var lastOpenDate: Date?
    var taskDateKey: String
    var completedTasks: Set<String>
    var moods: [MoodEntry]
    var lastShareDate: Date?
    var askDateKey: String
    var askCountToday: Int
    var journalCount: Int

    static let empty = UserEngagementState(
        streakCount: 0,
        longestStreak: 0,
        lastOpenDate: nil,
        taskDateKey: "",
        completedTasks: [],
        moods: [],
        lastShareDate: nil,
        askDateKey: "",
        askCountToday: 0,
        journalCount: 0
    )
}

extension PersistenceClient: DependencyKey {
    static let liveValue = PersistenceClient(
        saveUser: { birthDate, birthTime, birthTimeUnknown, birthCity, lat, lng, timezone in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let user = User(
                    birthDate: birthDate,
                    birthTime: birthTime,
                    birthTimeUnknown: birthTimeUnknown,
                    birthCity: birthCity,
                    birthLatitude: lat,
                    birthLongitude: lng,
                    birthTimezone: timezone,
                    onboardingCompleted: true
                )
                ctx.insert(user)
                try? ctx.save()
            }
        },

        loadUser: {
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return nil }
                return UserDTO(
                    id: user.id,
                    name: user.name,
                    birthDate: user.birthDate,
                    birthTime: user.birthTime,
                    birthTimeUnknown: user.birthTimeUnknown,
                    birthCity: user.birthCity,
                    birthLatitude: user.birthLatitude,
                    birthLongitude: user.birthLongitude,
                    birthTimezone: user.birthTimezone,
                    isPremium: true, // user.isPremium,
                    locale: user.locale,
                    onboardingCompleted: user.onboardingCompleted,
                    createdAt: user.createdAt,
                    engagement: decodeEngagement(from: user),
                    handle: user.handle,
                    supabaseUserId: user.supabaseUserId
                )
            }
        },

        updateUser: { birthDate, birthTime, birthTimeUnknown, birthCity, lat, lng, timezone in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return }
                user.birthDate = birthDate
                user.birthTime = birthTime
                user.birthTimeUnknown = birthTimeUnknown
                user.birthCity = birthCity
                user.birthLatitude = lat
                user.birthLongitude = lng
                user.birthTimezone = timezone
                try? ctx.save()
            }
        },

        setPremiumStatus: { isPremium in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return }
                user.isPremium = isPremium
                try? ctx.save()
            }
        },

        updateEngagement: { engagement in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return }

                user.streakCount = engagement.streakCount
                user.longestStreak = engagement.longestStreak
                user.lastOpenDate = engagement.lastOpenDate
                user.taskDateKey = engagement.taskDateKey
                user.completedTasksCSV = engagement.completedTasks.sorted().joined(separator: ",")
                user.lastShareDate = engagement.lastShareDate
                user.askDateKey = engagement.askDateKey
                user.askCountToday = engagement.askCountToday
                user.journalCount = engagement.journalCount

                if let moodData = try? JSONEncoder().encode(engagement.moods),
                   let moodJSON = String(data: moodData, encoding: .utf8) {
                    user.moodHistoryJSON = moodJSON
                }

                try? ctx.save()
            }
        },

        setHandle: { handle in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return }
                user.handle = handle
                try? ctx.save()
            }
        },

        setSupabaseUserId: { id in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<User>()
                guard let user = (try? ctx.fetch(descriptor))?.first else { return }
                user.supabaseUserId = id
                try? ctx.save()
            }
        },

        listPartners: {
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<Partner>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
                guard let partners = try? ctx.fetch(descriptor) else { return [] }
                return partners.map(Self.dto(from:))
            }
        },

        addPartner: { dto in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let partner = Partner(
                    id: dto.id,
                    ownerUserId: dto.ownerUserId,
                    name: dto.name,
                    birthDate: dto.birthDate,
                    birthTime: dto.birthTime,
                    birthTimeUnknown: dto.birthTimeUnknown,
                    birthCity: dto.birthCity,
                    birthLatitude: dto.birthLatitude,
                    birthLongitude: dto.birthLongitude,
                    birthTimezone: dto.birthTimezone,
                    source: dto.source,
                    createdAt: dto.createdAt
                )
                ctx.insert(partner)
                try? ctx.save()
            }
        },

        updatePartner: { dto in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let targetId = dto.id
                let descriptor = FetchDescriptor<Partner>(
                    predicate: #Predicate { $0.id == targetId }
                )
                guard let partner = (try? ctx.fetch(descriptor))?.first else { return }
                partner.name = dto.name
                partner.birthDate = dto.birthDate
                partner.birthTime = dto.birthTime
                partner.birthTimeUnknown = dto.birthTimeUnknown
                partner.birthCity = dto.birthCity
                partner.birthLatitude = dto.birthLatitude
                partner.birthLongitude = dto.birthLongitude
                partner.birthTimezone = dto.birthTimezone
                // Birth data changed → chart + synastry caches are stale.
                partner.cachedChartJSON = nil
                partner.cachedSynastryJSON = nil
                partner.lastSyncedAt = nil
                try? ctx.save()
            }
        },

        deletePartner: { id in
            await MainActor.run {
                let ctx = ModelContainer.astara.mainContext
                let descriptor = FetchDescriptor<Partner>(
                    predicate: #Predicate { $0.id == id }
                )
                guard let partner = (try? ctx.fetch(descriptor))?.first else { return }
                ctx.delete(partner)
                try? ctx.save()
            }
        }
    )

    /// Convert a SwiftData ``Partner`` into a Sendable ``PartnerDTO`` for
    /// cross-isolation use. Must run on MainActor because it touches @Model
    /// properties.
    @MainActor
    static func dto(from partner: Partner) -> PartnerDTO {
        PartnerDTO(
            id: partner.id,
            ownerUserId: partner.ownerUserId,
            name: partner.name,
            birthDate: partner.birthDate,
            birthTime: partner.birthTime,
            birthTimeUnknown: partner.birthTimeUnknown,
            birthCity: partner.birthCity,
            birthLatitude: partner.birthLatitude,
            birthLongitude: partner.birthLongitude,
            birthTimezone: partner.birthTimezone,
            lastSyncedAt: partner.lastSyncedAt,
            source: partner.source,
            createdAt: partner.createdAt
        )
    }

    static let previewValue = PersistenceClient(
        saveUser: { _, _, _, _, _, _, _ in },
        loadUser: { nil },
        updateUser: { _, _, _, _, _, _, _ in },
        setPremiumStatus: { _ in },
        updateEngagement: { _ in },
        setHandle: { _ in },
        setSupabaseUserId: { _ in },

        listPartners: { [] },
        addPartner: { _ in },
        updatePartner: { _ in },
        deletePartner: { _ in }
    )
}

extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}

private func decodeEngagement(from user: User) -> UserEngagementState {
    let tasks = Set(
        user.completedTasksCSV
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }
    )

    let moods: [MoodEntry]
    if let data = user.moodHistoryJSON.data(using: .utf8),
       let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
        moods = decoded
    } else {
        moods = []
    }

    return UserEngagementState(
        streakCount: user.streakCount,
        longestStreak: user.longestStreak,
        lastOpenDate: user.lastOpenDate,
        taskDateKey: user.taskDateKey,
        completedTasks: tasks,
        moods: moods,
        lastShareDate: user.lastShareDate,
        askDateKey: user.askDateKey,
        askCountToday: user.askCountToday,
        journalCount: user.journalCount
    )
}
