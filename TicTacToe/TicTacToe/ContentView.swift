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
    // Selection & Info States
    @State private var selectedMode: GameMode? = nil
    @State private var showAIPopup: Bool = false
    @State private var selectedDifficulty: Difficulty = .medium
    
    // Core Game State
    @State private var board: [Square] = Array(repeating: Square(player: nil), count: 9)
    @State private var activePlayer: Player = .x
    @State private var winMessage: String? = nil
    @State private var isGameOver: Bool = false
    @State private var isAITinking: Bool = false
    
    // Track focus states for tvOS / macOS / visionOS navigation mapping
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
                
                // Screen Swapping Layer
                if selectedMode == nil {
                    // 1. Initial Menu Mode Selection Screen
                    modeSelectionMenu(geometry: geometry)
                } else {
                    // 2. Active Gameplay Screen
                    gameplayInterface(geometry: geometry)
                }
                
                // 3. Immersive Custom AI Popup Overlaid Window
                if showAIPopup {
                    Color.black.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    aiDetailsPopup(geometry: geometry)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedMode)
        .animation(.easeInOut(duration: 0.25), value: showAIPopup)
    }
    
    // MARK: - Subviews
    
    // Initial Choice Screen View
    private func modeSelectionMenu(geometry: GeometryProxy) -> some View {
        VStack(spacing: 35) {
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
            
            VStack(spacing: 18) {
                Button(action: {
                    showAIPopup = true
                }) {
                    HStack {
                        Image(systemName: "cpu")
                        Text("SINGLE PLAYER (VS AI)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Player.x.primaryColor.opacity(0.2))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Player.x.primaryColor, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .focused($focusedIndex, equals: 101)
                
                Button(action: {
                    selectedMode = .multiPlayer
                    focusedIndex = 0
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("DOUBLE PLAYER (LOCAL)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Player.o.primaryColor.opacity(0.15))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Player.o.primaryColor, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .focused($focusedIndex, equals: 102)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: 450, maxHeight: 750)
        .frame(width: geometry.size.width, height: geometry.size.height)
        .onAppear {
            focusedIndex = 101
        }
    }
    
    // Gameplay Window view
    private func gameplayInterface(geometry: GeometryProxy) -> some View {
        VStack(spacing: geometry.size.height > 500 ? 30 : 15) {
            
            // Header Section
            VStack(spacing: 6) {
                Text("TIC-TAC-TOE")
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(Player.x.primaryColor)
                    .shadow(color: Player.x.glowColor, radius: 10)
                
                Text(selectedMode == .singlePlayer ? "MODE: AI (\(selectedDifficulty.rawValue))" : "MODE: LOCAL VS MODE")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
            .padding(.top, 25)
            
            Spacer()
            
            // Game Grid
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<9, id: \.self) { index in
                    Button(action: {
                        handleTap(at: index)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(focusedIndex == index ? Player.x.primaryColor : gridEdgeColor, lineWidth: focusedIndex == index ? 3 : 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(focusedIndex == index ? deepSpaceBlue.opacity(0.9) : deepSpaceBlue.opacity(0.6))
                                )
                                .aspectRatio(1.0, contentMode: .fit)
                                .shadow(color: focusedIndex == index ? Player.x.glowColor : Color.clear, radius: focusedIndex == index ? 12 : 0)
                            
                            if let player = board[index].player {
                                NeonPieceView(player: player)
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.6)), removal: .opacity))
                            }
                        }
                    }
                    .buttonStyle(GridSquareButtonStyle())
                    .focused($focusedIndex, equals: index)
                    #if os(visionOS)
                    .hoverEffect()
                    #endif
                }
            }
            .padding(.horizontal, 20)
            .disabled(isGameOver || isAITinking)
            
            Spacer()
            
            // Status/Turn Window Banner
            Group {
                if isAITinking {
                    Text("AI IS COMPUTING...")
                        .font(.title3)
                        .bold()
                        .foregroundColor(Player.o.primaryColor)
                        .shadow(color: Player.o.glowColor, radius: 8)
                } else if let message = winMessage {
                    Text(message)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                        .shadow(color: .green, radius: 8)
                } else {
                    HStack(spacing: 8) {
                        Text("Turn:")
                            .foregroundColor(.gray)
                        Text(activePlayer.name)
                            .foregroundColor(activePlayer.primaryColor)
                            .font(.title3)
                            .bold()
                            .shadow(color: activePlayer.glowColor, radius: 8)
                    }
                }
            }
            
            Spacer()
            
            // System Actions Menu row
            HStack(spacing: 15) {
                Button(action: resetGame) {
                    Text("RESET")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .focused($focusedIndex, equals: 10)
                
                Button(action: {
                    selectedMode = nil
                    resetGame()
                }) {
                    Text("MAIN MENU")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Player.x.primaryColor, Player.o.primaryColor]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .focused($focusedIndex, equals: 11)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: 450, maxHeight: 750)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    // Custom Styled Window Popup with Difficulty Selector
    private func aiDetailsPopup(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.title2)
                    .foregroundColor(Player.o.primaryColor)
                Text("AI INITIALIZATION MATRIX")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Text("Configure runtime operations for NEO-CORE v1.5 below.")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Platform agnostic picker layout using modern tabbed look
            HStack(spacing: 10) {
                ForEach(Difficulty.allCases) { diff in
                    Button(action: {
                        selectedDifficulty = diff
                    }) {
                        Text(diff.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedDifficulty == diff ? .black : .white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedDifficulty == diff ? Player.x.primaryColor : Color.gray.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedDifficulty == diff ? Player.x.primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 5)
            
            // Dynamic behavior explanation block
            VStack(alignment: .leading, spacing: 4) {
                Text("BEHAVIOR PROFILE:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(selectedDifficulty.description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(deepSpaceBlue.opacity(0.5))
            .cornerRadius(10)
            
            Divider().background(gridEdgeColor)
            
            // Bottom Right Aligned OK Button
            HStack {
                Spacer()
                Button(action: {
                    showAIPopup = false
                    selectedMode = .singlePlayer
                    focusedIndex = 0
                }) {
                    Text("OK")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Player.x.primaryColor)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .focused($focusedIndex, equals: 200)
            }
        }
        .padding(22)
        .frame(width: min(geometry.size.width - 40, 400), height: 350)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(deepSpaceBlue.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Player.o.primaryColor.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Player.o.glowColor.opacity(0.3), radius: 30)
        .onAppear {
            focusedIndex = 200
        }
    }
    
    // MARK: - Game & AI Loop Logic
    
    private func handleTap(at index: Int) {
        guard board[index].player == nil && !isAITinking && !isGameOver else { return }
        
        // Human Move
        board[index].player = activePlayer
        
        if checkGameState() { return }
        
        // Advance Turn State
        activePlayer = (activePlayer == .x) ? .o : .x
        
        // Trigger AI Loop if configured
        if selectedMode == .singlePlayer && activePlayer == .o {
            runAIEngineLoop()
        }
    }
    
    private func runAIEngineLoop() {
        isAITinking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let winPatterns: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
            var chosenMove: Int? = nil
            
            // Determine execution path based on difficulty state configuration
            switch selectedDifficulty {
            case .easy:
                // Pure randomness
                chosenMove = getRandomMove()
                
            case .medium:
                // 50% chance to execute tactical checks, otherwise drops onto casual placement
                if Double.random(in: 0...1) > 0.5 {
                    chosenMove = computeTacticalMove(winPatterns: winPatterns)
                } else {
                    chosenMove = getRandomMove()
                }
                
            case .hard:
                // Always evaluate matrix lines for optimal plays
                chosenMove = computeTacticalMove(winPatterns: winPatterns)
            }
            
            // Fallback safety layer: if tactical processing returned nil, pick a random slot
            if chosenMove == nil {
                chosenMove = getRandomMove()
            }
            
            // Execute AI move payload
            if let aiIndex = chosenMove {
                board[aiIndex].player = .o
            }
            
            isAITinking = false
            
            if !checkGameState() {
                activePlayer = .x
            }
        }
    }
    
    // Helper processing engines
    private func getRandomMove() -> Int? {
        let availableMoves = board.indices.filter { board[$0].player == nil }
        return availableMoves.randomElement()
    }
    
    private func computeTacticalMove(winPatterns: [[Int]]) -> Int? {
        // Phase A: Offensive check (Can AI win right now?)
        for pattern in winPatterns {
            let aiCount = pattern.filter { board[$0].player == .o }.count
            let emptyCount = pattern.filter { board[$0].player == nil }.count
            if aiCount == 2 && emptyCount == 1 {
                return pattern.first(where: { board[$0].player == nil })
            }
        }
        
        // Phase B: Defensive check (Block the player)
        for pattern in winPatterns {
            let humanCount = pattern.filter { board[$0].player == .x }.count
            let emptyCount = pattern.filter { board[$0].player == nil }.count
            if humanCount == 2 && emptyCount == 1 {
                return pattern.first(where: { board[$0].player == nil })
            }
        }
        
        return nil
    }
    
    private func checkGameState() -> Bool {
        if checkWin(for: activePlayer) {
            winMessage = selectedMode == .singlePlayer && activePlayer == .o ? "AI Core Wins!" : "Player \(activePlayer.name) Wins!"
            isGameOver = true
            focusedIndex = 10
            return true
        } else if checkDraw() {
            winMessage = "It's a Tie Matrix!"
            isGameOver = true
            focusedIndex = 10
            return true
        }
        return false
    }
    
    private func checkWin(for player: Player) -> Bool {
        let winPatterns: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
        for pattern in winPatterns {
            let matchCount = pattern.filter { board[$0].player == player }.count
            if matchCount == 3 { return true }
        }
        return false
    }
    
    private func checkDraw() -> Bool {
        return board.allSatisfy { $0.player != nil }
    }
    
    private func resetGame() {
        board = Array(repeating: Square(player: nil), count: 9)
        activePlayer = .x
        winMessage = nil
        isGameOver = false
        isAITinking = false
        focusedIndex = 0
    }
}

// MARK: - Core Style Modifiers

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
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(pieceGeo.size.width * 0.24)
                } else {
                    Circle()
                        .stroke(lineWidth: pieceGeo.size.width * 0.09)
                        .padding(pieceGeo.size.width * 0.18)
                }
            }
            .foregroundColor(player.primaryColor)
            .shadow(color: player.glowColor, radius: 12)
        }
    }
}

// MARK: - Preview Provider

#Preview {
    ContentView()
}
