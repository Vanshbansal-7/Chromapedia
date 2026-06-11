import SwiftUI

@main
struct ChromapediaApp: App {
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favoritesManager)
                .preferredColorScheme(.light)
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ColorLibraryView()
                .tabItem { Label("Explore", systemImage: "circle.hexagongrid.fill") }
                .tag(0)

            MixingLabView()
                .tabItem { Label("Mix Lab", systemImage: "drop.fill") }
                .tag(1)

            CameraColorView()
                .tabItem { Label("Identify", systemImage: "camera.aperture") }
                .tag(2)
        }
        .tint(Color(hex: "#FF6B6B"))
    }
}

#Preview { ContentView().environmentObject(FavoritesManager()) }
