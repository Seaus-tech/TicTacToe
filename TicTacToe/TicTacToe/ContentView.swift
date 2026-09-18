import SwiftUI

// Lightweight enum to handle our three game styles
enum MatchMode {
    case online, bot, localPassAndPlay
}

private enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var gameManager: OnlineGameManager
    
    // Core game state arrays
    @State private var board: [String] = Array(repeating: "", count: 9)
    @State private var isYourTurn: Bool = true
    @State private var localToken: String = "X"
    @State private var winMessage: String? = nil
    @State private var winStreak: Int = 0
    @State private var totalCareerWins: Int = 0
    @AppStorage("appAppearance") private var appearance = AppAppearance.system.rawValue
    
    // Default to Bot match when offline, automatically shifts to .online when Game Center connects
    @State private var activeMode: MatchMode = .bot
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.primary.opacity(0.045)
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    let horizontalPadding = min(20, geometry.size.width * 0.06)
                    let compactLayout = geometry.size.height < 620
                    // Keep controls visible first; only the board contracts in short windows.
                    let reservedHeight: CGFloat = gameManager.currentMatch == nil ? 340 : 235
                    let boardSide = max(
                        110,
                        min(
                            420,
                            geometry.size.width - (horizontalPadding * 2),
                            geometry.size.height - reservedHeight
                        )
                    )

                    VStack(spacing: compactLayout ? 12 : 20) {
                        LiquidHeaderCard

                        if gameManager.currentMatch == nil {
                            ModeSelectionTabs
                        }

                        MatrixGameBoard(sideLength: boardSide)
                        LiquidActionControls
                    }
                    .frame(maxWidth: 600)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, compactLayout ? 10 : 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle("Tic-Tac-Toe")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Picker("Appearance", selection: $appearance) {
                            ForEach(AppAppearance.allCases) { option in
                                Text(option.title)
                                    .tag(option.rawValue)
                            }
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    .accessibilityLabel("Appearance")
                }
            }
        }
        .tint(.blue)
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onAppear {
            setupIncomingMoveListener()
        }
        .onChange(of: gameManager.currentMatch) { _, newMatch in
            if newMatch != nil {
                activeMode = .online
            }
        }
    }
    
    // MARK: - Game status
    private var LiquidHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(gameManager.currentMatch == nil ? "Ready to play" : "Online game")
                    .font(.headline)
                Text(gameManager.isPlayerAuthenticated ? gameManager.localPlayerName : "Play on this device or find an opponent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(gameManager.isPlayerAuthenticated ? Color.green : Color.secondary)
                .frame(width: 10, height: 10)
                .accessibilityLabel(gameManager.isPlayerAuthenticated ? "Game Center connected" : "Playing locally")
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
    
    // MARK: - Game mode
    private var ModeSelectionTabs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Game mode")
                .font(.headline)

            HStack(spacing: 8) {
            Button(action: { activeMode = .bot; resetMatchBoard() }) {
                Label("Play Bot", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .bot)
            .tint(activeMode == .bot ? .blue : .gray)
            
            Button(action: { activeMode = .localPassAndPlay; resetMatchBoard() }) {
                Label("Two Players", systemImage: "person.2")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .localPassAndPlay)
            .tint(activeMode == .localPassAndPlay ? .blue : .secondary)
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }
    
    // MARK: - Board
    private func MatrixGameBoard(sideLength: CGFloat) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        MatrixCell(at: index)
                    }
                }
            }
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.2), value: isYourTurn)
        .liquidGlassStyle(cornerRadius: 28)
        .shadow(color: .black.opacity(0.08), radius: 14, y: 5)
        .frame(width: sideLength, height: sideLength)
    }
    
    // MARK: - Board cell
    @ViewBuilder
    private func MatrixCell(at index: Int) -> some View {
        Button(action: {
            handleCellTap(at: index)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.10))
                
                if board[index] == "X" {
                    Text("X")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                } else if board[index] == "O" {
                    Text("O")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(board[index].isEmpty ? "Empty square" : "\(board[index])")
        .disabled(!board[index].isEmpty || winMessage != nil || !isYourTurn)
    }
}
extension ContentView {
    
    // MARK: - Game controls
    private var LiquidActionControls: some View {
        VStack(spacing: 16) {
            if let winMessage = winMessage {
                Text(winMessage)
                    .font(.headline)
                    .foregroundStyle(.primary)
            } else {
                Group {
                    switch activeMode {
                    case .online:
                        Label(isYourTurn ? "Your turn" : "Opponent's turn", systemImage: isYourTurn ? "hand.tap.fill" : "hourglass")
                    case .bot:
                        Label(isYourTurn ? "Your turn" : "Bot is thinking", systemImage: isYourTurn ? "hand.tap.fill" : "cpu")
                    case .localPassAndPlay:
                        Label("Player \(localToken)'s turn", systemImage: "person.fill")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                if gameManager.currentMatch == nil {
                    Button(action: {
                        gameManager.presentMatchmakerInterface()
                    }) {
                        Label("Play Online", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .liquidGlassButtonStyle()
                }
                
                Button(action: resetMatchBoard) {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle(isProminent: true)
            }
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .liquidGlassStyle(cornerRadius: 20)
    }

    // MARK: - Multiplatform Haptic Configurations
    private func triggerImpactFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    private func triggerSuccessFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
    
    // MARK: - Dynamic Game Tap Handlers
    private func handleCellTap(at index: Int) {
        board[index] = localToken
        triggerImpactFeedback()
        processMatrixState(for: board[index])
        
        guard winMessage == nil else { return }
        
        // Split Engine Routing Logic
        if activeMode == .online {
            gameManager.sendGameMove(cellIndex: index)
            isYourTurn = false
        } else if activeMode == .bot {
            isYourTurn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.executeBotMove()
            }
        } else if activeMode == .localPassAndPlay {
            // Swap turns and tokens instantly for offline pass-and-play matches
            localToken = (localToken == "X") ? "O" : "X"
            isYourTurn = true
        }
    }
    
    private func setupIncomingMoveListener() {
        gameManager.onMoveReceived = { opponentIndex in
            let opponentToken = (localToken == "X") ? "O" : "X"
            if board[opponentIndex].isEmpty && winMessage == nil {
                board[opponentIndex] = opponentToken
                triggerImpactFeedback()
                isYourTurn = true
                processMatrixState(for: opponentToken)
            }
        }
    }
    
    private func processMatrixState(for token: String) {
        if checkWinCondition(for: token) {
            winMessage = "MATRIX RESOLVED: \(token) WINS"
            triggerSuccessFeedback()
            
            // Only report achievements to the live Game Center dashboard if playing online or vs the Bot
            if activeMode != .localPassAndPlay {
                if token == localToken {
                    winStreak += 1
                    totalCareerWins += 1
                    gameManager.reportScoreToLeaderboard(wins: totalCareerWins)
                    gameManager.reportWinAchievement(currentStreakCount: winStreak)
                } else {
                    winStreak = 0
                }
            }
        } else if !board.contains("") {
            winMessage = "QUANTUM STALEMATE DETECTED"
        }
    }
    
    // MARK: - Evaluation Logic (Glitch Resistant Layout)
    private func checkWinCondition(for player: String) -> Bool {
        let zero = 0;  let one = 1;   let two = 2
        let three = 3; let four = 4;  let five = 5
        let six = 6;   let seven = 7; let eight = 8
        
        let row1 = board[zero] == player && board[one] == player && board[two] == player
        let row2 = board[three] == player && board[four] == player && board[five] == player
        let row3 = board[six] == player && board[seven] == player && board[eight] == player
        
        let col1 = board[zero] == player && board[three] == player && board[six] == player
        let col2 = board[one] == player && board[four] == player && board[seven] == player
        let col3 = board[two] == player && board[five] == player && board[eight] == player
        
        let diag1 = board[zero] == player && board[four] == player && board[eight] == player
        let diag2 = board[two] == player && board[four] == player && board[six] == player
        
        return row1 || row2 || row3 || col1 || col2 || col3 || diag1 || diag2
    }
    
    // MARK: - Strategic Bot Engine Routine
    private func executeBotMove() {
        guard winMessage == nil && board.contains("") else { return }
        let botToken = (localToken == "X") ? "O" : "X"
        
        if let winningMove = findStrategicCell(for: botToken) {
            board[winningMove] = botToken
            processMatrixState(for: botToken)
            isYourTurn = true
            return
        }
        
        if let defensiveBlockMove = findStrategicCell(for: localToken) {
            board[defensiveBlockMove] = botToken
            processMatrixState(for: botToken)
            isYourTurn = true
            return
        }
        
        let centerIndex = 4
        if board[centerIndex].isEmpty {
            board[centerIndex] = botToken
            processMatrixState(for: botToken)
            isYourTurn = true
            return
        }
        
        let openCells = board.enumerated().filter { $0.element.isEmpty }.map { $0.offset }
        if let randomChoice = openCells.randomElement() {
            board[randomChoice] = botToken
            processMatrixState(for: botToken)
            isYourTurn = true
        }
    }
    
    private func findStrategicCell(for token: String) -> Int? {
        let zero = 0;  let one = 1;   let two = 2
        let three = 3; let four = 4;  let five = 5
        let six = 6;   let seven = 7; let eight = 8
        
        let lines = [
            (zero, one, two), (three, four, five), (six, seven, eight),
            (zero, three, six), (one, four, seven), (two, five, eight),
            (zero, four, eight), (two, four, six)
        ]
        
        for (a, b, c) in lines {
            let cells = [board[a], board[b], board[c]]
            if cells.filter({ $0 == token }).count == 2 && cells.contains("") {
                if board[a].isEmpty { return a }
                if board[b].isEmpty { return b }
                if board[c].isEmpty { return c }
            }
        }
        return nil
    }
    
    private func resetMatchBoard() {
        board = Array(repeating: "", count: 9)
        winMessage = nil
        isYourTurn = true
        localToken = "X"
        triggerImpactFeedback()
    }
}

#Preview {
    ContentView()
        .environmentObject(OnlineGameManager())
}
