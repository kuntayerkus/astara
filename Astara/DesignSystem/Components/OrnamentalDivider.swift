import SwiftUI

/// Celestial section divider — ── ✦ ── — used between HomeView chapters.
struct OrnamentalDivider: View {
    var glyph: String = "✦"
    var color: Color = AstaraColors.gold
    var opacity: Double = 0.30

    var body: some View {
        HStack(spacing: 10) {
            line
            Text(glyph)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(opacity * 1.4))
            line
        }
        .padding(.horizontal, AstaraSpacing.xl)
    }

    private var line: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0), color.opacity(opacity), color.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

/// Decorative corner ornament for Chronicle cards.
struct CornerOrnament: View {
    var color: Color = AstaraColors.gold
    var size: CGFloat = 12
    var corner: UnitPoint = .topLeading

    var body: some View {
        GeometryReader { geo in
            Text("✦")
                .font(.system(size: size * 0.7))
                .foregroundStyle(color.opacity(0.5))
                .position(
                    x: corner == .topLeading || corner == .bottomLeading ? size : geo.size.width - size,
                    y: corner == .topLeading || corner == .topTrailing ? size : geo.size.height - size
                )
        }
    }
}

/// Ornamental divider with a centred text label: ── ✦ PLANETS ✦ ──
struct OrnamentalDividerTitle: View {
    var title: String
    var color: Color = AstaraColors.gold
    var opacity: Double = 0.30

    var body: some View {
        HStack(spacing: 8) {
            line
            HStack(spacing: 4) {
                Text("✦")
                    .font(.system(size: 8))
                    .foregroundStyle(color.opacity(opacity * 1.4))
                Text(title.uppercased())
                    .font(AstaraTypography.sectionMark)
                    .foregroundStyle(color.opacity(opacity * 1.4))
                    .tracking(2)
                Text("✦")
                    .font(.system(size: 8))
                    .foregroundStyle(color.opacity(opacity * 1.4))
            }
            line
        }
        .padding(.horizontal, AstaraSpacing.xl)
    }

    private var line: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0), color.opacity(opacity), color.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

/// Inline chapter section label: "✦ I · TODAY" style header.
struct ChapterLabel: View {
    var number: String
    var title: String

    var body: some View {
        HStack(spacing: AstaraSpacing.xs) {
            Text("✦")
                .font(.system(size: 8))
                .foregroundStyle(AstaraColors.gold.opacity(0.6))
            Text(number.uppercased())
                .font(AstaraTypography.sectionMark)
                .foregroundStyle(AstaraColors.textTertiary)
                .tracking(2)
            Text("·")
                .font(AstaraTypography.sectionMark)
                .foregroundStyle(AstaraColors.textTertiary.opacity(0.5))
            Text(title.uppercased())
                .font(AstaraTypography.sectionMark)
                .foregroundStyle(AstaraColors.textTertiary)
                .tracking(2)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0d0a14").ignoresSafeArea()
        VStack(spacing: 32) {
            OrnamentalDivider()
            OrnamentalDivider(glyph: "✧", opacity: 0.5)
            ChapterLabel(number: "I", title: "Today")
            ChapterLabel(number: "II", title: "Astara Score")
        }
    }
}
