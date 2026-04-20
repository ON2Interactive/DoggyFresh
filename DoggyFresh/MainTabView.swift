import SwiftUI

struct MainTabView: View {
    private enum AppTab: Int {
        case compose = 0
        case snap = 1
        case profile = 2
        case settings = 3
    }

    @State private var selectedTab: AppTab = .compose
    @State private var lastContentTab: AppTab = .compose
    @State private var snappedImage: UIImage?
    @State private var showSettingsSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ComposeView(snappedImage: $snappedImage)
            }
            .tabItem {
                Label("Compose", systemImage: "wand.and.stars")
            }
            .tag(AppTab.compose)

            NavigationStack {
                SnapView { image in
                    snappedImage = image
                    selectedTab = .compose
                    lastContentTab = .compose
                }
            }
            .tabItem {
                Label("Snap", systemImage: "camera")
            }
            .tag(AppTab.snap)

            NavigationStack {
                ProfileView(isOnboarding: false)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)

            Color.clear
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .settings {
                showSettingsSheet = true
                selectedTab = lastContentTab
            } else {
                lastContentTab = newValue
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView()
                .presentationDetents([.medium])
        }
    }
}

private struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let privacyURL = URL(string: "https://doggyfresh.cloud/privacy")!
    private let termsURL = URL(string: "https://doggyfresh.cloud/terms")!
    private let supportURL = URL(string: "https://doggyfresh.cloud/support")!
    private let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                settingsRow(title: "Privacy", systemImage: "hand.raised") {
                    openURL(privacyURL)
                }

                settingsRow(title: "Terms of Use", systemImage: "doc.text") {
                    openURL(termsURL)
                }

                settingsRow(title: "Support", systemImage: "questionmark.circle") {
                    openURL(supportURL)
                }

                settingsRow(title: "Manage Subscription", systemImage: "creditcard") {
                    openURL(subscriptionsURL)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Color.orange))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
