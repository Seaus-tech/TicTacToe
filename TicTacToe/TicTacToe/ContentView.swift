import SwiftUI

enum MatchMode {
    case online
    case bot
    case localPassAndPlay
}

struct ContentView: View {
    @StateObject private var gameManager = OnlineGameManager()
    @StateObject private var difficultyManager = BotDifficultyManager()
    
    @State private var board: [String] = Array(repeating: "", count: 9)
    @State private var isYourTurn: Bool = true
    @State private var localToken: String = "X"
    @State private var winMessage: String? = nil
    @State private var winStreak: Int = 0
    @State private var totalCareerWins: Int = 0
    @AppStorage("appAppearance") private var appearance = 0
    @State private var showWhatsNew: Bool = false
    @AppStorage("lastTrackedVersion") private var lastTrackedVersion: String = ""
    @State private var activeMode: MatchMode = .bot
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.primary.opacity(0.045)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    let horizontalPadding = min(20, geometry.size.width * 0.06)
                    let compactLayout = geometry.size.height < 620
                    let reservedHeight: CGFloat = activeMode == .bot ? 420 : 340
                    let boardSide = max(110, min(420, min(geometry.size.width - (horizontalPadding * 2), geometry.size.height - reservedHeight)))
                    
                    VStack(spacing: compactLayout ? 12 : 20) {
                        LiquidHeaderCard
                        
                        if gameManager.currentMatch == nil {
                            ModeSelectionTabs
                        }
                        
                        if gameManager.currentMatch == nil && activeMode == .bot {
                            DifficultySelectorView(
                                difficultyManager: difficultyManager,
                                saveAction: { tier in difficultyManager.saveDifficultyToCloud(level: tier) },
                                selectedLevel: difficultyManager.selectedLevel
                            )
                            .padding(.horizontal, 4)
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
                #if os(macOS)
                ToolbarItem(placement: .navigation) {
                    Button(action: { showWhatsNew = true }) {
                        Label("What's New", systemImage: "sparkles")
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showWhatsNew = true }) {
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
        }
        .onAppear {
            setupIncomingMoveListener()
            difficultyManager.fetchDifficulty()
            if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                if lastTrackedVersion != currentVersion {
                    showWhatsNew = true
                    lastTrackedVersion = currentVersion
                }
            }
        }
    }
    
    private var LiquidHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gameManager.currentMatch == nil ? "Ready to play" : "Online game")
                    .font(.headline)
                Text(gameManager.isPlayerAuthenticated ? gameManager.localPlayerName : "Play on this device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }
    
    private var ModeSelectionTabs: some View {
        HStack(spacing: 8) {
            Button(action: { activeMode = .bot; resetMatchBoard() }) {
                Label("Play Bot", systemImage: "cpu")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .bot)
            
            Button(action: { activeMode = .localPassAndPlay; resetMatchBoard() }) {
                Label("Two Players", systemImage: "person.2")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle(isProminent: activeMode == .localPassAndPlay)
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }
    
    private func MatrixGameBoard(sideLength: CGFloat) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        Button(action: { handleCellTap(at: index) }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.secondary.opacity(0.1))
                                if board[index] == "X" {
                                    Text("X").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundColor(.blue)
                                } else if board[index] == "O" {
                                    Text("O").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundColor(.orange)
                                }
                            }
                            .aspectRatio(1.0, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                        .disabled(!board[index].isEmpty || winMessage != nil || !isYourTurn)
                    }
                }
            }
        }
        .padding(16)
        .liquidGlassStyle(cornerRadius: 28)
        .frame(width: sideLength, height: sideLength)
    }
    
    private var LiquidActionControls: some View {
        VStack(spacing: 16) {
            if let winMessage = winMessage {
                Text(winMessage).font(.headline)
            }
            HStack(spacing: 12) {
                Button(action: {
                    gameManager.presentMatchmakerInterface()
                }) {
                    Label("Play Online", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle()
                
                Button(action: resetMatchBoard) {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButtonStyle(isProminent: true)
            }
        }
        .padding()
        .liquidGlassStyle(cornerRadius: 20)
    }
    
    private func handleCellTap(at index: Int) {
        board[index] = localToken
        processMatrixState(for: localToken)
        if activeMode == .bot {
            isYourTurn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { executeBotMove() }
        } else if activeMode == .localPassAndPlay {
            localToken = (localToken == "X") ? "O" : "X"
        }
    }
    
    private func executeBotMove() {
        guard winMessage == nil && board.contains("") else { return }
        let botToken = (localToken == "X") ? "O" : "X"
        if difficultyManager.selectedLevel >= 4, let defensiveBlockMove = findStrategicCell(for: localToken) {
            board[defensiveBlockMove] = botToken
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
        let lines = [(0,1,2), (3,4,5), (6,7,8), (0,3,6), (1,4,7), (2,5,8), (0,4,8), (2,4,6)]
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
    
    private func processMatrixState(for token: String) {
        if checkWinCondition(for: token) {
            winMessage = "MATRIX RESOLVED: \(token) WINS"
        } else if !board.contains("") {
            winMessage = "QUANTUM STALEMATE DETECTED"
        }
    }
    
    private func checkWinCondition(for player: String) -> Bool {
        let lines = [(0,1,2), (3,4,5), (6,7,8), (0,3,6), (1,4,7), (2,5,8), (0,4,8), (2,4,6)]
        for (a, b, c) in lines {
            if board[a] == player && board[b] == player && board[c] == player {
                return true
            }
        }
        return false
    }
    
    private func setupIncomingMoveListener() {}
    private func resetMatchBoard() {
        board = Array(repeating: "", count: 9)
        winMessage = nil
        isYourTurn = true
        localToken = "X"
    }
}
