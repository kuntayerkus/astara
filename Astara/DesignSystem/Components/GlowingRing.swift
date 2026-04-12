import SwiftUI

struct GlowingRing: View {
    var color: Color = AstaraColors.gold
    var lineWidth: CGFloat = 2
    var glowRadius: CGFloat = 12
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(color, lineWidth: lineWidth)
            .shadow(color: color.opacity(isAnimating ? 0.6 : 0.2), radius: glowRadius)
            .opacity(isAnimating ? 1 : 0.7)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    GlowingRing()
        .frame(width: 200, height: 200)
        .padding()
        .astaraBackground()
}
