// swiftlint:disable all
#if DEBUG
import SwiftUI

struct DebugPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var retroJSON: String = "Yükleniyor..."
    @State private var energyJSON: String = "Yükleniyor..."
    @State private var retrogrades: [DebugRetrograde] = []
    @State private var energyValues: [String: Double] = [:]
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🛠 Debug Paneli")
                            .font(AstaraTypography.titleLarge)
                            .foregroundStyle(AstaraColors.gold)
                        Text("Sadece DEBUG modunda görünür")
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
                .padding(AstaraSpacing.lg)

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Retrolar").tag(0)
                    Text("Element").tag(1)
                    Text("API").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AstaraSpacing.lg)
                .padding(.bottom, AstaraSpacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AstaraSpacing.md) {
                        switch selectedTab {
                        case 0: retroTab
                        case 1: energyTab
                        default: apiTab
                        }
                    }
                    .padding(AstaraSpacing.lg)
                    .padding(.bottom, AstaraSpacing.xxxl)
                }
            }
        }
        .task { await fetchAll() }
    }

    // MARK: - Retro Tab

    private var retroTab: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Retro Takvimi")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            if retrogrades.isEmpty {
                Text(retroJSON)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AstaraColors.textSecondary)
                    .padding(AstaraSpacing.sm)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(retrogrades) { retro in
                    HStack(alignment: .top, spacing: AstaraSpacing.sm) {
                        Circle()
                            .fill(retro.isActive ? AstaraColors.ember400 : AstaraColors.sage400)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(retro.planet)
                                    .font(AstaraTypography.labelMedium)
                                    .foregroundStyle(AstaraColors.textPrimary)
                                Spacer()
                                Text(retro.isActive ? "AKTİF" : "pasif")
                                    .font(AstaraTypography.caption)
                                    .foregroundStyle(retro.isActive ? AstaraColors.ember400 : AstaraColors.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((retro.isActive ? AstaraColors.ember400 : AstaraColors.textTertiary).opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            Text("\(retro.start) → \(retro.end)")
                                .font(AstaraTypography.caption)
                                .foregroundStyle(AstaraColors.textTertiary)
                        }
                    }
                    .padding(AstaraSpacing.sm)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Text("Ham JSON:")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
                .padding(.top, AstaraSpacing.sm)

            Text(retroJSON)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(AstaraColors.textSecondary.opacity(0.7))
                .padding(AstaraSpacing.sm)
                .background(AstaraColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Energy Tab

    private var energyTab: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            Text("Element Enerjisi")
                .font(AstaraTypography.labelLarge)
                .foregroundStyle(AstaraColors.textPrimary)

            if !energyValues.isEmpty {
                ForEach(["fire", "earth", "air", "water"], id: \.self) { key in
                    let raw = energyValues[key] ?? 0
                    HStack {
                        Text(key.capitalized)
                            .font(AstaraTypography.labelMedium)
                            .foregroundStyle(AstaraColors.textPrimary)
                            .frame(width: 60, alignment: .leading)
                        Text("Ham: \(raw, specifier: "%.4f")")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                        Spacer()
                        Text("→ \(Int(raw <= 1.0 ? raw * 100 : raw))%")
                            .font(AstaraTypography.labelMedium)
                            .foregroundStyle(AstaraColors.gold)
                    }
                    .padding(AstaraSpacing.sm)
                    .background(AstaraColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text("Not: Eğer değerler 0-1 aralığındaysa ×100 uygulanmalı.")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.ember400)
                    .padding(.top, AstaraSpacing.xxs)
            }

            Text("Ham JSON:")
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
                .padding(.top, AstaraSpacing.sm)

            Text(energyJSON)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(AstaraColors.textSecondary.opacity(0.7))
                .padding(AstaraSpacing.sm)
                .background(AstaraColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - API Tab

    private var apiTab: some View {
        VStack(alignment: .leading, spacing: AstaraSpacing.sm) {
            debugRow(label: "Environment", value: "#if DEBUG → staging")
            debugRow(label: "Base URL", value: APIEnvironment.current.baseURL.absoluteString)
            debugRow(label: "Static Data URL", value: APIEnvironment.current.staticDataURL.absoluteString)
            debugRow(label: "VPS URL", value: APIEnvironment.current.vpsURL.absoluteString)
            debugRow(label: "Bugün", value: {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return f.string(from: Date())
            }())
        }
    }

    private func debugRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textTertiary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AstaraColors.gold)
        }
        .padding(AstaraSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AstaraColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Fetch

    private func fetchAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchRetro() }
            group.addTask { await self.fetchEnergy() }
        }
    }

    private func fetchRetro() async {
        let url = APIEnvironment.current.staticDataURL.appendingPathComponent("/data/retro-calendar.json")
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            await MainActor.run { retroJSON = "Fetch hatası: \(url)" }
            return
        }
        let raw = String(data: data, encoding: .utf8) ?? "decode hatası"
        await MainActor.run { retroJSON = raw }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let entries = json["retrogrades"] as? [[String: Any]] {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            let parsed = entries.compactMap { entry -> DebugRetrograde? in
                guard let planet = entry["planet"] as? String,
                      let start = entry["start"] as? String,
                      let end = entry["end"] as? String else { return nil }
                let startDate = formatter.date(from: start)
                let endDate = formatter.date(from: end)
                let active: Bool
                if let s = startDate, let e = endDate {
                    active = today >= s && today <= e
                } else {
                    active = false
                }
                return DebugRetrograde(planet: planet, start: start, end: end, isActive: active)
            }
            await MainActor.run { retrogrades = parsed }
        }
    }

    private func fetchEnergy() async {
        let url = APIEnvironment.current.staticDataURL.appendingPathComponent("/data/daily-energy.json")
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            await MainActor.run { energyJSON = "Fetch hatası: \(url)" }
            return
        }
        let raw = String(data: data, encoding: .utf8) ?? "decode hatası"
        await MainActor.run { energyJSON = raw }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let elements = json["elements"] as? [String: Any] {
            var values: [String: Double] = [:]
            for key in ["fire", "earth", "air", "water"] {
                if let entry = elements[key] as? [String: Any] {
                    values[key] = (entry["level"] as? Double) ?? Double(entry["level"] as? Int ?? 0)
                }
            }
            await MainActor.run { energyValues = values }
        }
    }
}

struct DebugRetrograde: Identifiable {
    let id = UUID()
    let planet: String
    let start: String
    let end: String
    let isActive: Bool
}

#Preview {
    DebugPanelView()
}
#endif
