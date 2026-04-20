import SwiftUI
import UIKit

struct SnapView: View {
    let onPhotoCaptured: (UIImage) -> Void

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isOptimizing = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isOptimizing {
                VStack(spacing: 18) {
                    ProgressView()
                        .controlSize(.large)

                    Text("Optimizing photo...")
                        .font(.headline)

                    Text("Adjusting lighting, clarity, and focus before opening Compose.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 58))
                        .foregroundStyle(.secondary)

                    Button {
                        showCamera = true
                    } label: {
                        Label("Open camera", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.secondary)

                    Text("Camera is not available in Simulator.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Snap")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCamera = true
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: handleCameraDismiss) {
            SnapCameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
    }

    private func handleCameraDismiss() {
        guard let capturedImage else { return }
        self.capturedImage = nil
        errorMessage = nil

        Task {
            await optimizeAndRoute(capturedImage)
        }
    }

    @MainActor
    private func optimizeAndRoute(_ image: UIImage) async {
        isOptimizing = true
        defer { isOptimizing = false }

        do {
            let optimizedImage = try await GeminiService.optimizeSnapImage(image)
            onPhotoCaptured(optimizedImage)
        } catch GeminiService.GeminiError.nonAnimalImage {
            errorMessage = "Please snap an animal photo."
        } catch {
            onPhotoCaptured(image)
        }
    }
}

#Preview {
    NavigationStack {
        SnapView { _ in }
    }
}
