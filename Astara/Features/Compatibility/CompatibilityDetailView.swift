import SwiftUI

struct CompatibilityDetailView: View {
    let compatibility: Compatibility
    var isPremium: Bool = false
    var onGoPremium: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AstaraColors.cardBorder)
                    .frame(width: 40, height: 5)
                    .padding(.top, AstaraSpacing.md)
                    .padding(.bottom, AstaraSpacing.lg)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AstaraSpacing.lg) {
                        // Pair header
                        pairHeader

                        // Score rings row
                        scoreRingsRow

                        // Description + Category (premium-gated)
                        if isPremium {
                            descriptionCard
                            categoryBreakdown
                        } else {
                            ZStack(alignment: .bottom) {
                                VStack(spacing: AstaraSpacing.lg) {
                                    descriptionCard
                                    categoryBreakdown
                                }
                                .blur(radius: 8)
                                .allowsHitTesting(false)

                                PremiumLockOverlay(
                                    title: String(localized: "compatibility_premium_title"),
                                    subtitle: String(localized: "compatibility_premium_body")
                                ) {
                                    onGoPremium?()
                                }
                                .frame(minHeight: 240)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusLg))
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

    private var pairHeader: some View {
        SynastryOrbitView(
            sign1: compatibility.sign1,
            sign2: compatibility.sign2,
            score: compatibility.overallScore
        )
    }

    // MARK: - Score Rings

    private var scoreRingsRow: some View {
        HStack(spacing: AstaraSpacing.lg) {
            scoreRingItem(score: compatibility.loveScore, label: String(localized: "love"), icon: "heart.fill", color: AstaraColors.fire)
            scoreRingItem(score: compatibility.friendshipScore, label: String(localized: "friendship"), icon: "person.2.fill", color: AstaraColors.mist400)
            scoreRingItem(score: compatibility.workScore, label: String(localized: "work"), icon: "briefcase.fill", color: AstaraColors.sage400)
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func scoreRingItem(score: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color.opacity(0.7))

            ScoreRingView(score: score, label: label, size: 72)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Description

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "compatibility_analysis"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.gold)
                .tracking(1)
                .textCase(.uppercase)

            Text(compatibility.description)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .lineSpacing(5)
        }
        .padding(AstaraSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .astaraCard()
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.md) {
            Text(String(localized: "score_breakdown"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            scoreBar(label: String(localized: "love"), score: compatibility.loveScore, color: AstaraColors.fire)
            scoreBar(label: String(localized: "friendship"), score: compatibility.friendshipScore, color: AstaraColors.mist400)
            scoreBar(label: String(localized: "work"), score: compatibility.workScore, color: AstaraColors.sage400)
        }
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    private func scoreBar(label: String, score: Int, color: Color) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Text(label)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AstaraColors.cardBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                        .animation(.easeOut(duration: 0.8), value: score)
                }
            }
            .frame(height: 8)

            Text("\(score)")
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            CompatibilityDetailView(compatibility: .preview)
        }
}
