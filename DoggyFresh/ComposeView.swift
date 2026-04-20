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
    @AppStorage("dogProfiles.v2.activeDogID") private var activeDogIDRaw = ""

    @State private var selectedStyle: RefreshStyle = .cartoon
    @State private var composeState: ComposeState = .ready
    @State private var generatedPhoto: GeneratedPhoto?
    @State private var showDisplay = false
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var cameraImage: UIImage?
    @State private var usage: UsageQuota?
    @State private var isLoadingUsage = false

    private var activeDogID: UUID? {
        UUID(uuidString: activeDogIDRaw)
    }

    private var activeDogName: String {
        let _ = activeDogID
        return DogProfileStorage.activeDog()?.name ?? ""
    }

    private var activeDogNameFont: Font {
        UIDevice.current.userInterfaceIdiom == .phone ? .system(size: 14) : .body
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                profilePhoto

                if !activeDogName.isEmpty {
                    Text(activeDogName)
                        .font(activeDogNameFont.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Preset", selection: $selectedStyle) {
                ForEach(RefreshStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)

            usageView

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
        .onChange(of: activeDogIDRaw) { _, _ in
            snappedImage = nil
            composeState = .ready
        }
        .task {
            await refreshUsage()
        }
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
                if let image = currentComposeImage {
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

    private var currentComposeImage: UIImage? {
        let _ = activeDogID
        return snappedImage ?? DogProfileStorage.loadPhoto()
    }

    private var usageView: some View {
        Group {
            if isLoadingUsage && usage == nil {
                ProgressView()
                    .controlSize(.small)
            } else if let usage {
                Text("\(usage.remaining) of \(usage.limit) generations left this month")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func generatePhoto() async {
        guard let image = currentComposeImage else {
            composeState = .error("Add or snap a dog photo first.")
            return
        }

        composeState = .generating
        do {
            let context = DogProfileStorage.dogContextForActiveDog()
            let payload = try await GeminiService.refreshImage(image, style: selectedStyle, dogContext: context)
            generatedPhoto = GeneratedPhoto(style: selectedStyle, image: payload.image)
            usage = payload.usage
            showDisplay = true
            composeState = .ready
        } catch {
            composeState = .error(error.localizedDescription)
        }
    }

    private func refreshUsage() async {
        isLoadingUsage = true
        defer { isLoadingUsage = false }

        do {
            usage = try await GeminiService.fetchUsage()
        } catch {
            if usage == nil {
                composeState = .error(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ComposeView(snappedImage: .constant(nil))
    }
}
