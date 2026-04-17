import SwiftUI
import ComposableArchitecture

/// Share sheet that renders the current user's friend-invite QR code.
///
/// If the user hasn't claimed a handle yet we surface the claim flow instead —
/// a QR without a handle isn't actionable.
struct ShareMyQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.persistenceClient) private var persistence

    @State private var handle: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                content
            }
            .navigationTitle("QR Kodun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .task {
            let user = await persistence.loadUser()
            handle = user?.handle
            isLoading = false
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView().tint(AstaraColors.gold)
        } else if let handle, let url = QRCodeUtil.friendInviteURL(handle: handle) {
            VStack(spacing: 24) {
                #if canImport(UIKit)
                if let image = QRCodeUtil.generate(payload: url.absoluteString, size: 260) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 6)
                }
                #endif
                Text("@\(handle)")
                    .font(AstaraTypography.titleLarge)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("Arkadaşın bu kodu taratsın, otomatik olarak sana istek gönderilsin.")
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                ShareLink(item: url) {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AstaraColors.gold)
            }
            .padding()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(AstaraColors.gold)
                Text("Henüz kullanıcı adın yok")
                    .font(AstaraTypography.titleMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("Arkadaşlarla bağlantı kurmak için önce bir kullanıcı adı seç.")
                    .font(AstaraTypography.bodyMedium)
                    .foregroundStyle(AstaraColors.textSecondary)
                    .multilineTextAlignment(.center)
                NavigationLink("Kullanıcı Adı Al") {
                    ClaimHandleView()
                }
                .buttonStyle(.borderedProminent)
                .tint(AstaraColors.gold)
            }
            .padding()
        }
    }
}
