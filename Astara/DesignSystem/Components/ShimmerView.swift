import SwiftUI

struct ShimmerView: View {
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusMd
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AstaraColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: AstaraColors.gold.opacity(0.05), location: 0.3),
                                    .init(color: AstaraColors.goldLight.opacity(0.15), location: 0.5),
                                    .init(color: AstaraColors.gold.opacity(0.05), location: 0.7),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.6)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack(spacing: AstaraSpacing.sm) {
        ShimmerView()
            .frame(height: 20)
        ShimmerView()
            .frame(height: 20)
            .frame(width: 200)
        ShimmerView()
            .frame(height: 100)
    }
    .padding()
    .astaraBackground()
}
