import SwiftUI

@main
struct SekretLinkApp: App {
    @State private var incomingURL: URL?

    var body: some Scene {
        WindowGroup {
            ContentView(incomingURL: $incomingURL)
                .onOpenURL { url in incomingURL = url }
                .tint(Theme.accent)   // sekret-600 #b33f94 across all system controls
        }
    }
}
