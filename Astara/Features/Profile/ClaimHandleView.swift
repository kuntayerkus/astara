import SwiftUI
import ComposableArchitecture

/// Handle claim screen. Shown in onboarding (optional) and from Profile → "Kullanıcı adı al".
/// Validates locally, debounced availability check hits Supabase.
struct ClaimHandleView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.supabase) private var supabase
    @Dependency(\.persistenceClient) private var persistence

    @State private var handle: String = ""
    @State private var state: CheckState = .idle
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var checkTask: Task<Void, Never>?

    private enum CheckState: Equatable {
        case idle
        case checking
        case available
        case taken
        case invalid
    }

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(alignment: .leading, spacing: 20) {
                Text("Kullanıcı Adını Seç")
                    .font(AstaraTypography.displayMedium)
                    .foregroundStyle(AstaraColors.textPrimary)
                Text("3-20 karakter, küçük harf + rakam + alt çizgi. Sonradan değiştirmek zor.")
                    .font(AstaraTypography.bodySmall)
                    .foregroundStyle(AstaraColors.textSecondary)

                HStack {
                    Text("@").foregroundStyle(AstaraColors.textTertiary)
                    TextField("kullaniciadi", text: $handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(AstaraColors.textPrimary)
                        .onChange(of: handle) { _, newValue in
                            scheduleCheck(for: newValue)
                        }
                }
                .padding()
                .modifier(AstaraCardModifier())

                statusRow

                if let errorMessage {
                    Text(errorMessage)
                        .font(AstaraTypography.bodySmall)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button(action: submit) {
                    if isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        Text("Onayla")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AstaraColors.gold)
                .disabled(state != .available || isSubmitting)
            }
            .padding()
        }
        .navigationTitle("Kullanıcı Adı")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var statusRow: some View {
        switch state {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(AstaraColors.gold)
                Text("Kontrol ediliyor…")
                    .font(AstaraTypography.caption)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
        case .available:
            Label("@\(normalized) uygun", systemImage: "checkmark.circle.fill")
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(AstaraColors.sage400)
        case .taken:
            Label("Bu kullanıcı adı alınmış", systemImage: "xmark.circle.fill")
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(.orange)
        case .invalid:
            Label("Geçersiz format", systemImage: "exclamationmark.circle.fill")
                .font(AstaraTypography.labelMedium)
                .foregroundStyle(.orange)
        }
    }

    private var normalized: String {
        handle.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private func scheduleCheck(for raw: String) {
        let value = raw.trimmingCharacters(in: .whitespaces).lowercased()
        checkTask?.cancel()
        errorMessage = nil

        guard !value.isEmpty else {
            state = .idle
            return
        }
        guard AstaraSupabase.isHandleValid(value) else {
            state = .invalid
            return
        }

        state = .checking
        checkTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            do {
                let available = try await supabase.checkHandleAvailable(value)
                guard !Task.isCancelled, value == normalized else { return }
                state = available ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                state = .idle
            }
        }
    }

    private func submit() {
        let target = normalized
        guard state == .available else { return }
        isSubmitting = true
        Task {
            do {
                try await supabase.claimHandle(target)
                await persistence.setHandle(target)
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
                state = .idle
            }
        }
    }
}
