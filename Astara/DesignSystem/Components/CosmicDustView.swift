import SwiftUI

/// A highly optimized particle system creating floating cosmos dust.
struct CosmicDustView: View {
    @State private var dustParticles = CosmicDustView.generateParticles(count: 40)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<dustParticles.count, id: \.self) { index in
                    Circle()
                        .fill(dustParticles[index].color.opacity(dustParticles[index].opacity))
                        .frame(width: dustParticles[index].size, height: dustParticles[index].size)
                        .position(
                            x: dustParticles[index].x * geometry.size.width,
                            y: dustParticles[index].y * geometry.size.height
                        )
                        .blur(radius: dustParticles[index].size / 3)
                        .animation(
                            Animation.linear(duration: dustParticles[index].speed)
                                .repeatForever(autoreverses: false),
                            value: dustParticles[index].y
                        )
                }
            }
            .onAppear {
                // Trigger floating animation
                for index in 0..<dustParticles.count {
                    dustParticles[index].y = -0.2 // Float upwards
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    struct Particle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
        var color: Color
    }
    
    static func generateParticles(count: Int) -> [Particle] {
        return (0..<count).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0.2...1.2), // Start slightly below screen
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.6),
                speed: Double.random(in: 15...40),
                color: [.white, .yellow, AstaraColors.goldLight, .cyan].randomElement()!
            )
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CosmicDustView()
    }
    .ignoresSafeArea()
}
