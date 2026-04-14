import SwiftUI

struct OracleSphereView: View {
    var isThinking: Bool
    
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var pulsation: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background ambient glow
            Circle()
                .fill(AstaraColors.gold.opacity(isThinking ? 0.4 : 0.15))
                .frame(width: 140, height: 140)
                .blur(radius: isThinking ? 40 : 25)
                .scaleEffect(pulsation)
            
            // Core energy layer 1
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            AstaraColors.gold,
                            AstaraColors.goldLight,
                            AstaraColors.fire.opacity(0.8),
                            AstaraColors.gold
                        ]),
                        center: .center
                    )
                )
                .frame(width: isThinking ? 110 : 90, height: isThinking ? 110 : 90)
                .blur(radius: 12)
                .rotationEffect(.degrees(rotation1))
                .blendMode(.screen)
                .scaleEffect(pulsation)
            
            // Core energy layer 2 (reverse rotation)
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            AstaraColors.goldLight,
                            Color.white.opacity(0.8),
                            AstaraColors.gold.opacity(0.5),
                            AstaraColors.goldLight
                        ]),
                        center: .center
                    )
                )
                .frame(width: isThinking ? 90 : 70, height: isThinking ? 90 : 70)
                .blur(radius: 8)
                .rotationEffect(.degrees(rotation2))
                .blendMode(.plusLighter)
                .scaleEffect(pulsation * 1.05)
            
            // Central star
            if !isThinking {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation2 = -360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulsation = 1.15
            }
        }
        .onChange(of: isThinking) { _, newValue in
            if newValue {
                Haptics.selection()
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulsation = 1.3
                }
            } else {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulsation = 1.15
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 50) {
            OracleSphereView(isThinking: false)
            OracleSphereView(isThinking: true)
        }
    }
}
