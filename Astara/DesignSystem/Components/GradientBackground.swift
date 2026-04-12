import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AstaraColors.backgroundStart, AstaraColors.backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
