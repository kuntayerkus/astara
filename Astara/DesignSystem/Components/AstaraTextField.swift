import SwiftUI

struct AstaraTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: promptText)
            .font(AstaraTypography.bodyLarge)
            .foregroundStyle(AstaraColors.textPrimary)
            .focused($isFocused)
            .padding(.horizontal, AstaraSpacing.md)
            .frame(height: 52)
            .background(AstaraColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                    .stroke(
                        isFocused ? AstaraColors.gold : AstaraColors.cardBorder,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var promptText: Text {
        Text(placeholder)
            .foregroundStyle(AstaraColors.textTertiary)
    }
}

#Preview {
    VStack(spacing: AstaraSpacing.md) {
        AstaraTextField(placeholder: "Search city...", text: .constant(""))
        AstaraTextField(placeholder: "Search city...", text: .constant("Istanbul"))
    }
    .padding()
    .astaraBackground()
}
