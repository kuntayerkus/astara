import Foundation
import ComposableArchitecture

@Reducer
struct CompatibilityFeature {
    @ObservableState
    struct State: Equatable {
        // Legacy quick sign-vs-sign playground (unchanged UX)
        var sign1: ZodiacSign = .aries
        var sign2: ZodiacSign = .libra
        var result: Compatibility?
        var isCalculating: Bool = false
        var showDetail: Bool = false
        var isPremium: Bool = false

        // Real partners + synastry
        var partners: [PartnerDTO] = []
        var selectedPartner: PartnerDTO?
        var synastry: Synastry?
        var isLoadingSynastry: Bool = false
        var synastryError: String?
        var showAddPartner: Bool = false

        // Shared: the user's own chart. Passed in from parent (HomeFeature /
        // AppFeature) — synastry needs both sides.
        var userChart: BirthChart?
        var userId: UUID?
    }

    enum Action: Equatable {
        // Legacy sign-pair
        case onAppear(userSign: ZodiacSign)
        case selectSign1(ZodiacSign)
        case selectSign2(ZodiacSign)
        case calculate
        case resultReady(Compatibility)
        case toggleDetail
        case swapSigns
        case requestPremium

        // Partners
        case loadPartners
        case partnersLoaded([PartnerDTO])
        case selectPartner(PartnerDTO?)
        case showAddPartner(Bool)
        case addPartner(PartnerDTO)
        case deletePartner(UUID)
        case computeSynastry
        case synastryReady(Synastry)
        case synastryFailed(String)
    }

    @Dependency(\.compatibilityEngine) var compatibilityEngine
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.synastryService) var synastryService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear(let userSign):
                state.sign1 = userSign
                return .merge(
                    .send(.calculate),
                    .send(.loadPartners)
                )

            case .selectSign1(let sign):
                state.sign1 = sign
                state.result = nil
                return .send(.calculate)

            case .selectSign2(let sign):
                state.sign2 = sign
                state.result = nil
                return .send(.calculate)

            case .calculate:
                state.isCalculating = true
                let s1 = state.sign1
                let s2 = state.sign2
                return .run { send in
                    let result = await compatibilityEngine.calculate(s1, s2)
                    await send(.resultReady(result))
                }

            case .resultReady(let compatibility):
                state.isCalculating = false
                state.result = compatibility
                return .none

            case .toggleDetail:
                state.showDetail.toggle()
                return .none

            case .swapSigns:
                let tmp = state.sign1
                state.sign1 = state.sign2
                state.sign2 = tmp
                state.result = nil
                return .send(.calculate)

            case .requestPremium:
                return .none

            // MARK: Partners

            case .loadPartners:
                return .run { send in
                    let partners = await persistenceClient.listPartners()
                    await send(.partnersLoaded(partners))
                }

            case .partnersLoaded(let partners):
                state.partners = partners
                // If selected partner got deleted externally, clear it.
                if let sel = state.selectedPartner,
                   !partners.contains(where: { $0.id == sel.id }) {
                    state.selectedPartner = nil
                    state.synastry = nil
                }
                return .none

            case .selectPartner(let partner):
                state.selectedPartner = partner
                state.synastry = nil
                state.synastryError = nil
                if partner != nil { return .send(.computeSynastry) }
                return .none

            case .showAddPartner(let show):
                state.showAddPartner = show
                return .none

            case .addPartner(let partner):
                return .run { send in
                    await persistenceClient.addPartner(partner)
                    await send(.loadPartners)
                    await send(.selectPartner(partner))
                    await send(.showAddPartner(false))
                }

            case .deletePartner(let id):
                return .run { send in
                    await synastryService.invalidate(id)
                    await persistenceClient.deletePartner(id)
                    await send(.loadPartners)
                }

            case .computeSynastry:
                guard let chart = state.userChart, let partner = state.selectedPartner else {
                    return .none
                }
                state.isLoadingSynastry = true
                state.synastryError = nil
                return .run { send in
                    do {
                        let syn = try await synastryService.compare(chart, partner)
                        await send(.synastryReady(syn))
                    } catch {
                        await send(.synastryFailed(error.localizedDescription))
                    }
                }

            case .synastryReady(let syn):
                state.isLoadingSynastry = false
                state.synastry = syn
                return .none

            case .synastryFailed(let message):
                state.isLoadingSynastry = false
                state.synastryError = message
                return .none
            }
        }
    }
}
