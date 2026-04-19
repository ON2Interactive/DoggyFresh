import SwiftUI
import PhotosUI

struct ProfileView: View {
    let isOnboarding: Bool

    @AppStorage("dogProfile.onboarded") private var hasOnboarded = false
    @AppStorage("dogProfile.name") private var name = ""
    @AppStorage("dogProfile.age") private var age = ""
    @AppStorage("dogProfile.gender") private var gender = ""
    @AppStorage("dogProfile.color") private var color = ""

    @State private var profilePhoto: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    private let genderOptions = ["", "Female", "Male"]

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !age.trimmingCharacters(in: .whitespaces).isEmpty
        && !gender.trimmingCharacters(in: .whitespaces).isEmpty
        && !color.trimmingCharacters(in: .whitespaces).isEmpty
        && profilePhoto != nil
    }

    private var formFont: Font {
        UIDevice.current.userInterfaceIdiom == .phone ? .system(size: 14) : .body
    }

    private var controlMaxWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .phone ? 310 : 560
    }

    private var shouldCenterOnboarding: Bool {
        isOnboarding
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

                        profilePhotoSection

                        VStack(spacing: 16) {
                            pillTextField("Dog's Name", text: $name)
                            pillTextField("Age (e.g. 2 years)", text: $age)
                            genderWheel
                            pillTextField("Color (e.g. Golden)", text: $color)
                        }

                        Button {
                            if let photo = profilePhoto {
                                DogProfileStorage.savePhoto(photo)
                            }
                            if isOnboarding {
                                hasOnboarded = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text(isOnboarding ? "Create Dog Profile" : "Save")
                                .font(formFont)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black)
                        .frame(height: 44)
                        .frame(maxWidth: controlMaxWidth)
                        .background(Capsule().fill(.white))
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1 : 0.58)

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
        .navigationTitle(isOnboarding ? "" : "Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            profilePhoto = DogProfileStorage.loadPhoto()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profilePhoto = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImage) { _, newImage in
            if let newImage { profilePhoto = newImage }
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                profilePhotoPreview
            }
            .buttonStyle(.plain)
            .accessibilityLabel(profilePhoto == nil ? "Add photo" : "Change photo")

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
            if let profilePhoto {
                Image(uiImage: profilePhoto)
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

    // MARK: - Pill Text Field

    private var genderWheel: some View {
        ZStack {
            Capsule()
                .fill(.white)
                .frame(height: 44)

            Picker("Gender", selection: $gender) {
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
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .frame(maxWidth: controlMaxWidth)
            .background(Capsule().fill(.white))
    }
}

#Preview {
    NavigationStack {
        ProfileView(isOnboarding: true)
    }
}
