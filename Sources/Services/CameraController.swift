import AVFoundation
import CoreImage
import CoreMedia
import Foundation
import UIKit

/// 背面カメラの映像を配信する。プレビューは AVCaptureVideoPreviewLayer が描き、
/// このクラスは「いま届いている 1 枚」を保持して、停止と保存に使う。
final class CameraController: NSObject, ObservableObject {
    enum Status: Equatable {
        case idle
        case running
        case denied
        case unavailable
    }

    @Published private(set) var status: Status = .idle
    /// 映像の大きさ（縦持ちに回したあと）。枠の割り付けに使う。
    @Published private(set) var videoSize: CGSize = .zero

    let session = AVCaptureSession()

    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.shodai4.compositiongridcam.session")
    private let videoQueue = DispatchQueue(label: "com.shodai4.compositiongridcam.video",
                                           qos: .userInitiated)
    private let lock = NSLock()
    private var latestBuffer: CVPixelBuffer?
    private var reportedSize: CGSize = .zero
    private var isConfigured = false
    private var configurationFailed = false
    private lazy var context = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: 起動と停止

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            prepareAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.prepareAndRun()
                    } else {
                        self.status = .denied
                    }
                }
            }
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .denied
        }
    }

    /// 設定アプリから戻ったときなど、権限の変化を拾い直す。
    func refresh() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            prepareAndRun()
        case .denied, .restricted:
            if status != .denied { status = .denied }
            stop()
        case .notDetermined:
            start()
        @unknown default:
            break
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func prepareAndRun() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                guard !self.configurationFailed else { return }
                guard self.configureSession() else {
                    self.configurationFailed = true
                    DispatchQueue.main.async { self.status = .unavailable }
                    return
                }
                self.isConfigured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                self.status = self.session.isRunning ? .running : .unavailable
            }
        }
    }

    private func configureSession() -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.canSetSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video) else {
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return false }
            session.addInput(input)
        } catch {
            return false
        }

        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { return false }
        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            // 縦持ちの画面に合わせて、映像をあらかじめ回して受け取る。
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }

        applyDefaults(to: device)
        return true
    }

    private func applyDefaults(to device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            device.unlockForConfiguration()
        } catch {
            // 設定できなくても映像は出る。
        }
    }

    // MARK: 1 枚の取り出し

    /// いま届いている 1 枚。停止（フリーズ）と保存に使う。
    func latestImage() -> CGImage? {
        lock.lock()
        let buffer = latestBuffer
        lock.unlock()
        guard let buffer else { return nil }
        let image = CIImage(cvPixelBuffer: buffer)
        return context.createCGImage(image, from: image.extent)
    }

    /// 映像が届いているか。
    var hasImage: Bool {
        lock.lock()
        let exists = latestBuffer != nil
        lock.unlock()
        return exists
    }
}

// MARK: - フレームの受け取り

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lock.lock()
        latestBuffer = buffer
        lock.unlock()

        let width = CGFloat(CVPixelBufferGetWidth(buffer))
        let height = CGFloat(CVPixelBufferGetHeight(buffer))
        lock.lock()
        let known = reportedSize
        lock.unlock()
        guard known.width != width || known.height != height else { return }
        lock.lock()
        reportedSize = CGSize(width: width, height: height)
        lock.unlock()
        DispatchQueue.main.async {
            self.videoSize = CGSize(width: width, height: height)
        }
    }
}
