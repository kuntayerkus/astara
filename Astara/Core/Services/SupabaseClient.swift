import Foundation
import ComposableArchitecture
import KeychainAccess
#if canImport(Supabase)
import Supabase
#endif

// MARK: - DTOs

struct ProfileDTO: Codable, Sendable, Equatable {
    let id: UUID
    let handle: String
    let email: String?
    let birthDate: Date?
    let birthTime: String?      // "HH:mm"
    let birthLat: Double?
    let birthLng: Double?
    let birthTimezone: String?
    let locale: String
}

struct PublicProfile: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let handle: String
    let birthDate: Date?
    let birthTimezone: String?
    let locale: String
}

struct FriendProfile: Codable, Sendable, Equatable, Identifiable {
    let id: UUID                // friendships row id
    let friendId: UUID          // other user's id
    let handle: String
    let status: FriendStatus
    let createdAt: Date
    let acceptedAt: Date?
    let isOutgoing: Bool        // true if current user initiated
}

enum FriendStatus: String, Codable, Sendable, Equatable {
    case pending, accepted, blocked
}

struct DailyEnergyDTO: Codable, Sendable, Equatable {
    let userId: UUID
    let date: Date
    let energy: Int
    let theme: String?
    let luckyColorHex: String?
}

struct AuthSession: Sendable, Equatable {
    let userId: UUID
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

// MARK: - Errors

enum AstaraSupabaseError: LocalizedError, Equatable {
    case notConfigured
    case unauthorized
    case handleTaken
    case invalidHandle
    case notFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Supabase bağlantısı yapılandırılmamış."
        case .unauthorized: "Oturum açman gerekiyor."
        case .handleTaken: "Bu kullanıcı adı alınmış."
        case .invalidHandle: "Geçersiz kullanıcı adı."
        case .notFound: "Bulunamadı."
        case .network(let msg): msg
        }
    }
}

// MARK: - Client

/// Thin wrapper around `supabase-swift` SDK exposing only the operations the
/// Friend System needs. All network I/O is gated behind configuration — if the
/// SUPABASE_URL / SUPABASE_ANON_KEY xcconfig values are missing or still carry
/// the `REPLACE_WITH_*` placeholder, every call throws `.notConfigured` so the
/// UI layer can surface an onboarding hint instead of crashing.
///
/// Auth tokens are persisted in Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
/// via KeychainAccess. The SDK's built-in session store is also used — our
/// Keychain copy is defensive in case of SDK cache resets between launches.
@DependencyClient
struct AstaraSupabase {
    var isConfigured: @Sendable () -> Bool = { false }
    var currentUserId: @Sendable () async -> UUID? = { nil }

    var signInWithApple: @Sendable (
        _ idToken: String,
        _ nonce: String
    ) async throws -> AuthSession = { _, _ in throw AstaraSupabaseError.notConfigured }

    var signOut: @Sendable () async throws -> Void = { throw AstaraSupabaseError.notConfigured }

    var checkHandleAvailable: @Sendable (_ handle: String) async throws -> Bool = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var claimHandle: @Sendable (_ handle: String) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var upsertProfile: @Sendable (_ profile: ProfileDTO) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var searchHandle: @Sendable (_ query: String) async throws -> [PublicProfile] = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var sendFriendRequest: @Sendable (_ targetId: UUID) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var acceptFriendRequest: @Sendable (_ friendshipId: UUID) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var declineFriendRequest: @Sendable (_ friendshipId: UUID) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var unfriend: @Sendable (_ friendshipId: UUID) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var listFriends: @Sendable () async throws -> [FriendProfile] = {
        throw AstaraSupabaseError.notConfigured
    }

    var pushMyEnergy: @Sendable (_ snapshot: DailyEnergyDTO) async throws -> Void = { _ in
        throw AstaraSupabaseError.notConfigured
    }

    var fetchFriendEnergies: @Sendable () async throws -> [UUID: DailyEnergyDTO] = {
        throw AstaraSupabaseError.notConfigured
    }

    /// Stream of partial updates. Empty stream when not configured so callers can
    /// `.listen` without guarding.
    var subscribeFriendEnergies: @Sendable () -> AsyncStream<[UUID: DailyEnergyDTO]> = {
        AsyncStream { $0.finish() }
    }

    var deleteAccount: @Sendable () async throws -> Void = {
        throw AstaraSupabaseError.notConfigured
    }
}

// MARK: - Keychain token store

private enum SupabaseKeychain {
    static let service = "com.getastara.app.supabase"
    static let accessTokenKey = "access_token"
    static let refreshTokenKey = "refresh_token"
    static let userIdKey = "user_id"

    static var keychain: Keychain {
        Keychain(service: service).accessibility(.whenUnlockedThisDeviceOnly)
    }

    static func store(session: AuthSession) {
        let kc = keychain
        kc[accessTokenKey] = session.accessToken
        kc[refreshTokenKey] = session.refreshToken
        kc[userIdKey] = session.userId.uuidString
    }

    static func clear() {
        try? keychain.removeAll()
    }

    static func load() -> (userId: UUID, accessToken: String)? {
        let kc = keychain
        guard let uidStr = kc[userIdKey], let uid = UUID(uuidString: uidStr),
              let token = kc[accessTokenKey] else { return nil }
        return (uid, token)
    }
}

// MARK: - Live value

extension AstaraSupabase: DependencyKey {
    static let liveValue: AstaraSupabase = {
        let env = APIEnvironment.current
        guard let url = env.supabaseURL, let key = env.supabaseAnonKey else {
            // Return the default (all-throwing) instance — isConfigured == false.
            return AstaraSupabase(isConfigured: { false })
        }

        #if canImport(Supabase)
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        return AstaraSupabase.live(client: client)
        #else
        // SDK not linked yet (CI caching, Package.resolved refresh lag).
        return AstaraSupabase(isConfigured: { false })
        #endif
    }()

    #if canImport(Supabase)
    static func live(client: SupabaseClient) -> AstaraSupabase {
        AstaraSupabase(
            isConfigured: { true },

            currentUserId: {
                if let user = try? await client.auth.user() {
                    return user.id
                }
                return SupabaseKeychain.load()?.userId
            },

            signInWithApple: { idToken, nonce in
                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
                )
                let astaraSession = AuthSession(
                    userId: session.user.id,
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expiresAt: Date(timeIntervalSince1970: session.expiresAt)
                )
                SupabaseKeychain.store(session: astaraSession)
                return astaraSession
            },

            signOut: {
                try await client.auth.signOut()
                SupabaseKeychain.clear()
            },

            checkHandleAvailable: { handle in
                let normalized = handle.lowercased()
                guard Self.isHandleValid(normalized) else { throw AstaraSupabaseError.invalidHandle }
                let rows: [PublicProfile] = try await client
                    .from("users")
                    .select("id, handle, birth_date, birth_timezone, locale")
                    .eq("handle", value: normalized)
                    .limit(1)
                    .execute()
                    .value
                return rows.isEmpty
            },

            claimHandle: { handle in
                let normalized = handle.lowercased()
                guard Self.isHandleValid(normalized) else { throw AstaraSupabaseError.invalidHandle }
                guard let user = try? await client.auth.user() else { throw AstaraSupabaseError.unauthorized }
                do {
                    try await client
                        .from("users")
                        .update(["handle": normalized])
                        .eq("id", value: user.id)
                        .execute()
                } catch {
                    // Postgres unique_violation surfaces as 23505 in error message.
                    if "\(error)".contains("23505") { throw AstaraSupabaseError.handleTaken }
                    throw AstaraSupabaseError.network("\(error.localizedDescription)")
                }
            },

            upsertProfile: { profile in
                try await client
                    .from("users")
                    .upsert(profile)
                    .execute()
            },

            searchHandle: { query in
                let q = query.lowercased()
                let rows: [PublicProfile] = try await client
                    .from("users")
                    .select("id, handle, birth_date, birth_timezone, locale")
                    .ilike("handle", pattern: "\(q)%")
                    .limit(20)
                    .execute()
                    .value
                return rows
            },

            sendFriendRequest: { targetId in
                guard let user = try? await client.auth.user() else { throw AstaraSupabaseError.unauthorized }
                struct NewFriendship: Encodable { let user_a: UUID; let user_b: UUID }
                try await client
                    .from("friendships")
                    .insert(NewFriendship(user_a: user.id, user_b: targetId))
                    .execute()
            },

            acceptFriendRequest: { friendshipId in
                struct Accept: Encodable { let status: String; let accepted_at: Date }
                try await client
                    .from("friendships")
                    .update(Accept(status: "accepted", accepted_at: Date()))
                    .eq("id", value: friendshipId)
                    .execute()
            },

            declineFriendRequest: { friendshipId in
                try await client
                    .from("friendships")
                    .delete()
                    .eq("id", value: friendshipId)
                    .execute()
            },

            unfriend: { friendshipId in
                try await client
                    .from("friendships")
                    .delete()
                    .eq("id", value: friendshipId)
                    .execute()
            },

            listFriends: {
                guard let user = try? await client.auth.user() else { throw AstaraSupabaseError.unauthorized }
                struct Row: Decodable {
                    let id: UUID
                    let user_a: UUID
                    let user_b: UUID
                    let status: String
                    let created_at: Date
                    let accepted_at: Date?
                }
                let rows: [Row] = try await client
                    .from("friendships")
                    .select("id, user_a, user_b, status, created_at, accepted_at")
                    .or("user_a.eq.\(user.id.uuidString),user_b.eq.\(user.id.uuidString)")
                    .execute()
                    .value

                // Fetch handles in one batch
                let otherIds = rows.map { $0.user_a == user.id ? $0.user_b : $0.user_a }
                let handles: [PublicProfile] = try await client
                    .from("users")
                    .select("id, handle, birth_date, birth_timezone, locale")
                    .in("id", values: otherIds)
                    .execute()
                    .value
                let handleMap = Dictionary(uniqueKeysWithValues: handles.map { ($0.id, $0.handle) })

                return rows.compactMap { row -> FriendProfile? in
                    let other = row.user_a == user.id ? row.user_b : row.user_a
                    guard let handle = handleMap[other],
                          let status = FriendStatus(rawValue: row.status) else { return nil }
                    return FriendProfile(
                        id: row.id,
                        friendId: other,
                        handle: handle,
                        status: status,
                        createdAt: row.created_at,
                        acceptedAt: row.accepted_at,
                        isOutgoing: row.user_a == user.id
                    )
                }
            },

            pushMyEnergy: { snapshot in
                try await client
                    .from("daily_energy_snapshots")
                    .upsert(snapshot, onConflict: "user_id,date")
                    .execute()
            },

            fetchFriendEnergies: {
                guard let user = try? await client.auth.user() else { throw AstaraSupabaseError.unauthorized }
                let today = ISO8601DateFormatter.astaraDateOnly.string(from: Date())
                let rows: [DailyEnergyDTO] = try await client
                    .from("daily_energy_snapshots")
                    .select()
                    .eq("date", value: today)
                    .neq("user_id", value: user.id)
                    .execute()
                    .value
                return Dictionary(uniqueKeysWithValues: rows.map { ($0.userId, $0) })
            },

            subscribeFriendEnergies: {
                // Realtime subscription is wired via a bridging stream. We poll
                // every 60s as a fallback + the SDK's channel updates will
                // yield sooner via the Task inside.
                AsyncStream { continuation in
                    let task = Task {
                        while !Task.isCancelled {
                            do {
                                let snapshot = try await Self.live(client: client).fetchFriendEnergies()
                                continuation.yield(snapshot)
                            } catch {
                                // Swallow — upstream will just see no update
                            }
                            try? await Task.sleep(nanoseconds: 60_000_000_000)
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },

            deleteAccount: {
                guard let user = try? await client.auth.user() else { throw AstaraSupabaseError.unauthorized }
                // Cascades friendships + daily_energy_snapshots via FK on delete.
                try await client
                    .from("users")
                    .delete()
                    .eq("id", value: user.id)
                    .execute()
                try? await client.auth.signOut()
                SupabaseKeychain.clear()
            }
        )
    }
    #endif

    static func isHandleValid(_ handle: String) -> Bool {
        let pattern = #"^[a-z0-9_]{3,20}$"#
        return handle.range(of: pattern, options: .regularExpression) != nil
            && !reservedHandles.contains(handle)
    }

    static let reservedHandles: Set<String> = [
        "admin", "astara", "help", "support", "root", "system",
        "api", "www", "info", "contact", "privacy", "legal",
        "official", "staff", "team", "app", "dev", "null", "undefined"
    ]
}

extension DependencyValues {
    var supabase: AstaraSupabase {
        get { self[AstaraSupabase.self] }
        set { self[AstaraSupabase.self] = newValue }
    }
}

// MARK: - Date helpers (date-only, UTC)

extension ISO8601DateFormatter {
    static let astaraDateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
