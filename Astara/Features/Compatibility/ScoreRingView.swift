import SwiftUI

struct ScoreRingView: View {
    let score: Int
    let label: String
    var size: CGFloat = 80
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(AstaraColors.cardBorder, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.5), value: score)

            VStack(spacing: 1) {
                Text("\(score)")
                    .font(.custom("CormorantGaramond-Bold", size: size * 0.28))
                    .foregroundStyle(AstaraColors.textPrimary)

                Text(label)
                    .font(.system(size: size * 0.12))
                    .foregroundStyle(AstaraColors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
    }

    private var scoreColor: Color {
        switch score {
        case 0..<40: AstaraColors.fire
        case 40..<60: AstaraColors.ember400
        case 60..<80: AstaraColors.gold
        default: AstaraColors.sage400
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ScoreRingView(score: 88, label: "Genel", size: 100)
        ScoreRingView(score: 62, label: "Aşk", size: 80)
        ScoreRingView(score: 45, label: "İş", size: 60)
    }
    .padding()
    .astaraBackground()
}
