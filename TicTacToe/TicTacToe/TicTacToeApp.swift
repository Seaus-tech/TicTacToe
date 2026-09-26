import SwiftUI

@main
struct TicTacToeApp: App {
    @StateObject private var gameManager = OnlineGameManager()
    @AppStorage("appAppearance") private var appearance = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .preferredColorScheme(appearance == 1 ? .light : appearance == 2 ? .dark : nil)
        }
        #if os(macOS)
        .defaultSize(width: 680, height: 600)
        .windowResizability(.contentMinSize)
        #endif
    }
}
