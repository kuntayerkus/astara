import SwiftUI

enum AstaraButtonStyle {
    case primary
    case secondary
    case ghost
}

struct AstaraButton: View {
    let title: String
    let style: AstaraButtonStyle
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    Text(title)
                        .font(AstaraTypography.labelLarge)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(textColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            .overlay(borderOverlay)
        }
        .buttonStyle(AstaraSpringButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var textColor: Color {
        switch style {
        case .primary: AstaraColors.backgroundStart
        case .secondary: AstaraColors.gold
        case .ghost: AstaraColors.gold
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [AstaraColors.gold, AstaraColors.goldLight],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            Color.clear
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                .stroke(AstaraColors.gold, lineWidth: 1.5)
        case .ghost:
            EmptyView()
        }
    }
}

struct AstaraSpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: AstaraSpacing.md) {
        AstaraButton(title: "Continue", style: .primary) {}
        AstaraButton(title: "Skip", style: .secondary) {}
        AstaraButton(title: "Maybe Later", style: .ghost) {}
        AstaraButton(title: "Loading...", style: .primary, isLoading: true) {}
    }
    .padding()
    .astaraBackground()
}
