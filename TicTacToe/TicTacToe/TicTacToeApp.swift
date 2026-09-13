import SwiftUI

@main
struct TicTacToeApp: App {
    // Initialize the manager state right at launch
    @StateObject private var gameManager = OnlineGameManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager) // Makes it accessible everywhere
        }
        #if os(macOS)
        .defaultSize(width: 360, height: 720)
        #endif
    }
}
