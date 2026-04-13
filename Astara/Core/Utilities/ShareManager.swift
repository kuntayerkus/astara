import SwiftUI
import UIKit

enum ShareManager {
    /// Present a share sheet with the given items
    static func share(_ items: [Any], sourceView: UIView? = nil) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Exclude types that don't fit astrology content
        controller.excludedActivityTypes = [.addToReadingList, .assignToContact, .print]

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            // iPad popover support
            if let popover = controller.popoverPresentationController {
                popover.sourceView = sourceView ?? root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            root.present(controller, animated: true)
        }
    }

    /// Render a SwiftUI view as an image for sharing (screenshot-friendly card)
    @MainActor
    static func renderAsImage<V: View>(_ view: V, size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    /// Share a SwiftUI view as an image with Astara watermark text
    @MainActor
    static func shareAsImage<V: View>(_ view: V, size: CGSize = CGSize(width: 1080, height: 1920)) {
        guard let image = renderAsImage(view, size: size) else { return }
        share([image])
    }
}
