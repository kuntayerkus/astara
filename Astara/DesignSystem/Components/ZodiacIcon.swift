import SwiftUI

struct ZodiacIcon: View {
    let sign: ZodiacSign
    var size: CGFloat = AstaraSpacing.iconLg
    var color: Color = AstaraColors.gold

    var body: some View {
        Text(sign.symbol)
            .font(.system(size: size * 0.7))
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: AstaraSpacing.sm) {
        ForEach(ZodiacSign.allCases) { sign in
            ZodiacIcon(sign: sign, size: 32)
        }
    }
    .padding()
    .astaraBackground()
}
