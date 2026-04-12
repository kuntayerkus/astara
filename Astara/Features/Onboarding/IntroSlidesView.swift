import SwiftUI
import ComposableArchitecture

struct IntroSlidesView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    private let slides: [(icon: String, title: String, subtitle: String)] = [
        (
            "star.fill",
            "Yıldızlara, zorluklarla.",
            "Astara, gökyüzünü senin için okuyor. Haritanı çıkar, enerjini anla."
        ),
        (
            "chart.pie.fill",
            "Haritanı oku. Enerjini anla. Yolunu bul.",
            "Doğum haritandan günlük enerjine, her şey tek bir yerde."
        ),
        (
            "sparkles",
            "Her gün, gökyüzü sana bir şey söylüyor.",
            "Gezegen hareketleri, retro uyarıları ve kişisel yorumlarla her güne hazır ol."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TabView(selection: $store.introSlideIndex.sending(\.setIntroSlide)) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    slideView(icon: slide.icon, title: slide.title, subtitle: slide.subtitle)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            // Page indicator
            HStack(spacing: AstaraSpacing.xs) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == store.introSlideIndex
                            ? AstaraColors.gold
                            : AstaraColors.textTertiary
                        )
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: store.introSlideIndex)
                }
            }
            .padding(.top, AstaraSpacing.lg)

            Spacer()

            // Continue button
            AstaraButton(title: String(localized: "continue"), style: .primary) {
                if store.introSlideIndex < slides.count - 1 {
                    store.send(.setIntroSlide(store.introSlideIndex + 1))
                } else {
                    store.send(.nextStep)
                }
            }
            .padding(.horizontal, AstaraSpacing.lg)
            .padding(.bottom, AstaraSpacing.xxl)
        }
    }

    private func slideView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AstaraSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AstaraColors.gold)

            Text(title)
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AstaraSpacing.xl)
        }
        .padding(.horizontal, AstaraSpacing.md)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        IntroSlidesView(
            store: Store(initialState: OnboardingFeature.State(currentStep: .intro)) {
                OnboardingFeature()
            }
        )
    }
}
