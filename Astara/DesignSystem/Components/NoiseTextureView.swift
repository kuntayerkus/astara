import SwiftUI

/// Subtle film-grain noise overlay that adds tactile depth to backgrounds.
/// Layer this above gradient backgrounds at 2–4 % opacity with .overlay blend.
struct NoiseTextureView: View {
    var opacity: Double = 0.035
    var blendMode: BlendMode = .overlay

    var body: some View {
        Canvas { context, size in
            // Deterministic pseudo-random grain using a simple LCG
            var seed: UInt64 = 1234567891
            func nextRand() -> Double {
                seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Double(seed >> 33) / Double(UInt64(1) << 31)
            }

            let tileSize: CGFloat = 1.5
            let cols = Int(size.width / tileSize) + 1
            let rows = Int(size.height / tileSize) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let brightness = nextRand()
                    let alpha = nextRand() * opacity
                    let color = Color(white: brightness, opacity: alpha)
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .blendMode(blendMode)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

extension View {
    /// Adds a subtle noise grain over this view for premium material depth.
    func noiseOverlay(opacity: Double = 0.035) -> some View {
        self.overlay(
            NoiseTextureView(opacity: opacity)
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "#0d0a14").ignoresSafeArea()
        NoiseTextureView(opacity: 0.06)
    }
}
