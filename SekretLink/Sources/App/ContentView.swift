import SwiftUI

struct ContentView: View {
    @Binding var incomingURL: URL?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CreateSecretView()
                .tabItem {
                    Label("Create", systemImage: "lock.fill")
                }
                .tag(0)

            ViewSecretView(incomingURL: $incomingURL)
                .tabItem {
                    Label("Open", systemImage: "eye")
                }
                .tag(1)
        }
        .onChange(of: incomingURL) { url in
            if url != nil {
                selectedTab = 1
            }
        }
    }
}
