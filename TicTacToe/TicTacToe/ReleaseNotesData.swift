import SwiftUI

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
    static let currentVersion = "v3.7.1"

    static let latestNotes: [FeatureGroup] = [
        FeatureGroup(
            sectionTitle: "WHAT'S NEW",
            items: [
                FeatureItem(emoji: "🧠", tintColor: .purple,
                            text: "Unbeatable Bot: Tier 5 \"Nemesis\" now runs a full minimax engine with alpha-beta pruning. It is very hard to beat."),
                FeatureItem(emoji: "🎨", tintColor: .blue,
                            text: "Piece Picker: Choose X or O before every game. X always goes first."),
                FeatureItem(emoji: "🏆", tintColor: .orange,
                            text: "Live Score Tracker: X wins, O wins, and draws are tracked across your session with animated counters."),
                FeatureItem(emoji: "✨", tintColor: .yellow,
                            text: "Win Animation: The winning three cells glow and highlight the moment the game ends."),
                FeatureItem(emoji: "🎯", tintColor: .green,
                            text: "Turn Indicator: A pulsing dot shows whose move it is at all times.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "BOT TIERS",
            items: [
                FeatureItem(emoji: "🟢", tintColor: .green,
                            text: "Tier 1 — Rookie: Fully random. Great for kids."),
                FeatureItem(emoji: "🔵", tintColor: .teal,
                            text: "Tier 2 — Cadet: Mostly random with occasional smart plays."),
                FeatureItem(emoji: "🟣", tintColor: .blue,
                            text: "Tier 3 — Tactician: Takes wins, prefers center and corners."),
                FeatureItem(emoji: "🟠", tintColor: .purple,
                            text: "Tier 4 — Veteran: Wins, blocks, and controls the board."),
                FeatureItem(emoji: "🔴", tintColor: .red,
                            text: "Tier 5 — Nemesis: Perfect play via minimax. Unbeatable.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "ONLINE PLAY",
            items: [
                FeatureItem(emoji: "🌐", tintColor: .cyan,
                            text: "Game Center Matchmaking: Fully wired turn relay, opponent name display, and graceful disconnect handling."),
                FeatureItem(emoji: "🔥", tintColor: .orange,
                            text: "Win Streaks & Career Wins: Automatically synced to your Game Center leaderboard and achievements.")
            ]
        ),
        FeatureGroup(
            sectionTitle: "FIXES",
            items: [
                FeatureItem(emoji: "🛠️", tintColor: .red,
                            text: "Bot double-move bug fixed — the bot no longer places two pieces in one turn."),
                FeatureItem(emoji: "🛠️", tintColor: .red,
                            text: "AI win detection fixed — the top-left row was previously excluded from all win checks.")
            ]
        )
    ]
}
