import Foundation
import UIKit

struct DogProfile {
    var name: String
    var age: String
    var gender: String
    var color: String

    var isComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !age.trimmingCharacters(in: .whitespaces).isEmpty
        && !gender.trimmingCharacters(in: .whitespaces).isEmpty
        && !color.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

struct DogContext: Encodable {
    let name: String
    let gender: String
    let color: String
}

enum DogProfileStorage {
    private static var photoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dogProfilePhoto.jpg")
    }

    static func savePhoto(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: photoURL)
        }
    }

    static func loadPhoto() -> UIImage? {
        guard let data = try? Data(contentsOf: photoURL) else { return nil }
        return UIImage(data: data)
    }
}
