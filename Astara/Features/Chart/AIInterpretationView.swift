import SwiftUI

struct AIInterpretationView: View {
    let chart: BirthChart
    var isPremium: Bool = false
    var onGoPremium: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var interpretation: String? = nil

    var body: some View {
        ZStack {
            GradientBackground()
            StarfieldView(starCount: 40).opacity(0.15)

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AstaraSpacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: AstaraSpacing.xs) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(AstaraColors.gold)
                                    Text(String(localized: "ai_chart_reading"))
                                        .font(AstaraTypography.titleLarge)
                                        .foregroundStyle(AstaraColors.textPrimary)
                                }
                                Text(String(localized: "ai_powered_by_gemini"))
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(AstaraColors.textTertiary)
                            }
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AstaraColors.textTertiary)
                            }
                        }

                        if !isPremium {
                            PremiumLockOverlay(
                                title: String(localized: "ai_premium_title"),
                                subtitle: String(localized: "ai_premium_body")
                            ) {
                                onGoPremium?()
                            }
                            .frame(height: 280)
                        } else if isGenerating {
                            VStack(spacing: AstaraSpacing.md) {
                                VStack(spacing: AstaraSpacing.sm) {
                                    ForEach(0..<6, id: \.self) { i in
                                        ShimmerView()
                                            .frame(height: i == 0 ? 18 : 13)
                                            .frame(maxWidth: i % 3 == 2 ? 180 : .infinity)
                                    }
                                }
                                Text(String(localized: "ai_reading_stars"))
                                    .font(AstaraTypography.bodySmall)
                                    .foregroundStyle(AstaraColors.gold.opacity(0.7))
                                    .italic()
                                    .multilineTextAlignment(.center)
                            }
                            .padding(AstaraSpacing.md)
                            .astaraCard()
                        } else if let text = interpretation {
                            VStack(alignment: .leading, spacing: AstaraSpacing.md) {
                                Text(text)
                                    .font(AstaraTypography.bodyMedium)
                                    .foregroundStyle(AstaraColors.textSecondary)
                                    .lineSpacing(6)

                                Text(String(localized: "ai_v2_note"))
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(AstaraColors.textTertiary)
                                    .italic()
                            }
                            .padding(AstaraSpacing.md)
                            .astaraCard()
                        } else {
                            VStack(spacing: AstaraSpacing.md) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AstaraColors.gold.opacity(0.6))
                                Text(String(localized: "ai_generate_prompt"))
                                    .font(AstaraTypography.bodyMedium)
                                    .foregroundStyle(AstaraColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                AstaraButton(title: String(localized: "ai_generate_button"), style: .primary) {
                                    generateInterpretation()
                                }
                            }
                            .padding(AstaraSpacing.xl)
                            .astaraCard()
                        }
                    }
                    .padding(.horizontal, AstaraSpacing.lg)
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func generateInterpretation() {
        isGenerating = true
        // v1: local placeholder. Real Gemini integration ships in v2.
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run {
                interpretation = String(localized: "ai_interpretation_v1_placeholder")
                isGenerating = false
            }
        }
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            AIInterpretationView(chart: .preview, isPremium: true)
        }
}
