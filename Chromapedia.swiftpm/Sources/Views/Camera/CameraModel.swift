import AVFoundation
import SwiftUI

enum CameraPermission { case undetermined, granted, denied }

struct DetectedColorInfo {
    let color: Color
    let hex: String
    let rgb: RGBValues
    let closestMatch: ColorItem
    static let initial = DetectedColorInfo(
        color: Color(hex: "#808080"), hex: "#808080",
        rgb: RGBValues(r: 128, g: 128, b: 128),
        closestMatch: ColorData.all[0]
    )
}

@MainActor
final class CameraModel: NSObject, ObservableObject {
    @Published var permission: CameraPermission = .undetermined
    @Published var detected: DetectedColorInfo = .initial
    @Published var isRunning = false

    nonisolated(unsafe) let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)

    private let bufferLock = NSLock()
    private nonisolated(unsafe) var _latestBuffer: CVPixelBuffer?

    private var sampleTimer: Timer?

    // EMA smoothing prevents jittery color readouts
    private var smoothR: Double = 128
    private var smoothG: Double = 128
    private var smoothB: Double = 128
    private let emaAlpha: Double = 0.4
    private let updateThreshold: Double = 2.5
    private let sampleRadius: Int = 20

    override init() { super.init(); checkPermission() }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: permission = .granted
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { self?.permission = granted ? .granted : .denied }
            }
        default: permission = .denied
        }
    }

    func start() {
        guard permission == .granted else { return }
        sessionQueue.async { [weak self] in
            self?.configureSession()
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isRunning = true }
        }
        startSampling()
    }

    func stop() {
        sampleTimer?.invalidate(); sampleTimer = nil
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }

    private nonisolated func configureSession() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .medium
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { session.commitConfiguration(); return }
        session.addInput(input)

        try? device.lockForConfiguration()
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        device.unlockForConfiguration()

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
    }

    private func startSampling() {
        sampleTimer?.invalidate()
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.sampleCenterRegion() }
        }
    }

    private func grabBuffer() -> CVPixelBuffer? {
        bufferLock.lock()
        let buf = _latestBuffer
        bufferLock.unlock()
        return buf
    }

    // samples a 40×40 center patch for stable color detection
    private func sampleCenterRegion() {
        guard let buffer = grabBuffer() else { return }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        let width  = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bpr    = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }

        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let cx = width / 2, cy = height / 2
        var totalR = 0, totalG = 0, totalB = 0, count = 0

        for dy in -sampleRadius...sampleRadius {
            for dx in -sampleRadius...sampleRadius {
                let px = cx + dx, py = cy + dy
                guard px >= 0, px < width, py >= 0, py < height else { continue }
                let off = py * bpr + px * 4
                // BGRA byte order
                totalB += Int(ptr[off])
                totalG += Int(ptr[off + 1])
                totalR += Int(ptr[off + 2])
                count += 1
            }
        }
        guard count > 0 else { return }

        let rawR = Double(totalR) / Double(count)
        let rawG = Double(totalG) / Double(count)
        let rawB = Double(totalB) / Double(count)

        smoothR = smoothR * (1 - emaAlpha) + rawR * emaAlpha
        smoothG = smoothG * (1 - emaAlpha) + rawG * emaAlpha
        smoothB = smoothB * (1 - emaAlpha) + rawB * emaAlpha

        let finalR = Int(smoothR.rounded())
        let finalG = Int(smoothG.rounded())
        let finalB = Int(smoothB.rounded())

        let dr = Double(finalR) - Double(detected.rgb.r)
        let dg = Double(finalG) - Double(detected.rgb.g)
        let db = Double(finalB) - Double(detected.rgb.b)
        let dist = sqrt(dr*dr + dg*dg + db*db)
        guard dist >= updateThreshold else { return }

        updateDetected(r: finalR, g: finalG, b: finalB)
    }

    private func updateDetected(r: Int, g: Int, b: Int) {
        let cr = max(0, min(255, r)), cg = max(0, min(255, g)), cb = max(0, min(255, b))
        let color = Color(red: Double(cr)/255, green: Double(cg)/255, blue: Double(cb)/255)
        detected = DetectedColorInfo(
            color: color,
            hex: ColorMath.rgbToHex(r: cr, g: cg, b: cb),
            rgb: RGBValues(r: cr, g: cg, b: cb),
            closestMatch: ColorMath.findClosestColor(r: cr, g: cg, b: cb)
        )
    }
}

extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.lock()
        _latestBuffer = buffer
        bufferLock.unlock()
    }
}
