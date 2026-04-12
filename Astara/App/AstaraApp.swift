import SwiftUI
import ComposableArchitecture

@main
struct AstaraApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onAppear {
                    store.send(.checkOnboardingStatus)
                }
        }
    }
}

// MARK: - App View

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.destination {
            case .onboarding:
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
            case .home:
                HomeView(store: store.scope(state: \.home, action: \.home))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: store.destination)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
