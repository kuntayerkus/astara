import SwiftUI

struct RetroAlertBanner: View {
    let activeRetrogrades: [Retrograde]
    let upcomingRetrogrades: [Retrograde]
    @State private var glowPulsing = false
    @State private var isExpanded = false

    // Backwards-compatible init (for previews passing a single list)
    init(retrogrades: [Retrograde]) {
        self.activeRetrogrades = retrogrades.filter { $0.isActive }
        self.upcomingRetrogrades = retrogrades.filter { $0.isFuture }
    }

    init(activeRetrogrades: [Retrograde], upcomingRetrogrades: [Retrograde]) {
        self.activeRetrogrades = activeRetrogrades
        self.upcomingRetrogrades = upcomingRetrogrades
    }

    var body: some View {
        VStack(spacing: AstaraSpacing.xs) {
            // Aktif retrolar
            ForEach(activeRetrogrades) { retro in
                activeRetroRow(retro: retro)
            }

            // Yaklaşan retrolar — açılır liste
            if !upcomingRetrogrades.isEmpty {
                upcomingSection
            }
        }
        .onAppear { glowPulsing = true }
    }

    // MARK: - Aktif Retro Satırı

    private func activeRetroRow(retro: Retrograde) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AstaraColors.ember400)
                .symbolEffect(.pulse)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(retro.planet.turkishName) \(String(localized: "retro_active"))")
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text("\(retro.startDate) – \(retro.endDate)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()
        }
        .padding(AstaraSpacing.md)
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                .stroke(
                    AstaraColors.ember400.opacity(glowPulsing ? 0.5 : 0.12),
                    lineWidth: 1
                )
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowPulsing)
        )
    }

    // MARK: - Yaklaşan Retrolar Bölümü

    private var upcomingSection: some View {
        VStack(spacing: 0) {
            // Başlık / toggle butonu
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AstaraSpacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundStyle(AstaraColors.gold.opacity(0.7))

                    Text(String(localized: "upcoming_retrogrades"))
                        .font(AstaraTypography.labelMedium)
                        .foregroundStyle(AstaraColors.textSecondary)

                    Spacer()

                    Text("\(upcomingRetrogrades.count)")
                        .font(AstaraTypography.caption)
                        .foregroundStyle(AstaraColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AstaraColors.cardBackground)
                        .clipShape(Capsule())

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(AstaraColors.textTertiary)
                }
                .padding(AstaraSpacing.md)
            }
            .buttonStyle(.plain)

            // Açılır liste
            if isExpanded {
                Divider()
                    .background(AstaraColors.cardBorder)

                VStack(spacing: 0) {
                    ForEach(Array(upcomingRetrogrades.enumerated()), id: \.element.id) { index, retro in
                        upcomingRetroRow(retro: retro)

                        if index < upcomingRetrogrades.count - 1 {
                            Divider()
                                .background(AstaraColors.cardBorder)
                                .padding(.leading, AstaraSpacing.xxl + AstaraSpacing.sm)
                        }
                    }
                }
            }
        }
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AstaraSpacing.cornerRadiusMd)
                .stroke(AstaraColors.gold.opacity(0.15), lineWidth: 1)
        )
    }

    private func upcomingRetroRow(retro: Retrograde) -> some View {
        HStack(spacing: AstaraSpacing.sm) {
            Text(retro.planet.symbol)
                .font(.system(size: 16))
                .foregroundStyle(AstaraColors.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(retro.planet.turkishName)
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)

                Text("\(retro.startDate) – \(retro.endDate)")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, AstaraSpacing.md)
        .padding(.vertical, AstaraSpacing.sm)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        RetroAlertBanner(
            activeRetrogrades: [.preview],
            upcomingRetrogrades: [
                Retrograde(planet: .venus, startDate: "2026-06-01", endDate: "2026-06-25"),
                Retrograde(planet: .saturn, startDate: "2026-07-13", endDate: "2026-11-28")
            ]
        )
        .padding()
    }
}
