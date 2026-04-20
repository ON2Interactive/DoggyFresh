import Foundation
import UIKit

struct DogProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var age: String
    var gender: String
    var color: String

    init(id: UUID = UUID(), name: String, age: String, gender: String, color: String) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.color = color
    }

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
    private static let profilesKey = "dogProfiles.v2.items"
    private static let activeDogIDKey = "dogProfiles.v2.activeDogID"
    private static let legacyMigratedKey = "dogProfiles.v2.legacyMigrated"
    private static let legacyNameKey = "dogProfile.name"
    private static let legacyAgeKey = "dogProfile.age"
    private static let legacyGenderKey = "dogProfile.gender"
    private static let legacyColorKey = "dogProfile.color"
    private static let maxDogs = 3

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var legacyPhotoURL: URL {
        documentsDirectory.appendingPathComponent("dogProfilePhoto.jpg")
    }

    private static func photoURL(for id: UUID) -> URL {
        documentsDirectory.appendingPathComponent("dog-\(id.uuidString).jpg")
    }

    private static func migrateLegacyProfileIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: legacyMigratedKey) else { return }

        defer {
            defaults.set(true, forKey: legacyMigratedKey)
        }

        guard decodeProfiles(from: defaults.data(forKey: profilesKey)).isEmpty else { return }

        let name = defaults.string(forKey: legacyNameKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let age = defaults.string(forKey: legacyAgeKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let gender = defaults.string(forKey: legacyGenderKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let color = defaults.string(forKey: legacyColorKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty || !age.isEmpty || !gender.isEmpty || !color.isEmpty || FileManager.default.fileExists(atPath: legacyPhotoURL.path) else {
            return
        }

        let profile = DogProfile(name: name, age: age, gender: gender, color: color)
        saveProfiles([profile])
        setActiveDogID(profile.id)

        if let image = UIImage(contentsOfFile: legacyPhotoURL.path) {
            savePhoto(image, for: profile.id)
        }
    }

    static func loadProfiles() -> [DogProfile] {
        let defaults = UserDefaults.standard

        let existingProfiles = decodeProfiles(from: defaults.data(forKey: profilesKey))
        if !existingProfiles.isEmpty {
            return existingProfiles
        }

        if defaults.data(forKey: profilesKey) != nil {
            defaults.removeObject(forKey: profilesKey)
            defaults.removeObject(forKey: activeDogIDKey)
        }

        if !defaults.bool(forKey: legacyMigratedKey) {
            migrateLegacyProfileIfNeeded()
            let migratedProfiles = decodeProfiles(from: defaults.data(forKey: profilesKey))
            if !migratedProfiles.isEmpty {
                return migratedProfiles
            }
        }

        return []
    }

    private static func decodeProfiles(from data: Data?) -> [DogProfile] {
        guard let data else { return [] }

        if let profiles = try? decoder.decode([DogProfile].self, from: data) {
            return profiles
        }
        
        return []
    }

    static func saveProfiles(_ profiles: [DogProfile]) {
        guard let data = try? encoder.encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }

    static func activeDogID() -> UUID? {
        if let rawValue = UserDefaults.standard.string(forKey: activeDogIDKey) {
            return UUID(uuidString: rawValue)
        }
        return loadProfiles().first?.id
    }

    static func setActiveDogID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: activeDogIDKey)
    }

    static func activeDog() -> DogProfile? {
        let profiles = loadProfiles()
        if let activeDogID = activeDogID(),
           let profile = profiles.first(where: { $0.id == activeDogID }) {
            return profile
        }
        return profiles.first
    }

    @discardableResult
    static func createDog(profile: DogProfile, image: UIImage?) -> Bool {
        var profiles = loadProfiles()
        guard profiles.count < maxDogs else { return false }
        profiles.append(profile)
        saveProfiles(profiles)
        setActiveDogID(profile.id)
        if let image {
            savePhoto(image, for: profile.id)
        }
        return true
    }

    static func updateDog(profile: DogProfile, image: UIImage?) {
        var profiles = loadProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveProfiles(profiles)
        if let image {
            savePhoto(image, for: profile.id)
        }
    }

    @discardableResult
    static func deleteDog(id: UUID) -> UUID? {
        var profiles = loadProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return activeDogID() }

        profiles.remove(at: index)
        saveProfiles(profiles)

        try? FileManager.default.removeItem(at: photoURL(for: id))

        let newActiveID = profiles.first?.id
        if let newActiveID {
            setActiveDogID(newActiveID)
        } else {
            UserDefaults.standard.removeObject(forKey: activeDogIDKey)
        }

        return newActiveID
    }

    static func loadPhoto(for id: UUID) -> UIImage? {
        guard let data = try? Data(contentsOf: photoURL(for: id)) else { return nil }
        return UIImage(data: data)
    }

    static func savePhoto(_ image: UIImage, for id: UUID) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: photoURL(for: id), options: .atomic)
        }
    }

    static func loadPhoto() -> UIImage? {
        guard let activeDog = activeDog() else { return nil }
        return loadPhoto(for: activeDog.id)
    }

    static func savePhoto(_ image: UIImage) {
        guard let activeDog = activeDog() else { return }
        savePhoto(image, for: activeDog.id)
    }

    static func dogContextForActiveDog() -> DogContext {
        let activeDog = activeDog()
        return DogContext(
            name: activeDog?.name ?? "",
            gender: activeDog?.gender ?? "",
            color: activeDog?.color ?? ""
        )
    }

    static func maximumDogCount() -> Int {
        maxDogs
    }
}
