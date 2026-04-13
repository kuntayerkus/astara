import SwiftUI
import ComposableArchitecture

struct SignSelectorView: View {
    let selectedSign: ZodiacSign
    let onSelect: (ZodiacSign) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AstaraSpacing.sm) {
                    ForEach(ZodiacSign.allCases) { sign in
                        signChip(sign)
                            .id(sign)
                    }
                }
                .padding(.horizontal, AstaraSpacing.lg)
            }
            .onAppear {
                proxy.scrollTo(selectedSign, anchor: .center)
            }
            .onChange(of: selectedSign) { _, newSign in
                withAnimation {
                    proxy.scrollTo(newSign, anchor: .center)
                }
            }
        }
    }

    private func signChip(_ sign: ZodiacSign) -> some View {
        Button {
            onSelect(sign)
        } label: {
            VStack(spacing: AstaraSpacing.xxs) {
                Text(sign.symbol)
                    .font(.system(size: 20))

                Text(sign.turkishName)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(
                        selectedSign == sign ? AstaraColors.gold : AstaraColors.textTertiary
                    )
            }
            .padding(.vertical, AstaraSpacing.sm)
            .padding(.horizontal, AstaraSpacing.md)
            .background(
                selectedSign == sign
                    ? AstaraColors.gold.opacity(0.12)
                    : AstaraColors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                    .stroke(
                        selectedSign == sign ? AstaraColors.gold.opacity(0.4) : AstaraColors.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SignSelectorView(selectedSign: .pisces) { _ in }
        .astaraBackground()
}
