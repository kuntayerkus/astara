import SwiftUI

struct ChartRevealAnimation: View {
    @State private var progress: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var rotation: Double = -60
    
    // New Magical Properties
    @State private var supernovaScale: CGFloat = 0.1
    @State private var supernovaOpacity: Double = 0.0
    @State private var particleExpansion: CGFloat = 0.0
    
    // Reduce particle count on thermally constrained devices (A13 / older)
    private static let particleCount: Int = {
        switch ProcessInfo.processInfo.thermalState {
        case .serious, .critical: return 16
        default: return 40
        }
    }()

    // Generate static random positions for particles
    let particles: [(Double, Double, Double)] = (0..<ChartRevealAnimation.particleCount).map { _ in
        (Double.random(in: 0...360), Double.random(in: 0.3...1.0), Double.random(in: 20...160))
    }

    var body: some View {
        ZStack {
            // Supernova Burst
            Circle()
                .fill(AstaraColors.goldLight)
                .frame(width: 100, height: 100)
                .scaleEffect(supernovaScale)
                .opacity(supernovaOpacity)
                .blur(radius: 20)
            
            // Stardust particles
            ZStack {
                ForEach(0..<particles.count, id: \.self) { i in
                    let p = particles[i]
                    Circle()
                        .fill(AstaraColors.gold)
                        .frame(width: 2, height: 2)
                        .opacity(p.1 * glowOpacity)
                        .offset(x: cos(p.0 * .pi / 180) * (p.2 + Double(particleExpansion)),
                                y: sin(p.0 * .pi / 180) * (p.2 + Double(particleExpansion)))
                }
            }
            .rotationEffect(.degrees(rotation * 1.5))
            
            // Outer ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AstaraColors.gold.opacity(0.8),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .padding(10)
                .rotationEffect(.degrees(-90))

            // Inner ring
            Circle()
                .trim(from: 0, to: max(0, progress - 0.1))
                .stroke(
                    AstaraColors.gold.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1)
                )
                .padding(30)
                .rotationEffect(.degrees(-90))

            // Zodiac sign placeholders around the wheel
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30.0 - 90.0
                let signProgress = Double(index) / 12.0

                Text(ZodiacSign.allCases[index].symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.gold)
                    .opacity(progress > signProgress ? 1 : 0)
                    .scaleEffect(progress > signProgress ? 1 : 0.2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: progress > signProgress)
                    .offset(
                        x: cos(angle * .pi / 180) * 120,
                        y: sin(angle * .pi / 180) * 120
                    )
            }

            // Center core
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.6), AstaraColors.gold.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 140, height: 140)
                    .opacity(glowOpacity)
                    .scaleEffect(1.0 + (particleExpansion * 0.01))
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(AstaraColors.goldLight)
                    .opacity(glowOpacity)
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            // Supernova initial burst
            withAnimation(.easeOut(duration: 0.8)) {
                supernovaScale = 4.0
                supernovaOpacity = 0.8
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
                supernovaOpacity = 0.0
            }
            
            // Build the rings
            withAnimation(.easeOut(duration: 2.5).delay(0.3)) {
                progress = 1.0
                rotation = 0
            }
            
            // Pulsing core and particles
            withAnimation(.easeIn(duration: 1.0).delay(2.0)) {
                glowOpacity = 1.0
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particleExpansion = 40
            }
        }
    }
}

#Preview {
    ChartRevealAnimation()
        .frame(width: 300, height: 300)
        .astaraBackground()
}
