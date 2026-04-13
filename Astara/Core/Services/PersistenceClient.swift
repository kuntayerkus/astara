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
    var loadUser: @Sendable () async -> User?
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
                return (try? ctx.fetch(descriptor))?.first
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
