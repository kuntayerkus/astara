import WidgetKit
import SwiftUI

// MARK: - Large / Premium Tier Widget
//
// Full daily context card: element, energy, theme, ritual tip, retro banner,
// last-updated hint. Same premium gating as the medium widget — non-premium
// users see the paywall placeholder.

struct CosmicOverviewWidget: Widget {
    let kind = "com.getastara.app.widget.cosmicoverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstaraTimelineProvider()) { entry in
            CosmicOverviewWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    AstaraWidgetGradient()
                }
                .widgetURL(URL(string: entry.snapshot.isPremium ? "astara://daily" : "astara://profile/subscription"))
        }
        .configurationDisplayName("Astara — Tam Panorama")
        .description("Günün tüm astro katmanları (Premium)")
        .supportedFamilies([.systemLarge])
    }
}

struct CosmicOverviewWidgetView: View {
    let entry: AstaraEntry

    var body: some View {
        if entry.snapshot.isPremium {
            PremiumLargeContent(entry: entry)
        } else {
            PremiumGateView(locale: entry.snapshot.localePrefix)
        }
    }
}

private struct PremiumLargeContent: View {
    let entry: AstaraEntry

    private var sign: ZodiacSign {
        ZodiacSign(rawValue: entry.snapshot.sunSignRawValue) ?? .leo
    }

    private var locale: String { entry.snapshot.localePrefix }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header — burç + today label + son güncelleme
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(WidgetStrings.todayLabel(locale: locale).uppercased())
                        .font(AstaraTypography.sectionMark)
                        .tracking(1.4)
                        .foregroundStyle(AstaraColors.gold)
                    HStack(spacing: 8) {
                        Text(sign.symbol)
                            .font(.system(size: 26))
                            .foregroundStyle(AstaraColors.goldLight)
                        Text(WidgetStrings.greeting(for: sign, locale: locale))
                            .font(AstaraTypography.titleLarge)
                            .foregroundStyle(AstaraColors.textPrimary)
                    }
                }
                Spacer()
                if let hex = entry.snapshot.luckyColorHex {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle().stroke(AstaraColors.cardBorder, lineWidth: 0.75)
                            )
                        Text(locale == "tr" ? "şans" : "luck")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                    }
                }
            }

            Divider()
                .overlay(AstaraColors.cardBorder)

            // Enerji satırı
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(WidgetStrings.energyLabel(locale: locale))
                        .font(AstaraTypography.labelMedium)
                        .foregroundStyle(AstaraColors.textSecondary)
                    Spacer()
                    Text("%\(entry.snapshot.energy)")
                        .font(.custom("CormorantGaramond-SemiBold", size: 34))
                        .foregroundStyle(AstaraColors.goldLight)
                }
                EnergyBar(value: entry.snapshot.energy)
                    .frame(height: 5)
            }

            // Tema
            sectionBlock(
                label: WidgetStrings.themeLabel(locale: locale),
                body: entry.snapshot.theme,
                accent: AstaraColors.starlight
            )

            // Ritüel
            if let tip = entry.snapshot.tip, !tip.isEmpty {
                sectionBlock(
                    label: WidgetStrings.ritualLabel(locale: locale),
                    body: tip,
                    accent: AstaraColors.gold
                )
            }

            // Retro
            if let retro = entry.snapshot.retroBanner, !retro.isEmpty {
                sectionBlock(
                    label: WidgetStrings.retroLabel(locale: locale),
                    body: retro,
                    accent: AstaraColors.ember400
                )
            }

            Spacer(minLength: 0)

            Text(WidgetStrings.updatedAt(entry.snapshot.updatedAt, locale: locale))
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
        }
    }

    @ViewBuilder
    private func sectionBlock(label: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(AstaraTypography.sectionMark)
                .tracking(1.2)
                .foregroundStyle(accent)
            Text(body)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
                .lineLimit(3)
        }
    }
}

#Preview(as: .systemLarge) {
    CosmicOverviewWidget()
} timeline: {
    AstaraEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            sunSignRawValue: ZodiacSign.virgo.rawValue,
            energy: 78,
            theme: "netlik ve düzen",
            luckyColorHex: "#C9A96E",
            tip: "Masanı topla; sabah çayı ile üç dakika sessizlik.",
            retroBanner: "Merkür retrosu — önemli mesajları iki kez oku.",
            isPremium: true,
            localePrefix: "tr",
            updatedAt: .now
        ),
        isPlaceholder: false
    )
}
