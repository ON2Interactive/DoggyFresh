import UIKit

struct UsageQuota: Codable, Equatable {
    let used: Int
    let limit: Int
    let remaining: Int
    let monthBucket: String
}

struct GenerationPayload {
    let image: UIImage
    let usage: UsageQuota
}

enum GeminiService {
    private static let generateEndpoint = URL(string: "https://www.doggyfresh.cloud/api/generate")!
    private static let usageEndpoint = URL(string: "https://www.doggyfresh.cloud/api/usage")!

    static func fetchUsage() async throws -> UsageQuota {
        var components = URLComponents(url: usageEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "deviceID", value: AppDeviceIdentity.current)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data)
            throw GeminiError.serverError(httpResponse.statusCode, errorResponse?.error)
        }

        guard let decodedResponse = try? JSONDecoder().decode(UsageResponse.self, from: data) else {
            throw GeminiError.invalidResponse
        }

        return decodedResponse.usage
    }

    static func refreshImage(_ image: UIImage,
                             style: RefreshStyle,
                             dogContext: DogContext,
                             customInstruction: String? = nil) async throws -> GenerationPayload {
        let resized = resizedImage(image, maxDimension: 1024)

        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageConversionFailed
        }

        let requestBody = ProxyRequest(
            imageData: jpegData.base64EncodedString(),
            mimeType: "image/jpeg",
            styleDescription: style.promptDescription,
            dogContext: dogContext,
            customInstruction: customInstruction,
            deviceID: AppDeviceIdentity.current
        )

        var request = URLRequest(url: generateEndpoint)
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
            if httpResponse.statusCode == 429 {
                throw GeminiError.limitReached(errorResponse?.usage)
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

        return GenerationPayload(image: resultImage, usage: decodedResponse.usage)
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
        case limitReached(UsageQuota?)
        case serverError(Int, String?)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image"
            case .nonAnimalImage:
                return "Please use an animal photo."
            case .limitReached(let usage):
                if let usage {
                    return "Monthly generation limit reached. \(usage.used)/\(usage.limit) used."
                }
                return "Monthly generation limit reached."
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

private enum AppDeviceIdentity {
    private static let storageKey = "deviceIdentity.v1"

    static var current: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: storageKey), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString.lowercased()
        defaults.set(newID, forKey: storageKey)
        return newID
    }
}

private struct ProxyRequest: Encodable {
    let imageData: String
    let mimeType: String
    let styleDescription: String
    let dogContext: DogContext
    let customInstruction: String?
    let deviceID: String
}

private struct ProxyResponse: Decodable {
    let imageData: String
    let mimeType: String
    let usage: UsageQuota
}

private struct UsageResponse: Decodable {
    let usage: UsageQuota
}

private struct ProxyErrorResponse: Decodable {
    let error: String
    let usage: UsageQuota?
}
