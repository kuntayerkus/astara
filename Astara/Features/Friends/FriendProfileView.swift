import SwiftUI

/// Friend profile sheet — handle, daily energy, and a CTA hook into synastry
/// (Feature 3 Partners). Synastry integration is soft-linked: we just emit a
/// deep link intent that the Compatibility tab can pick up later.
struct FriendProfileView: View {
    let friend: FriendProfile
    let energy: DailyEnergyDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        energyCard
                        synastryCTA
                    }
                    .padding()
                }
            }
            .navigationTitle("@\(friend.handle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [AstaraColors.goldLight, AstaraColors.goldDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 96, height: 96)
                .overlay(
                    Text(friend.handle.prefix(1).uppercased())
                        .font(AstaraTypography.displayMedium)
                        .foregroundStyle(.black.opacity(0.7))
                )
            Text("@\(friend.handle)")
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            Text(statusText)
                .font(AstaraTypography.caption)
                .foregroundStyle(AstaraColors.textSecondary)
        }
        .padding(.top, 20)
    }

    private var statusText: String {
        switch friend.status {
        case .accepted:
            if let acceptedAt = friend.acceptedAt {
                return "Arkadaş oldunuz: \(AstaraDateFormatters.displayDate.string(from: acceptedAt))"
            }
            return "Arkadaşsınız"
        case .pending: return friend.isOutgoing ? "İstek bekleniyor" : "Seninle bağlantı kurmak istiyor"
        case .blocked: return "Engellendi"
        }
    }

    @ViewBuilder
    private var energyCard: some View {
        if let energy {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Bugünkü Enerji")
                        .font(AstaraTypography.titleMedium)
                        .foregroundStyle(AstaraColors.textPrimary)
                    Spacer()
                    Text("%\(energy.energy)")
                        .font(AstaraTypography.displayMedium)
                        .foregroundStyle(AstaraColors.gold)
                }
                if let theme = energy.theme {
                    Text(theme)
                        .font(AstaraTypography.bodyMedium)
                        .foregroundStyle(AstaraColors.textSecondary)
                }
            }
            .padding()
            .modifier(AstaraCardModifier())
        } else {
            Text("Bu kullanıcı henüz bugünkü enerjisini paylaşmadı.")
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textTertiary)
                .padding()
                .modifier(AstaraCardModifier())
        }
    }

    @ViewBuilder
    private var synastryCTA: some View {
        if friend.status == .accepted {
            Button {
                // Soft hook — Compatibility tab picks this up via shared state
                // in a future iteration. For now we just dismiss.
                dismiss()
            } label: {
                Label("Synastry Hesapla", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AstaraColors.gold)
        }
    }
}
