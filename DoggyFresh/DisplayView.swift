import SwiftUI

struct DisplayView: View {
    let image: UIImage
    let style: RefreshStyle

    @Environment(\.dismiss) private var dismiss

    @State private var displayedImage: UIImage
    @State private var promptText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showSaveConfirmation = false
    @FocusState private var isPromptFocused: Bool

    init(image: UIImage, style: RefreshStyle) {
        self.image = image
        self.style = style
        _displayedImage = State(initialValue: image)
    }

    var body: some View {
        VStack(spacing: 16) {
            topActions

            Spacer(minLength: 0)

            Image(uiImage: displayedImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                promptComposer
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            isPromptFocused = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Saved!", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        }
    }

    private var topActions: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            HStack(spacing: 4) {
                Button {
                    Task {
                        try? await ImageSaver.save(displayedImage)
                        showSaveConfirmation = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.tint)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save image")

                ShareLink(item: Image(uiImage: displayedImage),
                          preview: SharePreview("DoggyFresh", image: Image(uiImage: displayedImage))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.tint)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share image")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.orange.opacity(0.12))
            )
        }
    }

    private var promptComposer: some View {
        HStack(spacing: 8) {
            TextField("Describe a change", text: $promptText, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .focused($isPromptFocused)
                .padding(.leading, 16)
                .disabled(isGenerating)

            Button {
                Task { await regenerateImage() }
            } label: {
                if isGenerating {
                    ProgressView()
                        .frame(width: 42, height: 42)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(.tint))
                }
            }
            .buttonStyle(.plain)
            .disabled(isGenerating || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            .accessibilityLabel("Generate from prompt")
        }
        .padding(.vertical, 6)
        .padding(.leading, 2)
        .padding(.trailing, 6)
        .background(Capsule().fill(Color(.secondarySystemBackground)))
    }

    private func regenerateImage() async {
        let instruction = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return }

        isGenerating = true
        errorMessage = nil

        do {
            let payload = try await GeminiService.refreshImage(
                displayedImage,
                style: style,
                dogContext: DogContext(name: "", gender: "", color: ""),
                customInstruction: instruction
            )
            displayedImage = payload.image
            promptText = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        DisplayView(image: UIImage(), style: .cartoon)
    }
}
