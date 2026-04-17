import SwiftUI

/// Detailed synastry result sheet. Shows score breakdown, dominant themes and
/// the strongest cross-aspects. Handles loading / error / sign-only fallback.
struct SynastryDetailView: View {
    let partner: PartnerDTO
    let synastry: Synastry?
    let isLoading: Bool
    let errorMessage: String?
    let onClose: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(spacing: AstaraSpacing.lg) {
                        header

                        if let message = errorMessage {
                            errorCard(message)
                        } else if isLoading || synastry == nil {
                            loadingCard
                        } else if let synastry {
                            content(synastry)
                        }
                    }
                    .padding(AstaraSpacing.lg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close")) { onClose() }
                        .foregroundStyle(AstaraColors.textSecondary)
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(AstaraColors.fire)
                    }
                }
            }
            .confirmationDialog(
                String(localized: "partner_delete_confirm_title"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "partner_delete_confirm_yes"), role: .destructive) {
                    onDelete()
                }
                Button(String(localized: "cancel"), role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: AstaraSpacing.sm) {
            Text(partner.approximateSunSign.symbol)
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(AstaraColors.gold)
            Text(partner.name)
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(partner.approximateSunSign.localizedName)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textTertiary)

            if partner.birthTimeUnknown {
                Text(String(localized: "partners_fallback_warning"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.ember400)
                    .multilineTextAlignment(.center)
                    .padding(.top, AstaraSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    private var loadingCard: some View {
        VStack(spacing: AstaraSpacing.sm) {
            ProgressView().tint(AstaraColors.gold)
            Text(String(localized: "synastry_loading"))
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.xl)
        .astaraCard()
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(AstaraColors.fire)
            Text(String(localized: "synastry_error_title"))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(message)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    @ViewBuilder
    private func content(_ synastry: Synastry) -> some View {
        scoreCard(synastry)
        if !synastry.dominantThemes.isEmpty {
            themesCard(synastry.dominantThemes)
        }
        if !synastry.crossAspects.isEmpty {
            aspectsCard(synastry.crossAspects)
        }
    }

    private func scoreCard(_ synastry: Synastry) -> some View {
        let c = synastry.compatibility
        return VStack(spacing: AstaraSpacing.md) {
            ScoreRingView(
                score: c.overallScore,
                label: String(localized: "overall"),
                size: 120,
                lineWidth: 8
            )

            if synastry.isSignOnlyFallback {
                Text(String(localized: "synastry_fallback_label"))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.ember400)
                    .tracking(1.5)
                    .textCase(.uppercase)
            }

            HStack(spacing: AstaraSpacing.md) {
                miniScore(score: c.loveScore, label: String(localized: "love"), icon: "heart.fill")
                miniScore(score: c.friendshipScore, label: String(localized: "friendship"), icon: "person.2.fill")
                miniScore(score: c.workScore, label: String(localized: "work"), icon: "briefcase.fill")
            }

            Text(c.description)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, AstaraSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.lg)
        .chronicleCard()
    }

    private func themesCard(_ themes: [String]) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "synastry_themes").uppercased())
                .font(AstaraTypography.caption)
                .tracking(1.5)
                .foregroundStyle(AstaraColors.textTertiary)
            ForEach(themes, id: \.self) { theme in
                HStack(alignment: .top, spacing: AstaraSpacing.xs) {
                    Text("✦")
                        .foregroundStyle(AstaraColors.gold)
                    Text(theme)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    private func aspectsCard(_ aspects: [CrossAspect]) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "synastry_aspects").uppercased())
                .font(AstaraTypography.caption)
                .tracking(1.5)
                .foregroundStyle(AstaraColors.textTertiary)

            // Show top 8 strongest (sorted by strength in SynastryService).
            ForEach(aspects.prefix(8)) { aspect in
                aspectRow(aspect)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AstaraSpacing.lg)
        .astaraCard()
    }

    private func aspectRow(_ aspect: CrossAspect) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Text(aspect.type.symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(aspect.type.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(aspect.userPlanet.turkishName) \u{2194} \(aspect.partnerPlanet.turkishName)")
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("\(String(format: "%.1f", aspect.orb))° orb \u{00B7} \(Int(aspect.strength * 100))%")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func miniScore(score: Int, label: String, icon: String) -> some View {
        VStack(spacing: AstaraSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AstaraColors.textTertiary)
            Text("\(score)")
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(label)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AstaraSpacing.sm)
        .microCard()
    }
}
