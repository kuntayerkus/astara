import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let speed: Double
}

struct StarfieldView: View {
    let starCount: Int
    @State private var stars: [Star] = []
    @State private var phase: Double = 0

    init(starCount: Int = 80) {
        self.starCount = starCount
    }

    var body: some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = (sin(phase * star.speed + star.opacity * 10) + 1) / 2
                let alpha = star.opacity * (0.3 + 0.7 * twinkle)

                let rect = CGRect(
                    x: star.position.x * size.width,
                    y: star.position.y * size.height,
                    width: star.size,
                    height: star.size
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateStars()
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    private func generateStars() {
        stars = (0..<starCount).map { _ in
            Star(
                position: CGPoint(
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...1)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...1.0),
                speed: Double.random(in: 0.5...2.0)
            )
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        StarfieldView()
    }
}
