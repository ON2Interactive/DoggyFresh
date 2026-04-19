import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var snappedImage: UIImage?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ComposeView(snappedImage: $snappedImage)
            }
            .tabItem {
                Label("Compose", systemImage: "wand.and.stars")
            }
            .tag(0)

            NavigationStack {
                SnapView { image in
                    snappedImage = image
                    selectedTab = 0
                }
            }
            .tabItem {
                Label("Snap", systemImage: "camera")
            }
            .tag(1)

            NavigationStack {
                ProfileView(isOnboarding: false)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}
