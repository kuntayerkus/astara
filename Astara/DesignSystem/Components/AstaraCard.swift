import SwiftUI

struct AstaraCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AstaraColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}

extension View {
    func astaraCard(cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg) -> some View {
        modifier(AstaraCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    Text("Astara Card")
        .font(AstaraTypography.bodyLarge)
        .foregroundStyle(.white)
        .padding(AstaraSpacing.lg)
        .astaraCard()
        .padding()
        .astaraBackground()
}
