import WidgetKit
import SwiftUI

// MARK: - Small / Free Tier Widget
//
// Shown to everyone. Compact glance at today's sun-sign context — greeting,
// energy bar, daily theme phrase, lucky color dot. No premium-gated content.
// Tapping deep-links to the daily tab.

struct DailyEnergyWidget: Widget {
    let kind = "com.getastara.app.widget.dailyenergy"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstaraTimelineProvider()) { entry in
            DailyEnergyWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    AstaraWidgetGradient()
                }
                .widgetURL(URL(string: "astara://daily"))
        }
        .configurationDisplayName("Astara")
        .description("Bugünün enerjisi ve tema")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyEnergyWidgetView: View {
    let entry: AstaraEntry

    private var sign: ZodiacSign {
        ZodiacSign(rawValue: entry.snapshot.sunSignRawValue) ?? .leo
    }

    private var locale: String { entry.snapshot.localePrefix }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1 — burç sembolü + isim
            HStack(spacing: 6) {
                Text(sign.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(AstaraColors.gold)
                Text(WidgetStrings.greeting(for: sign, locale: locale))
                    .font(AstaraTypography.labelMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Spacer(minLength: 0)
                if let hex = entry.snapshot.luckyColorHex {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(AstaraColors.cardBorder, lineWidth: 0.5)
                        )
                }
            }

            Spacer(minLength: 0)

            // Büyük enerji sayısı
            Text("%\(entry.snapshot.energy)")
                .font(.custom("CormorantGaramond-SemiBold", size: 40))
                .foregroundStyle(AstaraColors.goldLight)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Enerji bar
            EnergyBar(value: entry.snapshot.energy)
                .frame(height: 4)

            // Tema chip
            if !entry.snapshot.theme.isEmpty {
                Text(entry.snapshot.theme)
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Shared widget components

struct AstaraWidgetGradient: View {
    var body: some View {
        LinearGradient(
            colors: [AstaraColors.backgroundDeep, AstaraColors.backgroundMid, AstaraColors.backgroundWarm],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct EnergyBar: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AstaraColors.cardBackground)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AstaraColors.goldDark, AstaraColors.gold, AstaraColors.goldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(max(0, min(100, value))) / 100)
            }
        }
    }
}

#Preview(as: .systemSmall) {
    DailyEnergyWidget()
} timeline: {
    AstaraEntry(date: .now, snapshot: AstaraEntry.placeholderSnapshot, isPlaceholder: false)
}
