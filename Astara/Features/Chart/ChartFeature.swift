import Foundation
import ComposableArchitecture

@Reducer
struct ChartFeature {
    @ObservableState
    struct State: Equatable {
        var chart: BirthChart?
        var selectedPlanet: PlanetKey?
        var selectedHouse: Int?
        var showPlanetDetail: Bool = false
        var showHouseDetail: Bool = false
        var showAspectGrid: Bool = false
        var isPremium: Bool = false
        var showAIInterpretation: Bool = false
        var showChartShare: Bool = false
    }

    enum Action: Equatable {
        case onAppear
        case setChart(BirthChart)
        case selectPlanet(PlanetKey)
        case dismissPlanetDetail
        case selectHouse(Int)
        case dismissHouseDetail
        case toggleAspectGrid
        case requestPremium
        case toggleAIInterpretation
        case toggleChartShare
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case .setChart(let chart):
                state.chart = chart
                return .none

            case .selectPlanet(let key):
                state.selectedPlanet = key
                state.showPlanetDetail = true
                return .none

            case .dismissPlanetDetail:
                state.showPlanetDetail = false
                state.selectedPlanet = nil
                return .none

            case .selectHouse(let number):
                state.selectedHouse = number
                state.showHouseDetail = true
                return .none

            case .dismissHouseDetail:
                state.showHouseDetail = false
                state.selectedHouse = nil
                return .none

            case .toggleAspectGrid:
                state.showAspectGrid.toggle()
                return .none

            case .requestPremium:
                return .none

            case .toggleAIInterpretation:
                state.showAIInterpretation.toggle()
                return .none

            case .toggleChartShare:
                state.showChartShare.toggle()
                return .none
            }
        }
    }
}
