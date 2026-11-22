import Photos
import UIKit

/// 写真への追加だけを頼む（読み出しはしない）。
enum PhotoSaver {
    enum Outcome {
        case saved
        case denied
        case failed
    }

    static func save(_ image: UIImage) async -> Outcome {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .denied }
        guard let data = image.jpegData(compressionQuality: 0.95) else { return .failed }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
