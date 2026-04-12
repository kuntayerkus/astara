import SwiftUI

struct ShimmerView: View {
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusMd
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AstaraColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.08),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = UIScreen.main.bounds.width
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
