import SwiftUI
import ComposableArchitecture

struct SplashView: View {
    let store: StoreOf<OnboardingFeature>

    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var logoScale: Double = 0.8

    var body: some View {
        VStack(spacing: AstaraSpacing.lg) {
            Spacer()

            // Logo
            VStack(spacing: AstaraSpacing.xs) {
                Text("ASTARA")
                    .font(.custom("CormorantGaramond-Bold", size: 52))
                    .foregroundStyle(AstaraColors.gold)
                    .tracking(8)

                // Star divider
                HStack(spacing: AstaraSpacing.sm) {
                    line
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AstaraColors.gold)
                    line
                }
                .frame(width: 160)
            }
            .opacity(logoOpacity)
            .scaleEffect(logoScale)

            // Tagline
            Text("Ad astra per aspera")
                .font(.custom("CormorantGaramond-Medium", size: 18))
                .foregroundStyle(AstaraColors.goldLight)
                .italic()
                .opacity(taglineOpacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                logoOpacity = 1
                logoScale = 1
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
                taglineOpacity = 1
            }
            // Auto-advance after splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                store.send(.splashTimerFired)
            }
        }
    }

    private var line: some View {
        Rectangle()
            .fill(AstaraColors.gold.opacity(0.4))
            .frame(height: 1)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        StarfieldView()
        SplashView(
            store: Store(initialState: OnboardingFeature.State()) {
                OnboardingFeature()
            }
        )
    }
}
