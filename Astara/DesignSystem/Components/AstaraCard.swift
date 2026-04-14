import SwiftUI

struct AstaraCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg
    var tappable: Bool = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                AstaraColors.cardBorder,
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AstaraColors.goldLight.opacity(tappable && isPressed ? 0.3 : 0), lineWidth: 1.5)
            )
            .shadow(color: AstaraColors.gold.opacity(tappable && isPressed ? 0.15 : 0), radius: tappable && isPressed ? 12 : 0)
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .scaleEffect(tappable && isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            ._onButtonGesture { pressing in
                if tappable {
                    isPressed = pressing
                    if pressing { Haptics.selection() }
                }
            } perform: {}
    }
}

extension View {
    func astaraCard(cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg, tappable: Bool = false) -> some View {
        modifier(AstaraCardModifier(cornerRadius: cornerRadius, tappable: tappable))
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
