import SwiftUI

struct GradientBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [AstaraColors.backgroundStart, AstaraColors.backgroundEnd],
            startPoint: animate ? .topLeading : .top,
            endPoint: animate ? .bottomTrailing : .bottom
        )
        .hueRotation(.radians(animate ? 0.04 : -0.04))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

extension View {
    func astaraBackground() -> some View {
        self.background { GradientBackground() }
    }
}

#Preview {
    GradientBackground()
}
