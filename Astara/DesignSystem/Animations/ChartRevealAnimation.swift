import SwiftUI

struct ChartRevealAnimation: View {
    @State private var progress: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var rotation: Double = -30

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AstaraColors.gold.opacity(0.6),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Inner ring
            Circle()
                .trim(from: 0, to: max(0, progress - 0.1))
                .stroke(
                    AstaraColors.gold.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                .padding(20)
                .rotationEffect(.degrees(-90))

            // Zodiac sign placeholders around the wheel
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30.0 - 90.0
                let signProgress = Double(index) / 12.0

                Text(ZodiacSign.allCases[index].symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(AstaraColors.gold)
                    .opacity(progress > signProgress ? 1 : 0)
                    .offset(
                        x: cos(angle * .pi / 180) * 120,
                        y: sin(angle * .pi / 180) * 120
                    )
            }

            // Center glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AstaraColors.gold.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .opacity(glowOpacity)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                progress = 1.0
                rotation = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(1.8)) {
                glowOpacity = 1.0
            }
        }
    }
}

#Preview {
    ChartRevealAnimation()
        .frame(width: 300, height: 300)
        .astaraBackground()
}
