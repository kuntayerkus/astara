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
                    createdAt: user.createdAt
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
        }
    )

    static let previewValue = PersistenceClient(
        saveUser: { _, _, _, _, _, _, _ in },
        loadUser: { nil },
        updateUser: { _, _, _, _, _, _, _ in }
    )
}

extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
