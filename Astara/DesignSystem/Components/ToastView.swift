import SwiftUI

enum ToastType {
    case success
    case error
    case info

    var color: Color {
        switch self {
        case .success: AstaraColors.sage400
        case .error: AstaraColors.fire
        case .info: AstaraColors.gold
        }
    }

    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: AstaraSpacing.sm) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)

            Text(message)
                .font(AstaraTypography.bodyMedium)
                .foregroundStyle(AstaraColors.textPrimary)
        }
        .padding(.horizontal, AstaraSpacing.md)
        .padding(.vertical, AstaraSpacing.sm)
        .astaraCard(cornerRadius: AstaraSpacing.cornerRadiusMd)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastType

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                ToastView(message: message, type: type)
                    .padding(.top, AstaraSpacing.xl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { isPresented = false }
                        }
                    }
            }
        }
        .animation(.spring(duration: 0.4), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, type: ToastType = .info) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}

#Preview {
    VStack(spacing: AstaraSpacing.md) {
        ToastView(message: "Chart calculated successfully", type: .success)
        ToastView(message: "Network error occurred", type: .error)
        ToastView(message: "Mercury retrograde starts tomorrow", type: .info)
    }
    .padding()
    .astaraBackground()
}
