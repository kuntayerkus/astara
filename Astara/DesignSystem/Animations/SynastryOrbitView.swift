import SwiftUI

struct SynastryOrbitView: View {
    let sign1: ZodiacSign
    let sign2: ZodiacSign
    let score: Int
    
    @State private var rotation: Double = 0
    @State private var pulseOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: AstaraSpacing.lg) {
            ZStack {
                // Background Orbit Rings
                Circle()
                    .stroke(AstaraColors.gold.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-rotation / 2))
                
                Circle()
                    .stroke(AstaraColors.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 100, height: 100)
                
                // Central connecting line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AstaraColors.gold.opacity(0), AstaraColors.gold.opacity(pulseOpacity * 2), AstaraColors.gold.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 140, height: 1)
                    .rotationEffect(.degrees(rotation))
                
                // Center Score Pulse
                ZStack {
                    Circle()
                        .fill(AstaraColors.gold.opacity(pulseOpacity))
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                    
                    Text("\(score)")
                        .font(.custom("CormorantGaramond-Bold", size: 28))
                        .foregroundStyle(.white)
                }
                
                // Sign 1 (Orbiting)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 40, height: 40)
                    Circle()
                        .stroke(AstaraColors.cardBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)
                    Text(sign1.symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(AstaraColors.gold)
                }
                .offset(x: -70)
                .rotationEffect(.degrees(rotation))
                
                // Sign 2 (Orbiting Opposite)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 40, height: 40)
                    Circle()
                        .stroke(AstaraColors.cardBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)
                    Text(sign2.symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(AstaraColors.gold)
                }
                .offset(x: 70)
                .rotationEffect(.degrees(rotation))
            }
            .frame(height: 180)
            .onAppear {
                // Orbit speed depends on the score (higher score = faster smoother orbit, lower score = slow distant orbit)
                withAnimation(.linear(duration: Double(110 - score) / 5.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseOpacity = Double(score) / 100.0 * 0.7
                }
            }
            
            // Name Labels
            HStack {
                Text(sign1.turkishName)
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textSecondary)
                
                Spacer()
                
                Text(String(localized: "overall"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Text(sign2.turkishName)
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
            .padding(.horizontal, AstaraSpacing.md)
        }
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }
}

#Preview {
    ZStack {
        GradientBackground()
        VStack {
            SynastryOrbitView(sign1: .aries, sign2: .libra, score: 92)
            SynastryOrbitView(sign1: .taurus, sign2: .aquarius, score: 45)
        }
        .padding()
    }
}
