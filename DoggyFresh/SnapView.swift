import SwiftUI
import UIKit

struct SnapView: View {
    let onPhotoCaptured: (UIImage) -> Void

    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    var body: some View {
        Group {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
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
        onPhotoCaptured(capturedImage)
        self.capturedImage = nil
    }
}

#Preview {
    NavigationStack {
        SnapView { _ in }
    }
}
