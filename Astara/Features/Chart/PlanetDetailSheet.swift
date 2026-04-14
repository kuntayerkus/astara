import SwiftUI

struct PlanetDetailSheet: View {
    let chart: BirthChart
    let planetKey: PlanetKey
    var isPremium: Bool = false
    var onGoPremium: (() -> Void)? = nil

    private var planet: Planet? {
        chart.planet(for: planetKey)
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AstaraSpacing.lg) {
                    // Header
                    if let planet {
                        header(planet: planet)
                    }

                    // Position details
                    if let planet {
                        positionCard(planet: planet)
                    }

                    // Aspects
                    let planetAspects = chart.aspects(for: planetKey)
                    if !planetAspects.isEmpty {
                        aspectsCard(aspects: planetAspects)
                    }

                    // AI Interpretation (premium-gated)
                    aiInterpretationSection
                }
                .padding(AstaraSpacing.lg)
            }
        }
    }

    // MARK: - AI Interpretation Section

    private var aiInterpretationSection: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AstaraColors.gold)
                Text(String(localized: "ai_interpretation"))
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Spacer()
                if !isPremium {
                    Text("PREMIUM")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AstaraColors.gold)
                        .clipShape(Capsule())
                }
            }

            if isPremium {
                Text(String(localized: "ai_interpretation_placeholder"))
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .lineSpacing(4)
            } else {
                ZStack {
                    Text(String(localized: "ai_interpretation_placeholder"))
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(AstaraColors.textSecondary)
                        .lineSpacing(4)
                        .blur(radius: 5)
                        .allowsHitTesting(false)

                    Button {
                        Haptics.light()
                        onGoPremium?()
                    } label: {
                        Label(String(localized: "unlock_interpretation"), systemImage: "lock.open.fill")
                            .font(AstaraTypography.labelMedium)
                            .foregroundStyle(AstaraColors.backgroundStart)
                            .padding(.horizontal, AstaraSpacing.md)
                            .padding(.vertical, AstaraSpacing.xs)
                            .background(
                                LinearGradient(
                                    colors: [AstaraColors.gold, AstaraColors.goldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: AstaraColors.gold.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(AstaraSpringButtonStyle())
                }
                .frame(minHeight: 72)
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    // MARK: - Header

    private func header(planet: Planet) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            Text(planet.key.symbol)
                .font(.system(size: 48))
                .foregroundStyle(planet.isRetrograde ? AstaraColors.ember400 : AstaraColors.gold)

            Text(planet.key.turkishName)
                .font(AstaraTypography.displayMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            if planet.isRetrograde {
                HStack(spacing: AstaraSpacing.xxs) {
                    Text("℞")
                    Text(String(localized: "retrograde"))
                }
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.ember400)
            }
        }
    }

    // MARK: - Position Card

    private func positionCard(planet: Planet) -> some View {
        VStack(spacing: AstaraSpacing.sm) {
            detailRow(
                label: String(localized: "sign"),
                value: "\(planet.sign.symbol) \(planet.sign.turkishName)"
            )

            detailRow(
                label: String(localized: "degree"),
                value: planet.formattedDegree
            )

            detailRow(
                label: String(localized: "absolute_degree"),
                value: String(format: "%.2f°", planet.degree)
            )

            if let houseNum = chart.houseForPlanet(planetKey) {
                if let house = chart.house(houseNum) {
                    detailRow(
                        label: String(localized: "house"),
                        value: "\(house.romanNumeral) — \(house.meaning)"
                    )
                }
            }

            detailRow(
                label: String(localized: "element"),
                value: planet.sign.element.localizedName
            )

            detailRow(
                label: String(localized: "modality"),
                value: planet.sign.modality.localizedName
            )
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
            Spacer()
            Text(value)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
        }
    }

    // MARK: - Aspects Card

    private func aspectsCard(aspects: [Aspect]) -> some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text(String(localized: "aspects"))
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            ForEach(aspects) { aspect in
                let otherKey = aspect.planet1 == planetKey ? aspect.planet2 : aspect.planet1
                HStack {
                    Text(aspect.type.symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(aspect.type.isHarmonious ? AstaraColors.sage400 : AstaraColors.fire)
                        .frame(width: 28)

                    Text(otherKey.turkishName)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textPrimary)

                    Spacer()

                    Text(aspect.type.rawValue.capitalized)
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textSecondary)

                    Text(String(format: "%.1f°", aspect.orb))
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(AstaraSpacing.md)
        .astaraCard()
    }
}

#Preview {
    PlanetDetailSheet(chart: .preview, planetKey: .gunes)
}
