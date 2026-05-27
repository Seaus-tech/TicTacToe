import SwiftUI

// MARK: - Game Data

enum Player {
    case x
    case o
    
    var name: String {
        self == .x ? "X" : "O"
    }
    
    var primaryColor: Color {
        self == .x ? Color(red: 0.1, green: 0.8, blue: 0.9) : Color(red: 1.0, green: 0.3, blue: 0.3)
    }
    
    var glowColor: Color {
        primaryColor.opacity(0.6)
    }
}

enum GameMode {
    case singlePlayer
    case multiPlayer
    case onlinePlayer
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .easy: return "Computes purely random quadrant selections. Minimal defensive response."
        case .medium: return "50% algorithmic awareness. Occasionally disrupts player trajectories."
        case .hard: return "Full tactical grid mitigation. Prioritizes offensive wins and defensive blocks."
        }
    }
}

struct Square {
    var player: Player?
}

// MARK: - Main UI View

struct ContentView: View {
    @StateObject private var onlineManager = OnlineGameManager()
    
    // Selection & Info States
    @State private var selectedMode: GameMode? = nil
    @State private var showAIPopup: Bool = false
    @State private var showMultiplayerPopup: Bool = false
    @State private var selectedDifficulty: Difficulty = .medium
    
    // Core Game State
    @State private var board: [Square] = Array(repeating: Square(player: nil), count: 9)
    @State private var activePlayer: Player = .x
    @State private var winMessage: String? = nil
    @State private var isGameOver: Bool = false
    @State private var isAITinking: Bool = false
    
    @FocusState private var focusedIndex: Int?
    
    let deepSpaceBlue = Color(red: 0.02, green: 0.05, blue: 0.1)
    let gridEdgeColor = Color(red: 0.1, green: 0.8, blue: 1.0, opacity: 0.3)
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Layer
                #if os(visionOS)
                deepSpaceBlue.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                #else
                LinearGradient(gradient: Gradient(colors: [deepSpaceBlue, .black]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                #endif
                
                if selectedMode == nil {
                    modeSelectionMenu(geometry: geometry)
                } else {
                    gameplayInterface(geometry: geometry)
                }
                
                // Popups Layer
                if showAIPopup || showMultiplayerPopup {
                    Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                }
                
                if showAIPopup {
                    aiDetailsPopup(geometry: geometry).transition(.scale.combined(with: .opacity))
                }
                
                if showMultiplayerPopup {
                    multiplayerSelectionPopup(geometry: geometry).transition(.scale.combined(with: .opacity))
                }
                
                // Custom Simulating Connection Screen Modal
                if onlineManager.showMatchmaker {
                    Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("CONNECTING TO NEO-NET MATRIX...")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        Text("Searching for available network switchboards...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: onlineManager.match) { oldMatch, newMatch in
                if newMatch != nil {
                    selectedMode = .onlinePlayer
                    resetGame()
                } else if selectedMode == .onlinePlayer {
                    selectedMode = nil
                }
            }
            .onAppear {
                setupNetworkCallbacks()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedMode)
        .animation(.easeInOut(duration: 0.25), value: showAIPopup)
        .animation(.easeInOut(duration: 0.25), value: showMultiplayerPopup)
    }
    
    // MARK: - Subviews
    
    private func modeSelectionMenu(geometry: GeometryProxy) -> some View {
        VStack(spacing: 25) {
            VStack(spacing: 8) {
                Text("TIC-TAC-TOE")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.black)
                    .foregroundColor(Player.x.primaryColor)
                    .shadow(color: Player.x.glowColor, radius: 15)
                
                Text("SELECT OPERATING MODE")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(3)
            }
            .padding(.top, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: { showAIPopup = true }) {
                    HStack { Image(systemName: "cpu"); Text("SINGLE PLAYER (VS AI)") }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Player.x.primaryColor.opacity(0.15)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Player.x.primaryColor, lineWidth: 1.5))
                }
                .buttonStyle(.plain).focused($focusedIndex, equals: 101)
                
                Button(action: { showMultiplayerPopup = true }) {
                    HStack { Image(systemName: "person.2.fill"); Text("MULTIPLAYER OPTIONS") }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Player.o.primaryColor.opacity(0.15)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Player.o.primaryColor, lineWidth: 1.5))
                }
                .buttonStyle(.plain).focused($focusedIndex, equals: 102)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: 450, maxHeight: 750)
        .frame(width: geometry.size.width, height: geometry.size.height)
        .onAppear { focusedIndex = 101 }
    }
    
    private func gameplayInterface(geometry: GeometryProxy) -> some View {
        VStack(spacing: geometry.size.height > 500 ? 30 : 15) {
            VStack(spacing: 6) {
                Text("TIC-TAC-TOE")
                    .font(.system(.title, design: .monospaced)).fontWeight(.heavy)
                    .foregroundColor(Player.x.primaryColor).shadow(color: Player.x.glowColor, radius: 10)
                
                if selectedMode == .onlinePlayer {
                    Text("VS \(onlineManager.opponentName) (\(onlineManager.localPlayerPiece == .x ? "YOU ARE X" : "YOU ARE O"))")
                        .font(.system(.caption2, design: .monospaced)).foregroundColor(.green).tracking(1)
                } else {
                    Text(selectedMode == .singlePlayer ? "MODE: AI (\(selectedDifficulty.rawValue))" : "MODE: LOCAL VS MODE")
                        .font(.system(.caption2, design: .monospaced)).foregroundColor(.gray).tracking(2)
                }
            }
            .padding(.top, 25)
            
            Spacer()
            
            // Game Grid
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<9, id: \.self) { index in
                    Button(action: { handleTap(at: index) }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(focusedIndex == index ? Player.x.primaryColor : gridEdgeColor, lineWidth: focusedIndex == index ? 3 : 1.5)
                                .background(RoundedRectangle(cornerRadius: 18).fill(focusedIndex == index ? deepSpaceBlue.opacity(0.9) : deepSpaceBlue.opacity(0.6)))
                                .aspectRatio(1.0, contentMode: .fit)
                                .shadow(color: focusedIndex == index ? Player.x.glowColor : Color.clear, radius: focusedIndex == index ? 12 : 0)
                            
                            if let player = board[index].player {
                                NeonPieceView(player: player)
                            }
                        }
                    }
                    .buttonStyle(GridSquareButtonStyle())
                    .focused($focusedIndex, equals: index)
                }
            }
            .padding(.horizontal, 20)
            .disabled(isGameOver || isAITinking || (selectedMode == .onlinePlayer && !onlineManager.isMyTurn))
            
            Spacer()
            
            // Status turn / connection banner
            Group {
                if let message = winMessage {
                    Text(message).font(.title3).bold().foregroundColor(.green).shadow(color: .green, radius: 8)
                } else if selectedMode == .onlinePlayer {
                    Text(onlineManager.isMyTurn ? "YOUR TURN" : "WAITING FOR OPPONENT...")
                        .font(.title3).bold()
                        .foregroundColor(onlineManager.isMyTurn ? Player.x.primaryColor : .gray)
                        .shadow(color: onlineManager.isMyTurn ? Player.x.glowColor : .clear, radius: 8)
                } else if isAITinking {
                    Text("AI IS COMPUTING...").font(.title3).bold().foregroundColor(Player.o.primaryColor).shadow(color: Player.o.glowColor, radius: 8)
                } else {
                    HStack(spacing: 8) {
                        Text("Turn:").foregroundColor(.gray)
                        Text(activePlayer.name).foregroundColor(activePlayer.primaryColor).font(.title3).bold().shadow(color: activePlayer.glowColor, radius: 8)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button(action: {
                    if selectedMode == .onlinePlayer { onlineManager.sendResetRequest() }
                    resetGame()
                }) {
                    Text("RESET").font(.callout).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.gray.opacity(0.2)).cornerRadius(18)
                }
                .buttonStyle(.plain).focused($focusedIndex, equals: 10)
                
                Button(action: { selectedMode = nil; onlineManager.match = nil; resetGame() }) {
                    Text("MAIN MENU").font(.callout).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient(gradient: Gradient(colors: [Player.x.primaryColor, Player.o.primaryColor]), startPoint: .leading, endPoint: .trailing)).cornerRadius(18)
                }
                .buttonStyle(.plain).focused($focusedIndex, equals: 11)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 30).frame(maxWidth: 450, maxHeight: 750).frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private func aiDetailsPopup(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "cpu.fill").font(.title2).foregroundColor(Player.o.primaryColor)
                Text("AI INITIALIZATION MATRIX").font(.system(.headline, design: .monospaced)).foregroundColor(.white)
            }
            Text("Configure runtime operations for NEO-CORE v1.5 below.").font(.caption).foregroundColor(.gray)
            HStack(spacing: 10) {
                ForEach(Difficulty.allCases) { diff in
                    Button(action: { selectedDifficulty = diff }) {
                        Text(diff.rawValue).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(selectedDifficulty == diff ? .black : .white)
                            .padding(.vertical, 8).frame(maxWidth: .infinity).background(selectedDifficulty == diff ? Player.x.primaryColor : Color.gray.opacity(0.15)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("BEHAVIOR PROFILE:").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                Text(selectedDifficulty.description).font(.system(size: 11)).foregroundColor(.white).fixedSize(horizontal: false, vertical: true).lineLimit(2)
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(deepSpaceBlue.opacity(0.5)).cornerRadius(10)
            Divider().background(gridEdgeColor)
            HStack {
                Spacer()
                Button(action: { showAIPopup = false; selectedMode = .singlePlayer; focusedIndex = 0 }) {
                    Text("OK").font(.subheadline).fontWeight(.bold).foregroundColor(.black).padding(.horizontal, 30).padding(.vertical, 10).background(Player.x.primaryColor).cornerRadius(10)
                }
                .buttonStyle(.plain).focused($focusedIndex, equals: 200)
            }
        }
        .padding(22).frame(width: min(geometry.size.width - 40, 400), height: 350).background(RoundedRectangle(cornerRadius: 24).fill(deepSpaceBlue.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Player.o.primaryColor.opacity(0.5), lineWidth: 2)).shadow(color: Player.o.glowColor.opacity(0.3), radius: 30)
        .onAppear { focusedIndex = 200 }
    }

    private func multiplayerSelectionPopup(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "network").font(.title2).foregroundColor(Player.x.primaryColor)
                Text("MULTIPLAYER ROUTER").font(.system(.headline, design: .monospaced)).foregroundColor(.white)
            }
            Text("Select matchmaking pipeline to link target clients.").font(.caption).foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Button(action: { showMultiplayerPopup = false; selectedMode = .multiPlayer; focusedIndex = 0 }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("LOCAL DOUBLE PLAYER")
                    }
                    .font(.subheadline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.gray.opacity(0.15)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Player.o.primaryColor.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Button(action: { showMultiplayerPopup = false; onlineManager.findMatch() }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("QUANTUM ONLINE MATRIX")
                    }
                    .font(.subheadline).bold().foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Player.x.primaryColor).cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(gridEdgeColor)
            
            Button(action: { showMultiplayerPopup = false }) {
                Text("CANCEL").font(.caption).bold().foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(22).frame(width: min(geometry.size.width - 40, 380), height: 300).background(RoundedRectangle(cornerRadius: 24).fill(deepSpaceBlue.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Player.x.primaryColor.opacity(0.5), lineWidth: 2)).shadow(color: Player.x.glowColor.opacity(0.3), radius: 30)
    }
    
    // MARK: - Core Operations & Match Logic
    
    private func setupNetworkCallbacks() {
        onlineManager.onReceiveMove = { remoteIndex in
            withAnimation {
                let opponentPiece: Player = (onlineManager.localPlayerPiece == .x) ? .o : .x
                if board[remoteIndex].player == nil {
                    board[remoteIndex].player = opponentPiece
                    
                    // Run win evaluations immediately on the incoming network packet
                    if !checkGameState() {
                        activePlayer = onlineManager.localPlayerPiece
                    }
                }
            }
        }
        
        onlineManager.onReceiveReset = {
            self.resetGame()
        }
    }
    
    private func handleTap(at index: Int) {
        guard board[index].player == nil && !isAITinking && !isGameOver else { return }
        
        if selectedMode == .onlinePlayer {
            guard onlineManager.isMyTurn else { return }
            
            // 1. Mark tile locally
            board[index].player = onlineManager.localPlayerPiece
            
            // 2. Transmit packet data through the node server
            onlineManager.sendMove(at: index)
            
            // 3. Immediately evaluate if this placement ended the game
            if checkGameState() { return }
            
            // 4. Pass turn state to opponent
            activePlayer = (onlineManager.localPlayerPiece == .x) ? .o : .x
        } else {
            board[index].player = activePlayer
            if checkGameState() { return }
            activePlayer = (activePlayer == .x) ? .o : .x
            if selectedMode == .singlePlayer && activePlayer == .o { runAIEngineLoop() }
        }
    }
    
    private func runAIEngineLoop() {
        isAITinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let winPatterns: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
            var chosenMove: Int? = nil
            
            switch selectedDifficulty {
            case .easy: chosenMove = getRandomMove()
            case .medium: chosenMove = Double.random(in: 0...1) > 0.5 ? computeTacticalMove(winPatterns: winPatterns) : getRandomMove()
            case .hard: chosenMove = computeTacticalMove(winPatterns: winPatterns)
            }
            
            if chosenMove == nil { chosenMove = getRandomMove() }
            if let aiIndex = chosenMove { board[aiIndex].player = .o }
            isAITinking = false
            if !checkGameState() { activePlayer = .x }
        }
    }
    
    private func getRandomMove() -> Int? {
        board.indices.filter { board[$0].player == nil }.randomElement()
    }
    
    private func computeTacticalMove(winPatterns: [[Int]]) -> Int? {
        for pattern in winPatterns {
            if pattern.filter({ board[$0].player == .o }).count == 2 && pattern.filter({ board[$0].player == nil }).count == 1 {
                return pattern.first(where: { board[$0].player == nil })
            }
        }
        for pattern in winPatterns {
            if pattern.filter({ board[$0].player == .x }).count == 2 && pattern.filter({ board[$0].player == nil }).count == 1 {
                return pattern.first(where: { board[$0].player == nil })
            }
        }
        return nil
    }
    
    private func checkGameState() -> Bool {
        // Evaluate based on who just finished laying down their tile
        let currentTurner: Player = (selectedMode == .onlinePlayer) ? (onlineManager.isMyTurn ? onlineManager.localPlayerPiece : (onlineManager.localPlayerPiece == .x ? .o : .x)) : activePlayer
        
        if checkWin(for: currentTurner) {
            if selectedMode == .onlinePlayer {
                winMessage = currentTurner == onlineManager.localPlayerPiece ? "YOU WIN!" : "\(onlineManager.opponentName) WINS!"
            } else {
                winMessage = selectedMode == .singlePlayer && currentTurner == .o ? "AI Core Wins!" : "Player \(currentTurner.name) Wins!"
            }
            isGameOver = true
            focusedIndex = 10
            return true
        } else if board.allSatisfy({ $0.player != nil }) {
            winMessage = "It's a Tie Matrix!"
            isGameOver = true
            focusedIndex = 10
            return true
        }
        return false
    }
    
    private func checkWin(for player: Player) -> Bool {
        let winPatterns: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
        return winPatterns.contains { pattern in pattern.allSatisfy { board[$0].player == player } }
    }
    
    private func resetGame() {
        board = Array(repeating: Square(player: nil), count: 9)
        activePlayer = .x
        winMessage = nil
        isGameOver = false
        isAITinking = false
        focusedIndex = 0
        if selectedMode == .onlinePlayer {
            activePlayer = .x
            onlineManager.isMyTurn = (onlineManager.localPlayerPiece == .x)
        }
    }
}

// MARK: - Subcomponents

struct GridSquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NeonPieceView: View {
    let player: Player
    var body: some View {
        GeometryReader { pieceGeo in
            Group {
                if player == .x {
                    Image(systemName: "xmark").resizable().aspectRatio(contentMode: .fit).padding(pieceGeo.size.width * 0.24)
                } else {
                    Circle().stroke(lineWidth: pieceGeo.size.width * 0.09).padding(pieceGeo.size.width * 0.18)
                }
            }
            .foregroundColor(player.primaryColor).shadow(color: player.glowColor, radius: 12)
        }
    }
}
