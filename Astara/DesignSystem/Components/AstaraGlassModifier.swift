import SwiftUI

// Determines if expensive blurs should be disabled to guarantee 60fps on older devices
private var shouldReduceTransparency: Bool {
    UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
}

struct AstaraGlassModifier: ViewModifier {
    var style: GlassStyle = .deep
    var cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg
    var borderOpacity: Double = 0.25
    
    enum GlassStyle {
        case ultra, deep, light
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if shouldReduceTransparency {
                        Color(red: 0.05, green: 0.05, blue: 0.08, opacity: style == .ultra ? 0.95 : 0.85) // Fallback for A13
                    } else {
                        switch style {
                        case .ultra:
                            Color.clear.background(.ultraThinMaterial)
                        case .deep:
                            Color.clear.background(.ultraThinMaterial)
                                .brightness(-0.1)
                        case .light:
                            Color.clear.background(.regularMaterial)
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                AstaraColors.cardBorder,
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    /// Applies Astara's performance-optimized Liquid Glass effect. Gracefully degrades on older hardware or low power state.
    func astaraLiquidGlass(style: AstaraGlassModifier.GlassStyle = .deep, cornerRadius: CGFloat = AstaraSpacing.cornerRadiusLg, borderOpacity: Double = 0.25) -> some View {
        modifier(AstaraGlassModifier(style: style, cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}
