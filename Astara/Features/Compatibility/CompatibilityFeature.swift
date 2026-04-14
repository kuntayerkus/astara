import Foundation
import ComposableArchitecture

@Reducer
struct CompatibilityFeature {
    @ObservableState
    struct State: Equatable {
        var sign1: ZodiacSign = .aries
        var sign2: ZodiacSign = .libra
        var result: Compatibility?
        var isCalculating: Bool = false
        var showDetail: Bool = false
        var isPremium: Bool = false
    }

    enum Action: Equatable {
        case onAppear(userSign: ZodiacSign)
        case selectSign1(ZodiacSign)
        case selectSign2(ZodiacSign)
        case calculate
        case resultReady(Compatibility)
        case toggleDetail
        case swapSigns
        case requestPremium
    }

    @Dependency(\.compatibilityEngine) var compatibilityEngine

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear(let userSign):
                state.sign1 = userSign
                return .send(.calculate)

            case .selectSign1(let sign):
                guard sign != state.sign2 else { return .none }
                state.sign1 = sign
                state.result = nil
                return .send(.calculate)

            case .selectSign2(let sign):
                guard sign != state.sign1 else { return .none }
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
            }
        }
    }
}
