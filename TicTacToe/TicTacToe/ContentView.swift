#if canImport(SwiftUI)
import SwiftUI
#else
import SwiftCrossUI
import DefaultBackend
#endif

import GameKit

enum MatchMode: Hashable {
    case online
    case bot
    case localPassAndPlay
}

private enum AppSection: Hashable {
    case play
    case options
    case score
}

struct ContentView: View {
    @EnvironmentObject private var gameManager: OnlineGameManager
    @StateObject private var game = GameViewModel()
    @StateObject private var difficultyManager = BotDifficultyManager()

    @State private var activeMode: MatchMode = .bot
    @State private var selectedGameMode: GameMode = .classic
    @State private var selectedSection: AppSection? = .play
    @State private var showWhatsNew = false
    @State private var showHowToPlay = false
    @State private var showPiecePicker = false
    @AppStorage("appAppearance") private var appearance = 0
    @AppStorage("lastTrackedVersion") private var lastTrackedVersion = ""
    @AppStorage("hasSeenHowToPlay") private var hasSeenHowToPlay = false

    var body: some View {
        NavigationSplitView {
            GameSidebar(
                selection: $selectedSection,
                scoreX: game.scoreX,
                scoreO: game.scoreO,
                drawCount: game.drawCount
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            Group {
                switch selectedSection ?? .play {
                case .play:
                    GameView(
                        game: game,
                        activeMode: activeMode,
                        onNewGame: newGameRequested,
                        onOnlinePlay: gameManager.presentMatchmakerInterface
                    )
                case .options:
                    GameOptionsView(
                        activeMode: $activeMode,
                        selectedGameMode: $selectedGameMode,
                        difficulty: Binding(
                            get: { difficultyManager.selectedLevel },
                            set: setDifficulty
                        ),
                        onlineAvailable: gameManager.isPlayerAuthenticated,
                        onOnlinePlay: gameManager.presentMatchmakerInterface
                    )
                case .score:
                    ScoreView(
                        scoreX: game.scoreX,
                        scoreO: game.scoreO,
                        draws: game.drawCount,
                        winStreak: game.winStreak,
                        isGameCenterAvailable: gameManager.isPlayerAuthenticated,
                        onShowLeaderboard: gameManager.presentLeaderboard,
                        onReset: game.resetScores
                    )
                }
            }
            .navigationTitle(title(for: selectedSection ?? .play))
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedSection == .play {
                        Button(action: newGameRequested) {
                            Label("New Game", systemImage: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }

                    Menu {
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag(0)
                            Text("Light").tag(1)
                            Text("Dark").tag(2)
                        }
                        Divider()
                        Button("How to Play") {
                            showHowToPlay = true
                        }
                        Button("What’s New") {
                            showWhatsNew = true
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(.accentColor)
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView(isPresented: $showWhatsNew)
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showHowToPlay, onDismiss: completeHowToPlay) {
            HowToPlayView(isPresented: $showHowToPlay)
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showPiecePicker) {
            PiecePickerSheet(humanPiece: $game.humanPiece) {
                showPiecePicker = false
                startFreshGame()
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .alert("Opponent Disconnected", isPresented: $game.opponentDisconnected) {
            Button("OK", action: endOnlineMatch)
        } message: {
            Text("Your opponent left the game.")
        }
        .onAppear(perform: setupGame)
        .onChange(of: selectedGameMode) { _, newMode in
            game.activeGameMode = newMode
            startFreshGame()
        }
        .onChange(of: activeMode) { _, newMode in
            guard gameManager.currentMatch == nil else { return }
            game.matchMode = newMode

            if newMode == .bot {
                showPiecePicker = true
            } else {
                game.humanPiece = "X"
                startFreshGame()
            }
        }
        .onChange(of: gameManager.currentMatch == nil) { _, isNil in
            if !isNil {
                activeMode = .online
                game.matchMode = .online
                setupOnlineMoveListener()
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearance {
        case 1: .light
        case 2: .dark
        default: nil
        }
    }

    private func title(for section: AppSection) -> String {
        switch section {
        case .play: "Tic Tac Toe"
        case .options: "Game Options"
        case .score: "Score"
        }
    }

    private func setDifficulty(_ level: Int) {
        difficultyManager.saveDifficultyToCloud(level: level)
        game.botLevel = level
        if activeMode == .bot {
            startFreshGame()
        }
    }

    private func newGameRequested() {
        if activeMode == .bot && !game.isGameOver && !game.board.allSatisfy(\.isEmpty) {
            showPiecePicker = true
        } else {
            startFreshGame()
        }
    }

    private func setupGame() {
        game.onlineManager = gameManager
        game.matchMode = activeMode
        game.activeGameMode = selectedGameMode
        game.botLevel = difficultyManager.selectedLevel
        difficultyManager.fetchDifficulty()
        setupOnlineMoveListener()

        if !hasSeenHowToPlay {
            showHowToPlay = true
            if lastTrackedVersion.isEmpty,
               let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                lastTrackedVersion = version
            }
        } else if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                  lastTrackedVersion != version {
            showWhatsNew = true
            lastTrackedVersion = version
        }
    }

    private func completeHowToPlay() {
        hasSeenHowToPlay = true
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              lastTrackedVersion != version else { return }

        lastTrackedVersion = version
        Task { @MainActor in
            await Task.yield()
            showWhatsNew = true
        }
    }

    private func setupOnlineMoveListener() {
        gameManager.onMoveReceived = { index in
            game.receiveOnlineMove(index: index)
        }
        gameManager.onOpponentDisconnected = {
            game.opponentDisconnected = true
        }
        gameManager.onMatchStarted = { isFirst in
            game.humanPiece = isFirst ? "X" : "O"
            game.currentToken = "X"
            game.matchMode = .online
            game.startNewGame(keepPiece: true)
        }
        gameManager.onResetReceived = {
            game.startNewGame(keepPiece: true)
        }
    }

    private func startFreshGame() {
        game.matchMode = activeMode
        game.botLevel = difficultyManager.selectedLevel
        game.startNewGame(keepPiece: true)
    }

    private func endOnlineMatch() {
        gameManager.currentMatch?.disconnect()
        gameManager.currentMatch = nil
        activeMode = .bot
        game.matchMode = .bot
        game.startNewGame()
    }
}

private struct GameSidebar: View {
    @Binding var selection: AppSection?
    let scoreX: Int
    let scoreO: Int
    let drawCount: Int

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Play", systemImage: "gamecontroller")
                    .tag(AppSection.play)
                Label("Game Options", systemImage: "slider.horizontal.3")
                    .tag(AppSection.options)
                Label("Score", systemImage: "chart.bar")
                    .tag(AppSection.score)
            }

            Section("This Session") {
                LabeledContent("X") {
                    Text(scoreX, format: .number)
                        .foregroundStyle(.blue)
                }
                LabeledContent("O") {
                    Text(scoreO, format: .number)
                        .foregroundStyle(.orange)
                }
                LabeledContent("Draws") {
                    Text(drawCount, format: .number)
                }
            }
        }
        .navigationTitle("Tic Tac Toe")
        .listStyle(.sidebar)
    }
}

private struct GameView: View {
    @ObservedObject var game: GameViewModel
    let activeMode: MatchMode
    let onNewGame: () -> Void
    let onOnlinePlay: () -> Void
    @State private var replayStep: Int?

    private var displayedBoard: [String] {
        guard let replayStep,
              game.replayBoards.indices.contains(replayStep) else {
            return game.board
        }
        return game.replayBoards[replayStep]
    }

    var body: some View {
        let isReviewing = replayStep != nil
        let moveCount = max(game.replayBoards.count - 1, 0)

        VStack(spacing: 24) {
            ScoreSummary(
                scoreX: game.scoreX,
                scoreO: game.scoreO,
                draws: game.drawCount
            )

            GameStatus(
                text: replayStep == nil ? (game.resultMessage ?? game.turnOwnerLabel) : "Reviewing game",
                isComplete: game.isGameOver,
                token: game.currentToken
            )

            BoardView(
                board: displayedBoard,
                winningLine: isReviewing ? nil : game.winningLine,
                isGameOver: game.isGameOver || isReviewing,
                isBotTurn: isReviewing || (activeMode == .bot && game.currentToken == game.botPiece),
                isOnlineOpponentTurn: isReviewing || (activeMode == .online && game.currentToken != game.humanPiece),
                selectCell: game.humanTapped
            )
            .frame(maxWidth: 520, maxHeight: 520)

            if let replayStep {
                VStack(spacing: 12) {
                    HStack {
                        Button {
                            self.replayStep = max(0, replayStep - 1)
                        } label: {
                            Label("Previous", systemImage: "chevron.left")
                        }
                        .disabled(replayStep == 0)

                        Spacer()
                        Text("Move \(replayStep) of \(moveCount)")
                            .monospacedDigit()
                        Spacer()

                        Button {
                            self.replayStep = min(moveCount, replayStep + 1)
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                        }
                        .disabled(replayStep == moveCount)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(self.replayStep ?? 0) },
                            set: { self.replayStep = Int($0.rounded()) }
                        ),
                        in: 0...Double(max(moveCount, 1)),
                        step: 1
                    )
                    .disabled(moveCount == 0)

                    Button("Done Reviewing") {
                        self.replayStep = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: 520)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            game.undoMove()
                        } label: {
                            Label(activeMode == .bot ? "Undo Turn" : "Undo Move", systemImage: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!game.canUndo)

                        Button("New Game", action: onNewGame)
                            .buttonStyle(.borderedProminent)
                    }

                    HStack {
                        Button("Play Online", action: onOnlinePlay)
                            .buttonStyle(.bordered)

                        if game.isGameOver && !game.replayBoards.isEmpty {
                            Button {
                                replayStep = 0
                            } label: {
                                Label("Review Game", systemImage: "backward.end")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .controlSize(.large)
            }
        }
        .onChange(of: game.replayBoards.count) { _, count in
            if count == 0 {
                replayStep = nil
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct ScoreSummary: View {
    let scoreX: Int
    let scoreO: Int
    let draws: Int

    var body: some View {
        HStack(spacing: 0) {
            ScoreValue(title: "X", value: scoreX, color: .blue)
            Divider().frame(height: 36)
            ScoreValue(title: "Draws", value: draws, color: .secondary)
            Divider().frame(height: 36)
            ScoreValue(title: "O", value: scoreO, color: .orange)
        }
        .frame(maxWidth: 360)
        .padding(.vertical, 8)
    }
}

private struct ScoreValue: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(value, format: .number)
                .font(.title2.weight(.semibold))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GameStatus: View {
    let text: String
    let isComplete: Bool
    let token: String

    var body: some View {
        Label {
            Text(text)
                .font(.headline)
        } icon: {
            Image(systemName: isComplete ? "flag.checkered" : "circle.fill")
                .foregroundStyle(isComplete ? AnyShapeStyle(.secondary) : AnyShapeStyle(token == "X" ? Color.blue : Color.orange))
        }
        .foregroundStyle(isComplete ? .primary : .secondary)
        .animation(.default, value: text)
    }
}

private struct BoardView: View {
    let board: [String]
    let winningLine: [Int]?
    let isGameOver: Bool
    let isBotTurn: Bool
    let isOnlineOpponentTurn: Bool
    let selectCell: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3),
                spacing: 1
            ) {
                ForEach(0..<9, id: \.self) { index in
                    BoardCell(
                        index: index,
                        piece: board[index],
                        isWinningCell: winningLine?.contains(index) == true,
                        isDisabled: !board[index].isEmpty || isGameOver || isBotTurn || isOnlineOpponentTurn,
                        action: { selectCell(index) }
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .background(.separator)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tic Tac Toe board")
    }
}

private struct BoardCell: View {
    let index: Int
    let piece: String
    let isWinningCell: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.primary.opacity(0.04)
                if !piece.isEmpty {
                    Text(piece)
                        .font(.system(size: 56, weight: .medium, design: .rounded))
                        .foregroundStyle(piece == "X" ? .blue : .orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isWinningCell {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(piece == "X" ? .blue : .orange, lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(cellDescription)
        .accessibilityHint(piece.isEmpty && !isDisabled ? "Double tap to place a piece." : "")
        .animation(.snappy, value: piece)
    }

    private var cellDescription: String {
        let row = index / 3 + 1
        let column = index % 3 + 1
        if piece.isEmpty {
            return "Row \(row), column \(column), empty"
        }
        return "Row \(row), column \(column), \(piece)"
    }
}

private struct GameOptionsView: View {
    @Binding var activeMode: MatchMode
    @Binding var selectedGameMode: GameMode
    @Binding var difficulty: Int
    let onlineAvailable: Bool
    let onOnlinePlay: () -> Void

    var body: some View {
        Form {
            Section("Players") {
                Picker("Game", selection: $activeMode) {
                    Text("Play Bot").tag(MatchMode.bot)
                    Text("Two Players").tag(MatchMode.localPassAndPlay)
                }
                .pickerStyle(.segmented)

                Button("Play Online", action: onOnlinePlay)
                    .disabled(!onlineAvailable)
            }

            Section("Rules") {
                Picker("Ruleset", selection: $selectedGameMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Text(selectedGameMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if activeMode == .bot {
                Section("Bot") {
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Rookie").tag(1)
                        Text("Cadet").tag(2)
                        Text("Tactician").tag(3)
                        Text("Veteran").tag(4)
                        Text("Nemesis").tag(5)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }
}

private struct ScoreView: View {
    let scoreX: Int
    let scoreO: Int
    let draws: Int
    let winStreak: Int
    let isGameCenterAvailable: Bool
    let onShowLeaderboard: () -> Void
    let onReset: () -> Void

    var body: some View {
        Form {
            Section("Current Score") {
                LabeledContent("X") {
                    Text(scoreX, format: .number)
                        .foregroundStyle(.blue)
                }
                LabeledContent("O") {
                    Text(scoreO, format: .number)
                        .foregroundStyle(.orange)
                }
                LabeledContent("Draws") {
                    Text(draws, format: .number)
                }
            }

            Section("Progress") {
                LabeledContent("Win Streak") {
                    Text(winStreak, format: .number)
                }
            }

            Section("Game Center") {
                Button(action: onShowLeaderboard) {
                    Label("View Leaderboard", systemImage: "trophy")
                }
                .disabled(!isGameCenterAvailable)

                if !isGameCenterAvailable {
                    Text("Sign in to Game Center to view rankings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Reset Score", role: .destructive, action: onReset)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(OnlineGameManager())
}
