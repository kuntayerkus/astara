import SwiftUI

// MARK: - Card Style

enum AstaraCardStyle {
    /// Full-width editorial hero card. Deep gradient background + left gold accent bar.
    case chronicle
    /// Glassmorphism data card (default). Ultra-thin material + gradient border.
    case data
    /// Compact inline card. Transparent background + 1pt hairline border.
    case micro
}

// MARK: - Card Modifier

struct AstaraCardModifier: ViewModifier {
    var style: AstaraCardStyle = .data
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg
    var tappable: Bool = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        if style == .data {
            content
                .astaraLiquidGlass(style: .deep, cornerRadius: effectiveRadius)
                .overlay(border) // Add the extra glow for buttons if needed
                .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
                .scaleEffect(tappable && isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                ._onButtonGesture { pressing in
                    if tappable {
                        isPressed = pressing
                        if pressing { Haptics.impact(.rigid) } // Brutal/crisp tap
                    }
                } perform: {}
        } else {
            content
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: effectiveRadius))
                .overlay(border)
                .overlay(accentBar, alignment: .leading)
                .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
                .scaleEffect(tappable && isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                ._onButtonGesture { pressing in
                    if tappable {
                        isPressed = pressing
                        if pressing { Haptics.impact(.rigid) }
                    }
                } perform: {}
        }
    }

    // MARK: Backgrounds

    @ViewBuilder
    private var background: some View {
        switch style {
        case .chronicle:
            LinearGradient(
                colors: [AstaraColors.chronicleGradientTop, AstaraColors.chronicleGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .data:
            Color.clear
        case .micro:
            Color.clear
        }
    }

    // MARK: Borders

    @ViewBuilder
    private var border: some View {
        switch style {
        case .chronicle:
            RoundedRectangle(cornerRadius: effectiveRadius)
                .stroke(
                    LinearGradient(
                        colors: [AstaraColors.gold.opacity(0.45), AstaraColors.cardBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .data:
            // Sadece buton tıklandığındaki glow efektini tut, ana sınırı astaraLiquidGlass çiziyor
            RoundedRectangle(cornerRadius: effectiveRadius)
                .stroke(Color.clear, lineWidth: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: effectiveRadius)
                        .stroke(AstaraColors.goldLight.opacity(tappable && isPressed ? 0.3 : 0), lineWidth: 1.5)
                )
        case .micro:
            RoundedRectangle(cornerRadius: effectiveRadius)
                .stroke(AstaraColors.cardBorder, lineWidth: 1)
        }
    }

    // MARK: Chronicle accent bar (left edge gold line)

    @ViewBuilder
    private var accentBar: some View {
        if style == .chronicle {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [AstaraColors.gold, AstaraColors.gold.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .padding(.vertical, 8)
        }
    }

    // MARK: Helpers

    private var effectiveRadius: CGFloat {
        style == .micro ? AstaraSpacing.cornerRadiusMd : cornerRadius
    }

    private var shadowColor: Color {
        switch style {
        case .chronicle: return AstaraColors.gold.opacity(tappable && isPressed ? 0.12 : 0.06)
        case .data:      return .black.opacity(0.3)
        case .micro:     return .clear
        }
    }

    private var shadowRadius: CGFloat {
        style == .chronicle ? 20 : 12
    }

    private var shadowY: CGFloat {
        style == .micro ? 0 : 4
    }
}

// MARK: - View Extensions

extension View {
    /// Default glassmorphism data card (original behaviour).
    func astaraCard(cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg, tappable: Bool = false) -> some View {
        modifier(AstaraCardModifier(style: .data, cornerRadius: cornerRadius, tappable: tappable))
    }

    /// Full-width editorial hero card with gold accent bar.
    func chronicleCard(tappable: Bool = false) -> some View {
        modifier(AstaraCardModifier(style: .chronicle, cornerRadius: AstaraSpacing.cornerRadiusXl, tappable: tappable))
    }

    /// Compact borderline card for inline / secondary content.
    func microCard() -> some View {
        modifier(AstaraCardModifier(style: .micro))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Chronicle
            VStack(alignment: .leading, spacing: 8) {
                Text("BUGÜN")
                    .font(AstaraTypography.sectionMark)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .tracking(2)
                Text("Derin sular akıntısı taşır")
                    .font(AstaraTypography.heroLabel)
                    .foregroundStyle(AstaraColors.gold)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .chronicleCard()

            // Data
            Text("Glassmorphism kart")
                .font(AstaraTypography.bodyLarge)
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: .infinity)
                .astaraCard()

            // Micro
            Text("Micro kart")
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .microCard()
        }
        .padding(24)
    }
    .astaraBackground()
}
