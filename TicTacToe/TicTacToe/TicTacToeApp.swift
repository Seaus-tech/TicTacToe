import SwiftUI

@main
struct TicTacToeApp: App {
    var body: some Scene {
        WindowGroup {
            AuthView()
                #if os(macOS)
                // Set flexible minimum constraints while allowing infinite stretching expansion
                .frame(minWidth: 700, maxWidth: .infinity, minHeight: 550, maxHeight: .infinity)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar) // Ensures a true borderless glass aesthetic
        #endif
    }
}
