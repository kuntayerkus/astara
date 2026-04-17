import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

/// QR code generation + payload helpers for the Astara friend system.
///
/// Payload format mirrors the existing deep link scheme so a scanned QR
/// routes through `AppFeature.handleDeepLink` with zero branching:
///     astara://friend/{handle}
enum QRCodeUtil {

    // MARK: - Payload

    /// Build a canonical friend-invite URL for a given handle.
    /// Returns nil when the handle fails validation (keeps garbage out of QR codes).
    static func friendInviteURL(handle: String) -> URL? {
        let normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard AstaraSupabase.isHandleValid(normalized) else { return nil }
        return URL(string: "astara://friend/\(normalized)")
    }

    /// Extract a handle from any `astara://friend/{handle}` URL. Returns nil otherwise.
    static func handle(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "astara" else { return nil }
        // Host = "friend" OR path starts with "/friend/"
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var segments = url.pathComponents.filter { $0 != "/" }
        if let host = components?.host, !host.isEmpty {
            segments.insert(host, at: 0)
        }
        guard segments.count >= 2, segments[0] == "friend" else { return nil }
        let handle = segments[1].lowercased()
        return AstaraSupabase.isHandleValid(handle) ? handle : nil
    }

    // MARK: - Image Generation

    #if canImport(UIKit)
    /// Generate a QR `UIImage` for the given payload string.
    ///
    /// - Parameters:
    ///   - payload: raw string to encode (typically a `astara://friend/...` URL).
    ///   - size: desired output edge length in points. The filter renders at native
    ///           resolution; we scale up with nearest-neighbour interpolation to keep
    ///           the modules crisp.
    ///   - tint: optional foreground colour. Nil leaves it black-on-white which is the
    ///           most scannable. Pass Astara gold for branded share cards (still scans
    ///           reliably when background is pure white).
    /// - Returns: A UIImage or nil if the filter failed (out of memory, bad payload).
    static func generate(payload: String, size: CGFloat = 240, tint: UIColor? = nil) -> UIImage? {
        guard let data = payload.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M" // Balances density with scan robustness

        guard let ciImage = filter.outputImage else { return nil }

        let scale = size / ciImage.extent.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let finalImage: CIImage
        if let tint {
            let colourFilter = CIFilter.falseColor()
            colourFilter.inputImage = scaled
            colourFilter.color0 = CIColor(color: tint)
            colourFilter.color1 = CIColor(color: .white)
            finalImage = colourFilter.outputImage ?? scaled
        } else {
            finalImage = scaled
        }

        let context = CIContext()
        guard let cgImage = context.createCGImage(finalImage, from: finalImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// Convenience: generate a QR image for a handle (returns nil if handle invalid).
    static func generateForHandle(_ handle: String, size: CGFloat = 240, tint: UIColor? = nil) -> UIImage? {
        guard let url = friendInviteURL(handle: handle) else { return nil }
        return generate(payload: url.absoluteString, size: size, tint: tint)
    }
    #endif
}
