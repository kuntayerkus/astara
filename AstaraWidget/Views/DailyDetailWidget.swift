import WidgetKit
import SwiftUI

// MARK: - Medium / Premium Tier Widget
//
// Expands the free widget: adds ritual tip + retrograde banner. Non-premium
// users see a paywall placeholder instead, deep-linking to the subscription
// screen. Premium status is read from the ``WidgetSnapshot`` the host app wrote
// — no StoreKit or Keychain lookup inside the widget extension.

struct DailyDetailWidget: Widget {
    let kind = "com.getastara.app.widget.dailydetail"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstaraTimelineProvider()) { entry in
            DailyDetailWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    AstaraWidgetGradient()
                }
                .widgetURL(URL(string: entry.snapshot.isPremium ? "astara://daily" : "astara://profile/subscription"))
        }
        .configurationDisplayName("Astara — Detay")
        .description("Ritüel ve retro ipucu (Premium)")
        .supportedFamilies([.systemMedium])
    }
}

struct DailyDetailWidgetView: View {
    let entry: AstaraEntry

    var body: some View {
        if entry.snapshot.isPremium {
            PremiumMediumContent(entry: entry)
        } else {
            PremiumGateView(locale: entry.snapshot.localePrefix)
        }
    }
}

private struct PremiumMediumContent: View {
    let entry: AstaraEntry

    private var sign: ZodiacSign {
        ZodiacSign(rawValue: entry.snapshot.sunSignRawValue) ?? .leo
    }

    private var locale: String { entry.snapshot.localePrefix }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Sol panel — enerji + tema
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(sign.symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(AstaraColors.gold)
                    Text(WidgetStrings.greeting(for: sign, locale: locale))
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.textPrimary)
                }

                Text("%\(entry.snapshot.energy)")
                    .font(.custom("CormorantGaramond-SemiBold", size: 38))
                    .foregroundStyle(AstaraColors.goldLight)
                    .lineLimit(1)

                EnergyBar(value: entry.snapshot.energy)
                    .frame(height: 4)

                Text(entry.snapshot.theme)
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sağ panel — ritüel / retro
            VStack(alignment: .leading, spacing: 10) {
                if let retro = entry.snapshot.retroBanner, !retro.isEmpty {
                    InfoRow(
                        label: WidgetStrings.retroLabel(locale: locale),
                        content: retro,
                        accent: AstaraColors.ember400
                    )
                }

                if let tip = entry.snapshot.tip, !tip.isEmpty {
                    InfoRow(
                        label: WidgetStrings.ritualLabel(locale: locale),
                        content: tip,
                        accent: AstaraColors.gold
                    )
                }

                Spacer(minLength: 0)

                Text(WidgetStrings.updatedAt(entry.snapshot.updatedAt, locale: locale))
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let content: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(AstaraTypography.sectionMark)
                .tracking(1.2)
                .foregroundStyle(accent)
            Text(content)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textPrimary)
                .lineLimit(3)
        }
    }
}

// MARK: - Premium Paywall Placeholder

struct PremiumGateView: View {
    let locale: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(AstaraColors.gold)

            Text(WidgetStrings.premiumGateTitle(locale: locale))
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)

            Text(WidgetStrings.premiumGateBody(locale: locale))
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemMedium) {
    DailyDetailWidget()
} timeline: {
    AstaraEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            sunSignRawValue: ZodiacSign.scorpio.rawValue,
            energy: 64,
            theme: "denge",
            luckyColorHex: "#C9A96E",
            tip: "Bir bardak su iç, üç derin nefes al.",
            retroBanner: "Merkür retrosu — önemli mesajları iki kez oku.",
            isPremium: true,
            localePrefix: "tr",
            updatedAt: .now
        ),
        isPlaceholder: false
    )
}
