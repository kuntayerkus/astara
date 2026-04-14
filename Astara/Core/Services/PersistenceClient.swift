import Foundation
import SwiftData
import ComposableArchitecture

// MARK: - Shared ModelContainer

extension ModelContainer {
    static let astara: ModelContainer = {
        try! ModelContainer(for: User.self)
    }()
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
                    isPremium: user.isPremium,
                    locale: user.locale,
                    onboardingCompleted: user.onboardingCompleted,
                    createdAt: user.createdAt,
                    engagement: decodeEngagement(from: user)
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
        }
    )

    static let previewValue = PersistenceClient(
        saveUser: { _, _, _, _, _, _, _ in },
        loadUser: { nil },
        updateUser: { _, _, _, _, _, _, _ in },
        setPremiumStatus: { _ in },
        updateEngagement: { _ in }
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
