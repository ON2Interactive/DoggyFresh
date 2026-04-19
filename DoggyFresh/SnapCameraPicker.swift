import SwiftUI
import UIKit

struct SnapCameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.showsCameraControls = false
        picker.cameraOverlayView = context.coordinator.makeOverlay(for: picker)
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: SnapCameraPicker
        private weak var picker: UIImagePickerController?

        init(_ parent: SnapCameraPicker) {
            self.parent = parent
        }

        func makeOverlay(for picker: UIImagePickerController) -> UIView {
            self.picker = picker

            let overlay = UIView(frame: UIScreen.main.bounds)
            overlay.backgroundColor = .clear

            let shutterButton = UIButton(type: .custom)
            shutterButton.translatesAutoresizingMaskIntoConstraints = false
            shutterButton.backgroundColor = .white
            shutterButton.layer.cornerRadius = 38
            shutterButton.layer.borderWidth = 4
            shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
            shutterButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
            overlay.addSubview(shutterButton)

            let cancelButton = UIButton(type: .system)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            cancelButton.tintColor = .white
            cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            cancelButton.layer.cornerRadius = 22
            cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
            overlay.addSubview(cancelButton)

            NSLayoutConstraint.activate([
                shutterButton.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                shutterButton.bottomAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -34),
                shutterButton.widthAnchor.constraint(equalToConstant: 76),
                shutterButton.heightAnchor.constraint(equalToConstant: 76),

                cancelButton.leadingAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                cancelButton.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 18),
                cancelButton.widthAnchor.constraint(equalToConstant: 44),
                cancelButton.heightAnchor.constraint(equalToConstant: 44)
            ])

            return overlay
        }

        @objc private func takePhoto() {
            picker?.takePicture()
        }

        @objc private func cancel() {
            parent.dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
