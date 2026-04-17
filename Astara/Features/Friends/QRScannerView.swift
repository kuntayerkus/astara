import SwiftUI
#if canImport(UIKit) && canImport(AVFoundation)
import UIKit
import AVFoundation

/// Lightweight live-camera QR scanner.
///
/// Usage:
///     QRScannerView { url in
///         // Routed through AppFeature.handleDeepLink
///     }
///
/// The parent is responsible for presenting this inside a sheet and for
/// handling the dismissal once a code is captured.
struct QRScannerView: UIViewControllerRepresentable {

    /// Called once, on the main thread, with the first decoded URL that
    /// resolves to an `astara://` deep link.
    var onScan: (URL) -> Void

    /// Called if the user rejects camera access or the hardware is unavailable.
    var onUnavailable: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onUnavailable: onUnavailable)
    }

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, QRScannerDelegate {
        let onScan: (URL) -> Void
        let onUnavailable: (() -> Void)?
        private var didFire = false

        init(onScan: @escaping (URL) -> Void, onUnavailable: (() -> Void)?) {
            self.onScan = onScan
            self.onUnavailable = onUnavailable
        }

        func scannerDidRead(_ value: String) {
            guard !didFire, let url = URL(string: value), url.scheme?.lowercased() == "astara" else { return }
            didFire = true
            onScan(url)
        }

        func scannerUnavailable() {
            onUnavailable?()
        }
    }
}

// MARK: - UIKit Scanner VC

@MainActor
protocol QRScannerDelegate: AnyObject {
    func scannerDidRead(_ value: String)
    func scannerUnavailable()
}

final class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !session.isRunning else { return }
        // AVCaptureSession.startRunning is blocking; do it off the main thread.
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            delegate?.scannerUnavailable()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            delegate?.scannerUnavailable()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview
    }
}

extension QRScannerViewController: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        delegate?.scannerDidRead(value)
    }
}

#endif
