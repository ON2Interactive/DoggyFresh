import SwiftUI
import PhotosUI

private enum ComposeState {
    case ready
    case generating
    case error(String)
}

private struct GeneratedPhoto: Identifiable {
    let id = UUID()
    let style: RefreshStyle
    let image: UIImage
}

struct ComposeView: View {
    @Binding var snappedImage: UIImage?

    @State private var selectedStyle: RefreshStyle = .cartoon
    @State private var composeState: ComposeState = .ready
    @State private var generatedPhoto: GeneratedPhoto?
    @State private var showDisplay = false
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var cameraImage: UIImage?

    @AppStorage("dogProfile.name") private var dogName = ""
    @AppStorage("dogProfile.gender") private var dogGender = ""
    @AppStorage("dogProfile.color") private var dogColor = ""

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            profilePhoto

            Picker("Preset", selection: $selectedStyle) {
                ForEach(RefreshStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)

            Button {
                Task { await generatePhoto() }
            } label: {
                if case .generating = composeState {
                    ProgressView()
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 30, weight: .semibold))
                        .frame(width: 72, height: 72)
                }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .disabled(isGenerating)

            if case .error(let message) = composeState {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Compose")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Choose photo source", isPresented: $showPhotoSourceDialog, titleVisibility: .hidden) {
            Button("Choose photo") {
                showPhotoPicker = true
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take photo") {
                    showCamera = true
                }
            }

            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    snappedImage = image
                    composeState = .ready
                }
            }
        }
        .onChange(of: cameraImage) { _, newImage in
            guard let newImage else { return }
            snappedImage = newImage
            cameraImage = nil
            composeState = .ready
        }
        .navigationDestination(isPresented: $showDisplay) {
            if let generatedPhoto {
                DisplayView(image: generatedPhoto.image, style: generatedPhoto.style)
            }
        }
    }

    private var isGenerating: Bool {
        if case .generating = composeState {
            return true
        }
        return false
    }

    private var profilePhoto: some View {
        Button {
            showPhotoSourceDialog = true
        } label: {
            Group {
                if let image = snappedImage ?? DogProfileStorage.loadPhoto() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(.secondary.opacity(0.18))
                        Image(systemName: "dog")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 180, height: 180)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change source photo")
    }

    private func generatePhoto() async {
        guard let image = snappedImage ?? DogProfileStorage.loadPhoto() else {
            composeState = .error("Add or snap a dog photo first.")
            return
        }

        composeState = .generating
        do {
            let context = DogContext(name: dogName, gender: dogGender, color: dogColor)
            let refreshed = try await GeminiService.refreshImage(image, style: selectedStyle, dogContext: context)
            generatedPhoto = GeneratedPhoto(style: selectedStyle, image: refreshed)
            showDisplay = true
            composeState = .ready
        } catch {
            composeState = .error(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        ComposeView(snappedImage: .constant(nil))
    }
}
