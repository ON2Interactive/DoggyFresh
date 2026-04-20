import SwiftUI
import PhotosUI

struct ProfileView: View {
    let isOnboarding: Bool

    @AppStorage("dogProfile.onboarded") private var hasOnboarded = false

    @State private var profiles: [DogProfile] = []
    @State private var activeDogID: UUID?
    @State private var draft = DogProfileDraft()
    @State private var showAddDogSheet = false
    @State private var showMaxDogsAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showLastDogAlert = false
    @FocusState private var isTextFieldFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private var formFont: Font {
        UIDevice.current.userInterfaceIdiom == .phone ? .system(size: 15) : .body
    }

    private var controlMaxWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 310 : 560
    }

    private var shouldCenterOnboarding: Bool {
        isOnboarding
    }

    private var activeProfile: DogProfile? {
        guard let activeDogID else { return nil }
        return profiles.first(where: { $0.id == activeDogID })
    }

    private var isFormValid: Bool {
        draft.isComplete
    }

    private var canAddDog: Bool {
        profiles.count < DogProfileStorage.maximumDogCount()
    }

    var body: some View {
        ZStack {
            if isOnboarding {
                Image("Background Images")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.28)
                    .ignoresSafeArea()
            }

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        if shouldCenterOnboarding {
                            Spacer(minLength: 0)
                        }

                        if !isOnboarding {
                            profileSwitcherSection
                        }

                        DogProfileForm(
                            draft: $draft,
                            formFont: formFont,
                            controlMaxWidth: controlMaxWidth,
                            isTextFieldFocused: _isTextFieldFocused
                        )

                        Button {
                            saveCurrentDog()
                        } label: {
                            Text(isOnboarding ? "Create Dog Profile" : "Save")
                                .font(formFont.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isOnboarding ? .black : .white)
                        .frame(height: 44)
                        .frame(maxWidth: controlMaxWidth)
                        .background(
                            Capsule().fill(isOnboarding ? Color.white : Color.orange)
                        )
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1 : 0.58)

                        if !isOnboarding && profiles.count > 1 {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Remove dog", systemImage: "trash")
                                    .font(formFont.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .frame(height: 44)
                            .frame(maxWidth: controlMaxWidth)
                            .background(Capsule().fill(Color.white.opacity(0.96)))
                        }

                        if !isOnboarding && !canAddDog {
                            Text("Maximum of \(DogProfileStorage.maximumDogCount()) dogs")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        if shouldCenterOnboarding {
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: shouldCenterOnboarding ? geometry.size.height : nil)
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .navigationTitle(isOnboarding ? "" : "Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if canAddDog {
                            showAddDogSheet = true
                        } else {
                            showMaxDogsAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add dog")
                }
            }
        }
        .sheet(isPresented: $showAddDogSheet) {
            AddDogSheetView(
                formFont: formFont,
                controlMaxWidth: controlMaxWidth
            ) { newDog, image in
                guard DogProfileStorage.createDog(profile: newDog, image: image) else {
                    showMaxDogsAlert = true
                    return
                }
                reloadProfiles(select: newDog.id)
            }
            .presentationDetents([.large])
        }
        .alert("Maximum of \(DogProfileStorage.maximumDogCount()) dogs", isPresented: $showMaxDogsAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("You need at least one dog profile.", isPresented: $showLastDogAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Remove this dog?", isPresented: $showDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                removeCurrentDog()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This dog profile and photo will be removed.")
        }
        .onAppear {
            reloadProfiles(select: activeDogID)
        }
    }

    private var profileSwitcherSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Your dogs")
                .font(formFont.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(profiles) { profile in
                        dogChip(for: profile)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 58)
        }
        .frame(maxWidth: controlMaxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func dogChip(for profile: DogProfile) -> some View {
        let isActive = activeDogID == profile.id
        let photo = DogProfileStorage.loadPhoto(for: profile.id)

        return Button {
            selectDog(profile.id)
        } label: {
            HStack(spacing: 10) {
                Group {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(isActive ? 0.18 : 0.12))
                            Image(systemName: "dog.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.9))
                        }
                    }
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())

                Text(profile.name.isEmpty ? "Dog" : profile.name)
                    .font(formFont.weight(isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? Color.black : Color.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(isActive ? Color.white : Color.white.opacity(0.16))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.white.opacity(0.95) : Color.white.opacity(0.18), lineWidth: isActive ? 1 : 0)
            )
            .shadow(color: isActive ? Color.black.opacity(0.14) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func reloadProfiles(select preferredID: UUID?) {
        let loadedProfiles = DogProfileStorage.loadProfiles()
        profiles = loadedProfiles

        let targetID = preferredID
            ?? DogProfileStorage.activeDogID()
            ?? loadedProfiles.first?.id

        if let targetID {
            DogProfileStorage.setActiveDogID(targetID)
            activeDogID = targetID
            if let profile = loadedProfiles.first(where: { $0.id == targetID }) {
                draft = DogProfileDraft(profile: profile, photo: DogProfileStorage.loadPhoto(for: profile.id))
            }
        } else {
            activeDogID = nil
            draft = DogProfileDraft()
        }
    }

    private func selectDog(_ id: UUID) {
        if draft.isComplete, let activeProfile {
            DogProfileStorage.updateDog(profile: profileFromDraft(id: activeProfile.id), image: draft.photo)
        }
        reloadProfiles(select: id)
    }

    private func saveCurrentDog() {
        if isOnboarding {
            let profile = profileFromDraft(id: UUID())
            guard DogProfileStorage.createDog(profile: profile, image: draft.photo) else { return }
            hasOnboarded = true
            reloadProfiles(select: profile.id)
            return
        }

        guard let activeProfile else { return }
        DogProfileStorage.updateDog(profile: profileFromDraft(id: activeProfile.id), image: draft.photo)
        reloadProfiles(select: activeProfile.id)
        dismiss()
    }

    private func removeCurrentDog() {
        guard profiles.count > 1 else {
            showLastDogAlert = true
            return
        }

        guard let activeProfile else { return }
        let newActiveID = DogProfileStorage.deleteDog(id: activeProfile.id)
        reloadProfiles(select: newActiveID)
    }

    private func profileFromDraft(id: UUID) -> DogProfile {
        DogProfile(
            id: id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: draft.age.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: draft.gender.trimmingCharacters(in: .whitespacesAndNewlines),
            color: draft.color.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

private struct DogProfileDraft {
    var name = ""
    var age = ""
    var gender = ""
    var color = ""
    var photo: UIImage?

    init() { }

    init(profile: DogProfile, photo: UIImage?) {
        self.name = profile.name
        self.age = profile.age
        self.gender = profile.gender
        self.color = profile.color
        self.photo = photo
    }

    var isComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !age.trimmingCharacters(in: .whitespaces).isEmpty
        && !gender.trimmingCharacters(in: .whitespaces).isEmpty
        && !color.trimmingCharacters(in: .whitespaces).isEmpty
        && photo != nil
    }
}

private struct DogProfileForm: View {
    @Binding var draft: DogProfileDraft

    let formFont: Font
    let controlMaxWidth: CGFloat
    @FocusState var isTextFieldFocused: Bool

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    private let genderOptions = ["", "Female", "Male"]

    var body: some View {
        VStack(spacing: 24) {
            profilePhotoSection

            VStack(spacing: 16) {
                pillTextField("Dog's Name", text: $draft.name)
                pillTextField("Age (e.g. 2 years)", text: $draft.age)
                genderWheel
                pillTextField("Color (e.g. Golden)", text: $draft.color)
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    draft.photo = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImage) { _, newImage in
            if let newImage { draft.photo = newImage }
        }
    }

    private var profilePhotoSection: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                profilePhotoPreview
            }
            .buttonStyle(.plain)
            .accessibilityLabel(draft.photo == nil ? "Add photo" : "Change photo")

            HStack(spacing: 12) {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                        .font(formFont)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .frame(height: 40)
                .background(Capsule().fill(.white))

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take photo", systemImage: "camera")
                            .font(formFont)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .frame(height: 40)
                    .background(Capsule().fill(.white))
                }
            }
            .frame(maxWidth: controlMaxWidth)
            .controlSize(.large)
        }
    }

    private var profilePhotoPreview: some View {
        Group {
            if let photo = draft.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.88))
                    VStack(spacing: 4) {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Add photo")
                            .font(formFont)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 140, height: 140)
        .clipShape(Circle())
        .overlay(Circle().stroke(.secondary, lineWidth: 2))
    }

    private var genderWheel: some View {
        ZStack {
            Capsule()
                .fill(.white)
                .frame(height: 44)

            Picker("Gender", selection: $draft.gender) {
                Text("Gender").tag("")
                ForEach(genderOptions.dropFirst(), id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.wheel)
            .font(formFont)
            .foregroundStyle(.black)
            .frame(height: 96)
            .clipped()
        }
        .frame(height: 44)
        .clipped()
        .frame(maxWidth: controlMaxWidth)
    }

    private func pillTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(formFont)
            .textFieldStyle(.plain)
            .focused($isTextFieldFocused)
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .frame(maxWidth: controlMaxWidth)
            .background(Capsule().fill(.white))
    }
}

private struct AddDogSheetView: View {
    let formFont: Font
    let controlMaxWidth: CGFloat
    let onSave: (DogProfile, UIImage?) -> Void

    @State private var draft = DogProfileDraft()
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    DogProfileForm(
                        draft: $draft,
                        formFont: formFont,
                        controlMaxWidth: controlMaxWidth,
                        isTextFieldFocused: _isTextFieldFocused
                    )
                    .padding(.top, 12)

                    Button {
                        onSave(
                            DogProfile(
                                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                age: draft.age.trimmingCharacters(in: .whitespacesAndNewlines),
                                gender: draft.gender.trimmingCharacters(in: .whitespacesAndNewlines),
                                color: draft.color.trimmingCharacters(in: .whitespacesAndNewlines)
                            ),
                            draft.photo
                        )
                        dismiss()
                    } label: {
                        Text("Add Dog")
                            .font(formFont)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .frame(height: 44)
                    .frame(maxWidth: controlMaxWidth)
                    .background(Capsule().fill(.white))
                    .disabled(!draft.isComplete)
                    .opacity(draft.isComplete ? 1 : 0.58)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
            .navigationTitle("Add Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(isOnboarding: true)
    }
}
