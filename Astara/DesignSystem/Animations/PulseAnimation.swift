import SwiftUI

struct PulseAnimation: View {
    var color: Color = AstaraColors.gold
    var size: CGFloat = 40
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.3 : 0.8)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 1.4, height: size * 1.4)
                .scaleEffect(isPulsing ? 1.1 : 0.9)
                .opacity(isPulsing ? 0.2 : 0.5)

            Circle()
                .fill(color.opacity(0.5))
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    PulseAnimation()
        .astaraBackground()
}
