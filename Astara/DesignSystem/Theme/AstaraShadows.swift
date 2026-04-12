import SwiftUI

enum AstaraShadows {
    // MARK: - Card Shadow
    static func card<V: View>(_ content: V) -> some View {
        content.shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    // MARK: - Glow Effect (gold)
    static func glow<V: View>(_ content: V, color: Color = AstaraColors.gold, radius: CGFloat = 20) -> some View {
        content.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }

    // MARK: - Subtle Shadow
    static func subtle<V: View>(_ content: V) -> some View {
        content.shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
    }
}
