import SwiftUI
import ComposableArchitecture

/// Friends feature entry screen. Lists accepted friends with their daily energy badges
/// and surfaces pending incoming requests at the top.
struct FriendsListView: View {
    @Bindable var store: StoreOf<FriendsFeature>

    var body: some View {
        ZStack {
            GradientBackground()
            content
        }
        .navigationTitle("Arkadaşlar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    store.send(.showShareQR(true))
                } label: {
                    Image(systemName: "qrcode")
                }
                Button {
                    store.send(.showAddSheet(true))
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.showAddSheet },
                set: { store.send(.showAddSheet($0)) }
            )
        ) {
            AddFriendView(store: store)
        }
        .sheet(
            isPresented: Binding(
                get: { store.showQRScanner },
                set: { store.send(.showQRScanner($0)) }
            )
        ) {
            qrScannerSheet
        }
        .sheet(
            isPresented: Binding(
                get: { store.showShareQR },
                set: { store.send(.showShareQR($0)) }
            )
        ) {
            ShareMyQRView()
        }
        .sheet(
            isPresented: Binding(
                get: { store.selectedFriendHandle != nil },
                set: { if !$0 { store.send(.selectFriend(handle: nil)) } }
            )
        ) {
            if let handle = store.selectedFriendHandle,
               let friend = store.friends.first(where: { $0.handle == handle }) {
                FriendProfileView(friend: friend, energy: store.energies[friend.friendId])
            }
        }
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if !store.isConfigured {
            notConfiguredState
        } else if store.isLoading && store.friends.isEmpty {
            ProgressView().tint(AstaraColors.gold)
        } else if let error = store.loadError, store.friends.isEmpty {
            errorState(error)
        } else if store.friends.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !pendingIncoming.isEmpty {
                        section(title: "Bekleyen İstekler") {
                            ForEach(pendingIncoming) { friend in
                                pendingRequestRow(friend)
                            }
                        }
                    }
                    if !acceptedFriends.isEmpty {
                        section(title: "Arkadaşların") {
                            ForEach(acceptedFriends) { friend in
                                friendRow(friend)
                            }
                        }
                    }
                    if !pendingOutgoing.isEmpty {
                        section(title: "Gönderdiğin İstekler") {
                            ForEach(pendingOutgoing) { friend in
                                outgoingRequestRow(friend)
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                store.send(.onAppear)
            }
        }
    }

    private var acceptedFriends: [FriendProfile] {
        store.friends.filter { $0.status == .accepted }
    }

    private var pendingIncoming: [FriendProfile] {
        store.friends.filter { $0.status == .pending && !$0.isOutgoing }
    }

    private var pendingOutgoing: [FriendProfile] {
        store.friends.filter { $0.status == .pending && $0.isOutgoing }
    }

    // MARK: - Rows

    private func friendRow(_ friend: FriendProfile) -> some View {
        Button {
            store.send(.selectFriend(handle: friend.handle))
        } label: {
            HStack(spacing: 14) {
                avatar(for: friend.handle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(friend.handle)")
                        .font(AstaraTypography.labelLarge)
                        .foregroundStyle(AstaraColors.textPrimary)
                    if let energy = store.energies[friend.friendId] {
                        Text("Bugün %\(energy.energy) • \(energy.theme ?? "—")")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textSecondary)
                    } else {
                        Text("Enerji henüz paylaşılmadı")
                            .font(AstaraTypography.caption)
                            .foregroundStyle(AstaraColors.textTertiary)
                    }
                }
                Spacer()
                if let energy = store.energies[friend.friendId] {
                    energyBadge(energy.energy)
                }
            }
            .padding()
            .modifier(AstaraCardModifier())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Arkadaşlıktan Çıkar", role: .destructive) {
                store.send(.unfriend(friendshipId: friend.id))
            }
        }
    }

    private func pendingRequestRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: 14) {
            avatar(for: friend.handle)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(friend.handle)")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("Seninle bağlantı kurmak istiyor")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
            Spacer()
            Button("Kabul") {
                store.send(.acceptRequest(id: friend.id))
            }
            .buttonStyle(.borderedProminent)
            .tint(AstaraColors.gold)
            Button {
                store.send(.declineRequest(id: friend.id))
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.bordered)
            .tint(AstaraColors.textSecondary)
        }
        .padding()
        .modifier(AstaraCardModifier())
    }

    private func outgoingRequestRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: 14) {
            avatar(for: friend.handle)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(friend.handle)")
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("Bekleniyor…")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textTertiary)
            }
            Spacer()
            Button("İptal", role: .destructive) {
                store.send(.unfriend(friendshipId: friend.id))
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .modifier(AstaraCardModifier())
    }

    // MARK: - Helpers

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textSecondary)
            content()
        }
    }

    private func avatar(for handle: String) -> some View {
        Circle()
            .fill(LinearGradient(
                colors: [AstaraColors.goldLight, AstaraColors.goldDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 44, height: 44)
            .overlay(
                Text(handle.prefix(1).uppercased())
                    .font(AstaraTypography.titleMedium)
                    .foregroundStyle(.black.opacity(0.7))
            )
    }

    private func energyBadge(_ value: Int) -> some View {
        Text("%\(value)")
            .font(AstaraTypography.labelMedium)
            .foregroundStyle(AstaraColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(AstaraColors.gold.opacity(0.2))
            )
            .overlay(
                Capsule().stroke(AstaraColors.gold.opacity(0.4), lineWidth: 1)
            )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(AstaraColors.gold)
            Text("Henüz arkadaşın yok")
                .font(AstaraTypography.titleLarge)
                .foregroundStyle(AstaraColors.textPrimary)
            Text("QR kodunu paylaş veya kullanıcı adı ile arkadaş ekle")
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                store.send(.showAddSheet(true))
            } label: {
                Label("Arkadaş Ekle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(AstaraColors.gold)
        }
        .padding()
    }

    private var notConfiguredState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 40))
                .foregroundStyle(AstaraColors.textTertiary)
            Text("Arkadaş sistemi yakında")
                .font(AstaraTypography.titleMedium)
                .foregroundStyle(AstaraColors.textPrimary)
            Text("Bu özellik v2.0 ile birlikte aktifleşecek.")
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(message)
                .font(AstaraTypography.bodySmall)
                .foregroundStyle(AstaraColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Tekrar Dene") { store.send(.onAppear) }
                .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - QR Scanner sheet

    @ViewBuilder
    private var qrScannerSheet: some View {
        #if canImport(AVFoundation) && canImport(UIKit)
        QRScannerView { url in
            store.send(.showQRScanner(false))
            if let handle = QRCodeUtil.handle(from: url) {
                store.send(.resolveHandle(handle))
            }
        } onUnavailable: {
            store.send(.showQRScanner(false))
        }
        .ignoresSafeArea()
        #else
        Text("Kamera bu cihazda kullanılamıyor.")
            .padding()
        #endif
    }
}
