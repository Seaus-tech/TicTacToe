#if canImport(SwiftUI)
import SwiftUI
#else
import SwiftCrossUI
import DefaultBackend
#endif

struct FeatureItem: Identifiable {
    let id = UUID()
    let emoji: String
    let tintColor: Color
    let text: String
}

struct FeatureGroup: Identifiable {
    let id = UUID()
    let sectionTitle: String
    let items: [FeatureItem]
}

struct ReleaseNotesRegistry {
    // Update this version and the feature lists below for each release.
    static let currentVersion = "8.1.0"

    // To edit these notes, change the text or add/remove a FeatureItem in a section.
    // Each item is one bullet in the What's New screen.
    static let latestNotes: [FeatureGroup] = [
        FeatureGroup(
            sectionTitle: "NEW FEATURES",
            items: [
                FeatureItem(emoji: "↩️", tintColor: .orange,
                            text: "Undo a move. When playing against the bot, undo both your move and the bot's reply."),
                FeatureItem(emoji: "🎬", tintColor: .purple,
                            text: "Replay a completed game move by move with previous, next, and slider controls."),
                FeatureItem(emoji: "🏆", tintColor: .yellow,
                            text: "Open the Game Center leaderboard from the Score screen. Career wins are saved on your device and submitted when Game Center is available.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "UI IMPROVEMENTS",
            items: [
                FeatureItem(emoji: "📐", tintColor: .blue,
                            text: "The game board keeps its cells square, fixing the compressed board layout across supported screen sizes."),
                FeatureItem(emoji: "✨", tintColor: .cyan,
                            text: "Game and replay controls are arranged to fit more comfortably on narrower screens.")
            ]
        )
    ]
}
