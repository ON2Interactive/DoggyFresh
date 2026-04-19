import Photos
import UIKit

enum ImageSaver {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized else {
            throw SaveError.notAuthorized
        }

        guard let data = image.jpegData(compressionQuality: 1.0) else {
            throw SaveError.imageConversionFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }
    }

    enum SaveError: LocalizedError {
        case imageConversionFailed
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image"
            case .notAuthorized:
                return "Photo library access not granted"
            }
        }
    }
}
