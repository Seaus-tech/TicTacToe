#if canImport(SwiftUI)
import SwiftUI
#else
import SwiftCrossUI
import DefaultBackend
#endif

struct HowToPlayView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HowToPlayHeader()

                    VStack(spacing: 14) {
                        HowToPlayStep(
                            number: "1",
                            title: "Take turns",
                            detail: "Choose an empty square to place your mark. X goes first, then players alternate."
                        )
                        HowToPlayStep(
                            number: "2",
                            title: "Make a line",
                            detail: "Get three of your marks in a row horizontally, vertically, or diagonally to win."
                        )
                        HowToPlayStep(
                            number: "3",
                            title: "Watch for a draw",
                            detail: "If all nine squares are filled and nobody has three in a row, the game is a draw."
                        )
                    }

                    HowToPlayExtras()
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("How to Play")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Let’s Play") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(minWidth: 320, minHeight: 420)
    }
}

private struct HowToPlayHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "grid.3x3")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Welcome to NEO-GRID")
                .font(.title2.weight(.bold))

            Text("The goal is simple: line up three of your marks before your opponent does.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HowToPlayStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct HowToPlayExtras: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Play against a bot, a nearby friend, or online from Game Options.", systemImage: "gamecontroller")
            Label("Undo a move during a game, or review a finished game with Replay.", systemImage: "arrow.uturn.backward")
            Label("Check your results and open the Game Center leaderboard on the Score screen.", systemImage: "chart.bar")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
