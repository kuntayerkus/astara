import Foundation
import ComposableArchitecture

@Reducer
struct DailyHoroscopeFeature {
    @ObservableState
    struct State: Equatable {
        var horoscopes: [DailyHoroscope] = []
        var selectedSign: ZodiacSign = .aries
        var isLoading: Bool = false
        var showArchive: Bool = false
    }

    enum Action: Equatable {
        case onAppear(userSign: ZodiacSign)
        case selectSign(ZodiacSign)
        case loadHoroscopes
        case horoscopesLoaded([DailyHoroscope])
        case loadFailed
        case toggleArchive
    }

    @Dependency(\.horoscopeService) var horoscopeService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear(let userSign):
                state.selectedSign = userSign
                return .send(.loadHoroscopes)

            case .selectSign(let sign):
                state.selectedSign = sign
                return .none

            case .loadHoroscopes:
                guard state.horoscopes.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let horoscopes = try await horoscopeService.fetchDailyHoroscopes()
                        await send(.horoscopesLoaded(horoscopes))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case .horoscopesLoaded(let horoscopes):
                state.isLoading = false
                state.horoscopes = horoscopes
                return .none

            case .loadFailed:
                state.isLoading = false
                return .none

            case .toggleArchive:
                state.showArchive.toggle()
                return .none
            }
        }
    }
}

extension DailyHoroscopeFeature.State {
    var currentHoroscope: DailyHoroscope? {
        horoscopes.first(where: { $0.sign == selectedSign })
    }
}
