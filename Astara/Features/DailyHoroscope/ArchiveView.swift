import SwiftUI

struct ArchiveView: View {
    let sign: ZodiacSign
    var onGoPremium: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    // Archive is a premium placeholder for now; structure is ready for v2
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: AstaraSpacing.lg) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AstaraSpacing.xxs) {
                        Text(String(localized: "archive_title"))
                            .font(AstaraTypography.titleLarge)
                            .foregroundStyle(AstaraColors.textPrimary)

                        Text("\(sign.symbol) \(sign.turkishName)")
                            .font(AstaraTypography.bodySmall)
                            .foregroundStyle(AstaraColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AstaraColors.textTertiary)
                    }
                }
                .padding(.horizontal, AstaraSpacing.lg)

                // Premium gate
                VStack(spacing: AstaraSpacing.md) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AstaraColors.gold.opacity(0.4))

                    Text(String(localized: "archive_premium_title"))
                        .font(AstaraTypography.titleMedium)
                        .foregroundStyle(AstaraColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "archive_premium_body"))
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(AstaraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AstaraSpacing.xl)

                    AstaraButton(title: String(localized: "go_premium"), style: .primary) {
                        onGoPremium?()
                        dismiss()
                    }
                    .padding(.horizontal, AstaraSpacing.xl)
                    .padding(.top, AstaraSpacing.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ArchiveView(sign: .pisces)
        }
}
