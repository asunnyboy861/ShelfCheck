import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    @Binding var isContinuous: Bool
    @Binding var isTorchOn: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onScan = onScan
        controller.isContinuous = isContinuous
        controller.isTorchOn = isTorchOn
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.isContinuous = isContinuous
        uiViewController.isTorchOn = isTorchOn
        uiViewController.updateTorch()
    }
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    var isContinuous = false
    var isTorchOn = false {
        didSet { updateTorch() }
    }

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScanTime: Date = .distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showNoCameraAlert()
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        self.captureSession = session

        addScanOverlay()
    }

    private func addScanOverlay() {
        let overlayView = ScanOverlayView(frame: view.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              stringValue.isValidISBN() else { return }

        let now = Date()
        guard now.timeIntervalSince(lastScanTime) > 1.0 else { return }
        lastScanTime = now

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        onScan?(stringValue)

        if !isContinuous {
            stopScanning()
        }
    }

    func updateTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        try? device.setTorchModeOn(level: 1.0)
        device.torchMode = isTorchOn ? .on : .off
        device.unlockForConfiguration()
    }

    private func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func showNoCameraAlert() {
        let label = UILabel()
        label.text = "Camera access is required to scan barcodes.\nPlease enable it in Settings."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)
    }
}

class ScanOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let scanAreaSize: CGFloat = min(rect.width, rect.height) * 0.7
        let scanArea = CGRect(
            x: (rect.width - scanAreaSize) / 2,
            y: (rect.height - scanAreaSize) / 2 - 40,
            width: scanAreaSize,
            height: scanAreaSize * 0.6
        )

        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)

        context.clear(scanArea)

        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3)

        let cornerLength: CGFloat = 30
        let corners: [(CGPoint, CGPoint)] = [
            (scanArea.origin, CGPoint(x: scanArea.origin.x + cornerLength, y: scanArea.origin.y)),
            (scanArea.origin, CGPoint(x: scanArea.origin.x, y: scanArea.origin.y + cornerLength)),
            (CGPoint(x: scanArea.maxX, y: scanArea.minY), CGPoint(x: scanArea.maxX - cornerLength, y: scanArea.minY)),
            (CGPoint(x: scanArea.maxX, y: scanArea.minY), CGPoint(x: scanArea.maxX, y: scanArea.minY + cornerLength)),
            (CGPoint(x: scanArea.minX, y: scanArea.maxY), CGPoint(x: scanArea.minX + cornerLength, y: scanArea.maxY)),
            (CGPoint(x: scanArea.minX, y: scanArea.maxY), CGPoint(x: scanArea.minX, y: scanArea.maxY - cornerLength)),
            (CGPoint(x: scanArea.maxX, y: scanArea.maxY), CGPoint(x: scanArea.maxX - cornerLength, y: scanArea.maxY)),
            (CGPoint(x: scanArea.maxX, y: scanArea.maxY), CGPoint(x: scanArea.maxX, y: scanArea.maxY - cornerLength)),
        ]

        for (from, to) in corners {
            context.move(to: from)
            context.addLine(to: to)
        }
        context.strokePath()
    }
}
