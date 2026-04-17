import Foundation
import ComposableArchitecture

/// Friends tab state — arkadaş listesi, bekleyen istekler, handle-search add akışı.
///
/// Scope:
///  - Liste view'ı bu state'e bağlanır.
///  - Gelen/giden istekleri aynı array'de saklıyoruz; `FriendProfile.status` + `isOutgoing`
///    UI filter'ı için yeterli.
///  - Daily energy rozetleri `energies` map'inden okunur; subscribe akışı stream'den beslenir.
@Reducer
struct FriendsFeature {

    @ObservableState
    struct State: Equatable {
        var friends: [FriendProfile] = []
        var energies: [UUID: DailyEnergyDTO] = [:]
        var isLoading: Bool = false
        var loadError: String?

        // Add friend flow
        var searchQuery: String = ""
        var searchResults: [PublicProfile] = []
        var isSearching: Bool = false
        var searchError: String?

        // Sheets
        var showAddSheet: Bool = false
        var showQRScanner: Bool = false
        var showShareQR: Bool = false
        var selectedFriendHandle: String?

        // Post-deep-link pending profile lookup
        var pendingProfileLookup: PublicProfile?
        var isLookingUp: Bool = false
        var lookupError: String?

        var isConfigured: Bool = true
    }

    enum Action: Equatable {
        case onAppear
        case friendsLoaded([FriendProfile])
        case friendsLoadFailed(String)
        case energiesLoaded([UUID: DailyEnergyDTO])

        // Realtime
        case subscribeToEnergies
        case energyUpdate([UUID: DailyEnergyDTO])

        // Add friend
        case searchQueryChanged(String)
        case searchResultsLoaded([PublicProfile])
        case searchFailed(String)
        case sendFriendRequest(targetId: UUID)
        case friendRequestSent
        case friendRequestFailed(String)

        // Respond to incoming
        case acceptRequest(id: UUID)
        case declineRequest(id: UUID)
        case unfriend(friendshipId: UUID)

        // UI
        case showAddSheet(Bool)
        case showQRScanner(Bool)
        case showShareQR(Bool)
        case selectFriend(handle: String?)

        // Deep link
        case resolveHandle(String)
        case handleResolved(PublicProfile)
        case handleResolveFailed(String)
    }

    @Dependency(\.supabase) var supabase
    @Dependency(\.mainQueue) var mainQueue

    private enum CancelID: Hashable {
        case search
        case energySubscription
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isConfigured = supabase.isConfigured()
                guard state.isConfigured else { return .none }
                state.isLoading = true
                return .merge(
                    .run { send in
                        do {
                            let list = try await supabase.listFriends()
                            await send(.friendsLoaded(list))
                            let energies = try await supabase.fetchFriendEnergies()
                            await send(.energiesLoaded(energies))
                        } catch {
                            await send(.friendsLoadFailed(error.localizedDescription))
                        }
                    },
                    .send(.subscribeToEnergies)
                )

            case .friendsLoaded(let friends):
                state.friends = friends
                state.isLoading = false
                state.loadError = nil
                return .none

            case .friendsLoadFailed(let message):
                state.isLoading = false
                state.loadError = message
                return .none

            case .energiesLoaded(let map):
                state.energies = map
                return .none

            case .subscribeToEnergies:
                guard state.isConfigured else { return .none }
                return .run { send in
                    for await update in supabase.subscribeFriendEnergies() {
                        await send(.energyUpdate(update))
                    }
                }
                .cancellable(id: CancelID.energySubscription, cancelInFlight: true)

            case .energyUpdate(let map):
                // Merge (don't clobber) so missing entries don't wipe valid ones
                state.energies.merge(map) { _, new in new }
                return .none

            case .searchQueryChanged(let query):
                state.searchQuery = query
                let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
                guard trimmed.count >= 2 else {
                    state.searchResults = []
                    state.isSearching = false
                    return .cancel(id: CancelID.search)
                }
                state.isSearching = true
                state.searchError = nil
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(300))
                    do {
                        let results = try await supabase.searchHandle(trimmed)
                        await send(.searchResultsLoaded(results))
                    } catch {
                        await send(.searchFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchResultsLoaded(let results):
                state.searchResults = results
                state.isSearching = false
                return .none

            case .searchFailed(let message):
                state.isSearching = false
                state.searchError = message
                return .none

            case .sendFriendRequest(let targetId):
                return .run { send in
                    do {
                        try await supabase.sendFriendRequest(targetId)
                        await send(.friendRequestSent)
                    } catch {
                        await send(.friendRequestFailed(error.localizedDescription))
                    }
                }

            case .friendRequestSent:
                state.showAddSheet = false
                state.searchQuery = ""
                state.searchResults = []
                return .send(.onAppear)

            case .friendRequestFailed(let message):
                state.searchError = message
                return .none

            case .acceptRequest(let id):
                return .run { send in
                    try? await supabase.acceptFriendRequest(id)
                    await send(.onAppear)
                }

            case .declineRequest(let id):
                return .run { send in
                    try? await supabase.declineFriendRequest(id)
                    await send(.onAppear)
                }

            case .unfriend(let friendshipId):
                return .run { send in
                    try? await supabase.unfriend(friendshipId)
                    await send(.onAppear)
                }

            case .showAddSheet(let visible):
                state.showAddSheet = visible
                if !visible {
                    state.searchQuery = ""
                    state.searchResults = []
                    state.searchError = nil
                }
                return .none

            case .showQRScanner(let visible):
                state.showQRScanner = visible
                return .none

            case .showShareQR(let visible):
                state.showShareQR = visible
                return .none

            case .selectFriend(let handle):
                state.selectedFriendHandle = handle
                return .none

            case .resolveHandle(let handle):
                state.isLookingUp = true
                state.lookupError = nil
                return .run { send in
                    do {
                        let results = try await supabase.searchHandle(handle)
                        if let exact = results.first(where: { $0.handle == handle }) {
                            await send(.handleResolved(exact))
                        } else {
                            await send(.handleResolveFailed("Kullanıcı bulunamadı"))
                        }
                    } catch {
                        await send(.handleResolveFailed(error.localizedDescription))
                    }
                }

            case .handleResolved(let profile):
                state.pendingProfileLookup = profile
                state.isLookingUp = false
                return .none

            case .handleResolveFailed(let message):
                state.isLookingUp = false
                state.lookupError = message
                return .none
            }
        }
    }
}
