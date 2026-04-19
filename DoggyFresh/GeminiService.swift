import UIKit

enum GeminiService {
    private static let endpoint = URL(string: "https://doggyfresh.cloud/api/generate")!

    static func refreshImage(_ image: UIImage,
                             style: RefreshStyle,
                             dogContext: DogContext,
                             customInstruction: String? = nil) async throws -> UIImage {
        let resized = resizedImage(image, maxDimension: 1024)

        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageConversionFailed
        }

        let requestBody = ProxyRequest(
            imageData: jpegData.base64EncodedString(),
            mimeType: "image/jpeg",
            styleDescription: style.promptDescription,
            dogContext: dogContext,
            customInstruction: customInstruction
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data)
            if httpResponse.statusCode == 422 {
                throw GeminiError.nonAnimalImage
            }
            throw GeminiError.serverError(httpResponse.statusCode, errorResponse?.error)
        }

        let decodedResponse: ProxyResponse
        do {
            decodedResponse = try JSONDecoder().decode(ProxyResponse.self, from: data)
        } catch {
            throw GeminiError.invalidResponse
        }

        guard let imageData = Data(base64Encoded: decodedResponse.imageData),
              let resultImage = UIImage(data: imageData) else {
            throw GeminiError.invalidResponse
        }

        return resultImage
    }

    private static func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    enum GeminiError: LocalizedError {
        case imageConversionFailed
        case nonAnimalImage
        case serverError(Int, String?)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image"
            case .nonAnimalImage:
                return "Please use an animal photo."
            case .serverError(let code, let message):
                if let message, !message.isEmpty {
                    return "Server error (\(code)): \(message)"
                }
                return "Server error (\(code))"
            case .invalidResponse:
                return "Could not parse response"
            }
        }
    }
}

private struct ProxyRequest: Encodable {
    let imageData: String
    let mimeType: String
    let styleDescription: String
    let dogContext: DogContext
    let customInstruction: String?
}

private struct ProxyResponse: Decodable {
    let imageData: String
    let mimeType: String
}

private struct ProxyErrorResponse: Decodable {
    let error: String
}
