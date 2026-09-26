import SwiftUI
import GameKit

enum MatchMode {
    case online
    case bot
    case localPassAndPlay
}

struct ContentView: View {
    @EnvironmentObject private var gameManager: OnlineGameManager
    @StateObject private var game             = GameViewModel()
    @StateObject private var difficultyManager = BotDifficultyManager()

    @State private var activeMode: MatchMode  = .bot
    @AppStorage("appAppearance") private var appearance = 0
    @State private var showWhatsNew: Bool     = false
    @AppStorage("lastTrackedVersion") private var lastTrackedVersion: String = ""

    // Piece picker sheet
    @State private var showPiecePicker: Bool  = false

    // Pulse animation state for turn indicator
    @State private var pulseActive: Bool      = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Proper adaptive background — light grey in light mode, near-black in dark mode
                Color(light: Color(white: 0.94), dark: Color(white: 0.09))
                    .ignoresSafeArea()

                GeometryReader { geo in
                    #if os(macOS)
                    macOSLayout(geo: geo)
                    #else
                    iOSLayout(geo: geo)
                    #endif
                }
            }
            .navigationTitle("NEO-GRID")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .navigation) {
                    Button { showWhatsNew = true } label: {
                        Label("What's New", systemImage: "sparkles")
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showWhatsNew = true } label: {
                        Label("What's New", systemImage: "sparkles")
                    }
                }
                #endif
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag(0)
                            Text("Light").tag(1)
                            Text("Dark").tag(2)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                }
            }
        }
        .tint(.blue)
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView(isPresented: $showWhatsNew)
                .preferredColorScheme(appearance == 1 ? .light : appearance == 2 ? .dark : nil)
        }
        .sheet(isPresented: $showPiecePicker) {
            PiecePickerSheet(humanPiece: $game.humanPiece) {
                showPiecePicker = false
                startFreshGame()
            }
            .preferredColorScheme(appearance == 1 ? .light : appearance == 2 ? .dark : nil)
        }
        .alert("Opponent Disconnected", isPresented: $game.opponentDisconnected) {
            Button("OK") { endOnlineMatch() }
        } message: {
            Text("Your opponent left the game.")
        }
        .onAppear {
            setupGame()
        }
        .onChange(of: gameManager.currentMatch == nil) { _, isNil in
            if !isNil {
                activeMode = .online
                game.matchMode = .online
                setupOnlineMoveListener()
            }
        }
    }

    // MARK: - macOS: Side-by-side layout
    @ViewBuilder
    private func macOSLayout(geo: GeometryProxy) -> some View {
        let pad: CGFloat    = 20
        let panelW: CGFloat = 260
        // Board fills the left square, capped so it never exceeds the height
        let boardSide = min(geo.size.width - panelW - pad * 3, geo.size.height - pad * 2 - 50)
        let safeSide  = max(200, boardSide)

        HStack(alignment: .top, spacing: pad) {
            // Left: the board, score bar, and turn indicator centred vertically
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                scoreBar
                turnIndicator
                gameBoard(sideLength: safeSide)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity)

            // Right: controls panel
            VStack(spacing: 12) {
                headerCard
                if gameManager.currentMatch == nil {
                    modeSelectionTabs
                }
                if gameManager.currentMatch == nil && activeMode == .bot {
                    DifficultySelectorView(
                        difficultyManager: difficultyManager,
                        saveAction: { tier in
                            difficultyManager.saveDifficultyToCloud(level: tier)
                            game.botLevel = tier
                        },
                        selectedLevel: difficultyManager.selectedLevel
                    )
                }
                Spacer(minLength: 0)
                actionControls
            }
            .frame(width: panelW, alignment: .top)
            .frame(maxHeight: .infinity)
        }
        .padding(pad)
    }

    // MARK: - iOS: Vertical stacked layout
    @ViewBuilder
    private func iOSLayout(geo: GeometryProxy) -> some View {
        let hPad: CGFloat    = min(20, geo.size.width * 0.05)
        let compact          = geo.size.height < 600
        let spacing: CGFloat = compact ? 8 : 12

        let headerH: CGFloat    = 74
        let modeH: CGFloat      = gameManager.currentMatch == nil ? 68 : 0
        let diffH: CGFloat      = (gameManager.currentMatch == nil && activeMode == .bot) ? 76 : 0
        let scoreH: CGFloat     = 60
        let indicatorH: CGFloat = 28
        let controlsH: CGFloat  = activeMode == .bot ? 120 : 100
        let totalFixed          = headerH + modeH + diffH + scoreH + indicatorH + controlsH
                                  + spacing * 6
        let navBarH: CGFloat    = 50
        let boardSide = max(180, min(
            geo.size.width  - hPad * 2,
            geo.size.height - totalFixed - navBarH
        ))

        VStack(spacing: spacing) {
            headerCard
            if gameManager.currentMatch == nil {
                modeSelectionTabs
            }
            if gameManager.currentMatch == nil && activeMode == .bot {
                DifficultySelectorView(
                    difficultyManager: difficultyManager,
                    saveAction: { tier in
                        difficultyManager.saveDifficultyToCloud(level: tier)
                        game.botLevel = tier
                    },
                    selectedLevel: difficultyManager.selectedLevel
                )
                .padding(.horizontal, 4)
            }
            scoreBar
            turnIndicator
            gameBoard(sideLength: boardSide)
            actionControls
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, hPad)
        .padding(.vertical, compact ? 6 : 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(gameManager.currentMatch != nil ? "Online game" : "Ready to play")
                    .font(.headline)
                Text(gameManager.isPlayerAuthenticated ? gameManager.localPlayerName : "Play on this device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()

            // Win streak badge
            if game.winStreak > 1 {
                VStack(spacing: 2) {
                    Text("🔥")
                    Text("\(game.winStreak)")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }

    // MARK: - Mode Selection
    private var modeSelectionTabs: some View {
        HStack(spacing: 8) {
            Button {
                activeMode = .bot
                game.matchMode = .bot
                showPiecePicker = true
            } label: {
                Label("Play Bot", systemImage: "cpu")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .bot)

            Button {
                activeMode = .localPassAndPlay
                game.matchMode = .localPassAndPlay
                game.humanPiece = "X"   // Two-player: X always goes first, no choice needed
                startFreshGame()
            } label: {
                Label("Two Players", systemImage: "person.2")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .localPassAndPlay)
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }

    // MARK: - Score Bar
    private var scoreBar: some View {
        HStack {
            VStack(spacing: 4) {
                Text("X")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.blue)
                Text("\(game.scoreX)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: game.scoreX)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .frame(width: 1, height: 36)
                .foregroundColor(.secondary.opacity(0.3))

            VStack(spacing: 4) {
                Text("DRAWS")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.secondary)
                Text("\(game.drawCount)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: game.drawCount)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .frame(width: 1, height: 36)
                .foregroundColor(.secondary.opacity(0.3))

            VStack(spacing: 4) {
                Text("O")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.orange)
                Text("\(game.scoreO)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: game.scoreO)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .liquidGlassStyle(cornerRadius: 16)
    }

    // MARK: - Turn Indicator
    private var turnIndicator: some View {
        HStack(spacing: 8) {
            if !game.isGameOver {
                Circle()
                    .fill(game.currentToken == "X" ? Color.blue : Color.orange)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseActive ? 1.4 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: pulseActive
                    )
                Text(game.turnOwnerLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.secondary)
            } else if let msg = game.resultMessage {
                Text(msg)
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundColor(.primary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: game.isGameOver)
        .onAppear { pulseActive = true }
        .onChange(of: game.currentToken) { pulseActive = true }
    }

    // MARK: - Game Board
    private func gameBoard(sideLength: CGFloat) -> some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        cellView(index: index)
                    }
                }
            }
        }
        .padding(14)
        .liquidGlassStyle(cornerRadius: 28)
        .frame(width: sideLength, height: sideLength)
    }

    @ViewBuilder
    private func cellView(index: Int) -> some View {
        let piece       = game.board[index]
        let isWinCell   = game.winningLine?.contains(index) ?? false
        let isDisabled  = !piece.isEmpty || game.isGameOver ||
                          (activeMode == .bot && game.currentToken == game.botPiece) ||
                          (activeMode == .online && game.currentToken != game.humanPiece)

        Button {
            game.humanTapped(index: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isWinCell
                            ? (piece == "X" ? Color.blue.opacity(0.25) : Color.orange.opacity(0.25))
                            : Color.secondary.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isWinCell
                                    ? (piece == "X" ? Color.blue : Color.orange)
                                    : Color.clear,
                                lineWidth: 2.5
                            )
                    )
                    .shadow(
                        color: isWinCell
                            ? (piece == "X" ? .blue.opacity(0.5) : .orange.opacity(0.5))
                            : .clear,
                        radius: isWinCell ? 8 : 0
                    )

                if piece == "X" {
                    Text("X")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                } else if piece == "O" {
                    Text("O")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: piece)
        .animation(.easeInOut(duration: 0.4), value: isWinCell)
    }

    // MARK: - Action Controls
    private var actionControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    gameManager.presentMatchmakerInterface()
                } label: {
                    Label("Play Online", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle()
                .disabled(!gameManager.isPlayerAuthenticated)

                Button {
                    if activeMode == .localPassAndPlay {
                        // Two-player: no piece choice, just reset
                        startFreshGame()
                    } else if game.isGameOver || game.board.allSatisfy({ $0.isEmpty }) {
                        startFreshGame()
                    } else {
                        showPiecePicker = true
                    }
                } label: {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle(isProminent: true)
            }

            if game.scoreX > 0 || game.scoreO > 0 {
                Button {
                    game.resetScores()
                } label: {
                    Label("Reset Scores", systemImage: "xmark.circle")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }

    // MARK: - Setup
    private func setupGame() {
        game.onlineManager = gameManager
        game.matchMode     = activeMode
        game.botLevel      = difficultyManager.selectedLevel
        difficultyManager.fetchDifficulty()
        setupOnlineMoveListener()

        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           lastTrackedVersion != ver {
            showWhatsNew        = true
            lastTrackedVersion  = ver
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
            game.humanPiece  = isFirst ? "X" : "O"
            game.currentToken = "X"
            game.matchMode   = .online
            game.startNewGame(keepPiece: true)
        }
        gameManager.onResetReceived = {
            game.startNewGame(keepPiece: true)
        }
    }

    private func startFreshGame() {
        game.matchMode = activeMode
        game.botLevel  = difficultyManager.selectedLevel
        game.startNewGame(keepPiece: true)
    }

    private func endOnlineMatch() {
        gameManager.currentMatch?.disconnect()
        gameManager.currentMatch = nil
        activeMode    = .bot
        game.matchMode = .bot
        game.startNewGame()
    }
}
