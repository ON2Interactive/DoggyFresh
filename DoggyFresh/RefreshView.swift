import SwiftUI
import PhotosUI

private enum AppState {
    case idle
    case imageSelected(UIImage)
    case processing
    case result(original: UIImage, refreshed: UIImage)
    case error(String)
}

struct RefreshView: View {
    @State private var appState: AppState = .idle
    @State private var selectedStyle: RefreshStyle = .cartoon
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var showSaveConfirmation = false

    var body: some View {
        Group {
            switch appState {
            case .idle:
                idleView
            case .imageSelected(let image):
                selectedImageView(image)
            case .processing:
                processingView
            case .result(_, let refreshed):
                resultView(refreshed)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("DoggyFresh")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileView(isOnboarding: false)
                } label: {
                    profileToolbarIcon
                }
            }
        }
    }

    // MARK: - Toolbar Profile Icon

    private var profileToolbarIcon: some View {
        Group {
            if let photo = DogProfileStorage.loadPhoto() {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "dog")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("Give \(activeDogName.isEmpty ? "your dog" : activeDogName) a fresh new look")
                .font(.headline)
                .multilineTextAlignment(.center)

            // Style wheel selector
            VStack(spacing: 4) {
                Text("Choose a style")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Style", selection: $selectedStyle) {
                    ForEach(RefreshStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding()
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    appState = .imageSelected(uiImage)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImage) { _, newImage in
            if let newImage {
                appState = .imageSelected(newImage)
            }
        }
    }

    // MARK: - Selected Image View

    private func selectedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            Text("Style: \(selectedStyle.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("Cancel") {
                    resetState()
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await refreshImage(image) }
                } label: {
                    Label("Refresh", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Creating your \(selectedStyle.rawValue.lowercased()) masterpiece...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Result View

    private func resultView(_ image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            HStack(spacing: 16) {
                Button {
                    Task {
                        try? await ImageSaver.save(image)
                        showSaveConfirmation = true
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)

                ShareLink(item: Image(uiImage: image),
                          preview: SharePreview("DoggyFresh", image: Image(uiImage: image)))

                Button("New Photo") {
                    resetState()
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .alert("Saved!", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                resetState()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Actions

    private func refreshImage(_ image: UIImage) async {
        appState = .processing
        do {
            let dogContext = DogProfileStorage.dogContextForActiveDog()
            let payload = try await GeminiService.refreshImage(image, style: selectedStyle, dogContext: dogContext)
            appState = .result(original: image, refreshed: payload.image)
        } catch {
            appState = .error(error.localizedDescription)
        }
    }

    private var activeDogName: String {
        DogProfileStorage.activeDog()?.name ?? ""
    }

    private func resetState() {
        appState = .idle
        photosPickerItem = nil
        cameraImage = nil
    }
}

#Preview {
    NavigationStack {
        RefreshView()
    }
}
