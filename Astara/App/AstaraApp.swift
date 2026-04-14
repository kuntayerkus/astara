import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct AstaraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .onAppear {
                    store.send(.checkOnboardingStatus)
                }
                .onReceive(NotificationCenter.default.publisher(for: .astaraDidRegisterDeviceToken)) { notification in
                    guard let token = notification.userInfo?["token"] as? String else { return }
                    store.send(.syncDeviceToken(token))
                }
                .onReceive(NotificationCenter.default.publisher(for: .astaraDidOpenDeepLink)) { notification in
                    guard let url = notification.object as? URL else { return }
                    store.send(.handleDeepLink(url))
                }
                .onOpenURL { url in
                    store.send(.handleDeepLink(url))
                }
        }
        .modelContainer(ModelContainer.astara)
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
