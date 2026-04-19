import SwiftUI

@main
struct DoggyFreshApp: App {
    @AppStorage("dogProfile.onboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                MainTabView()
                    .tint(.orange)
            } else {
                NavigationStack {
                    ProfileView(isOnboarding: true)
                }
                .tint(.orange)
            }
        }
    }
}
