import SwiftUI
import ComposableArchitecture

/// Sheet — handle-search + QR scan entry points for adding a friend.
struct AddFriendView: View {
    @Bindable var store: StoreOf<FriendsFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                VStack(alignment: .leading, spacing: 20) {
                    searchField

                    HStack {
                        Button {
                            dismiss()
                            store.send(.showQRScanner(true))
                        } label: {
                            Label("QR Tara", systemImage: "qrcode.viewfinder")
                        }
                        .buttonStyle(.bordered)
                        .tint(AstaraColors.gold)

                        Spacer()
                    }

                    if store.isSearching {
                        ProgressView().tint(AstaraColors.gold)
                    } else if let error = store.searchError {
                        Text(error)
                            .font(AstaraTypography.bodySmall)
                            .foregroundStyle(.orange)
                    } else if store.searchResults.isEmpty && store.searchQuery.count >= 2 {
                        Text("Bu kullanıcı adına sahip kimse bulunamadı")
                            .font(AstaraTypography.bodySmall)
                            .foregroundStyle(AstaraColors.textSecondary)
                    }

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(store.searchResults) { result in
                                row(result)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Arkadaş Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AstaraColors.textTertiary)
            TextField(
                "@kullaniciadi",
                text: Binding(
                    get: { store.searchQuery },
                    set: { store.send(.searchQueryChanged($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(AstaraColors.textPrimary)
        }
        .padding()
        .modifier(AstaraCardModifier())
    }

    private func row(_ profile: PublicProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(profile.handle)")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text(profile.locale.uppercased())
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            Spacer()
            Button("Ekle") {
                store.send(.sendFriendRequest(targetId: profile.id))
            }
            .buttonStyle(.borderedProminent)
            .tint(AstaraColors.gold)
        }
        .padding()
        .modifier(AstaraCardModifier())
    }
}
