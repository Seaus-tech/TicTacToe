import SwiftUI

struct ContentView: View {
    @ObservedObject var gameManager: OnlineGameManager
    
    // Navigation Screens: "menu", "online_match", "local_play", "ai_play"
    @State private var currentScreen = "menu"
    @State private var aiDifficulty = "Medium"
    
    // Offline State Engines
    @State private var localBoard: [String] = Array(repeating: "", count: 9)
    @State private var isLocalXTurn = true
    @State private var localStatusMessage = "Player X's Turn"
    @State private var localWinner: String? = nil
    
    @State private var pulseVector = false
    
    var body: some View {
        ZStack {
            // --- DEEP LIQUID GLOW BACKDROP ---
            Color(red: 0.05, green: 0.04, blue: 0.08)
                .edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(Color.purple.opacity(0.35))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
                .offset(x: pulseVector ? -200 : 200, y: pulseVector ? 150 : -150)
                
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: pulseVector ? 250 : -250, y: pulseVector ? -120 : 120)
            
            // --- FRONT COMPOSITE GLASS PANEL LAYER ---
            VStack(spacing: 0) {
                
                // HEADER STATUS DASHBOARD
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ARCADE MATRIX LINK")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.purple)
                            .shadow(color: .purple.opacity(0.5), radius: 4)
                        Text("Operator ID: \(gameManager.currentUsername)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        if currentScreen != "menu" {
                            exitToMainMenu()
                        } else {
                            gameManager.logOut()
                        }
                    }) {
                        Text(currentScreen != "menu" ? "Main Menu" : "Disconnect")
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(currentScreen != "menu" ? Color.blue.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(currentScreen != "menu" ? .blue : .red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.white.opacity(0.03))
                
                Divider().background(Color.white.opacity(0.1))
                
                // --- CONTAINER FRAME ---
                VStack {
                    switch currentScreen {
                    case "menu":
                        mainPortalMenuView
                        
                    case "online_match":
                        onlineMatchmakingArenaView
                        
                    case "local_play", "ai_play":
                        offlineArenaView
                        
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .liquidGlassStyle()
            .padding(24)
        }
        .onAppear {
            // Keep matchmaking off on launch until explicit menu selection
            gameManager.showMatchmaker = false
            
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                pulseVector = true
            }
            
            // Link socket update streams to local display board matrix
            gameManager.onReceiveMove = { enemyIndex in
                let enemyPiece = gameManager.localPlayerPiece == .x ? "O" : "X"
                localBoard[enemyIndex] = enemyPiece
            }
            gameManager.onReceiveReset = { resetLocalBoard() }
        }
        .onChange(of: gameManager.match) { _, isMatched in
            if isMatched == true && currentScreen == "online_match" {
                resetLocalBoard()
            }
        }
    }
    
    // MARK: - Sub-View: Main Menu Portal
    private var mainPortalMenuView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Text("SELECT OPERATIONS MODE")
                .font(.system(.title3, design: .monospaced))
                .bold()
                .foregroundColor(.white)
                .tracking(2)
            
            VStack(spacing: 16) {
                MenuActionButton(
                    title: "SINGLE PLAYER (VS AI)",
                    subtitle: "Challenge the grid processing bot matrix",
                    iconName: "cpu",
                    glowColor: .blue,
                    isDisabled: false,
                    action: {
                        currentScreen = "ai_play"
                        resetLocalBoard()
                    }
                )
                
                MenuActionButton(
                    title: "LOCAL MULTIPLAYER",
                    subtitle: "Pass and play session matrix locally",
                    iconName: "person.2.fill",
                    glowColor: .green,
                    isDisabled: false,
                    action: {
                        currentScreen = "local_play"
                        resetLocalBoard()
                    }
                )
                
                MenuActionButton(
                    title: "ONLINE MATCHMAKING",
                    subtitle: "Connect through ngrok global relay server",
                    iconName: "globe",
                    glowColor: .purple,
                    isDisabled: gameManager.currentUsername == "Local Guest",
                    action: {
                        currentScreen = "online_match"
                        gameManager.showMatchmaker = true
                        
                        // 🌐 FIXED: Explicitly trigger the connection pipeline so terminal catches socket streams!
                        gameManager.connect()
                    }
                )
            }
            .frame(maxWidth: 440)
            
            Spacer()
        }
    }
    
    // MARK: - Sub-View: Online Lobby Search Frame
    private var onlineMatchmakingArenaView: some View {
        VStack {
            Spacer()
            if gameManager.showMatchmaker {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Lobby Standby")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(gameManager.opponentName)
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .bold()
                }
            } else {
                gameGridMatrixView
            }
            Spacer()
        }
    }
    
    // MARK: - Sub-View: Offline Board Modes Frame
    private var offlineArenaView: some View {
        VStack(spacing: 0) {
            if currentScreen == "ai_play" {
                HStack(spacing: 12) {
                    Text("Bot Intensity:")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    ForEach(["Easy", "Medium", "Hard"], id: \.self) { diff in
                        Button(action: { aiDifficulty = diff }) {
                            Text(diff)
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(aiDifficulty == diff ? Color.purple.opacity(0.6) : Color.white.opacity(0.08))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 14)
            }
            
            Spacer()
            gameGridMatrixView
            Spacer()
        }
    }
    
    // MARK: - Shared Component: Core Game Board Frame
    private var gameGridMatrixView: some View {
        VStack(spacing: 20) {
            Text(currentStatusText)
                .font(.title3)
                .bold()
                .foregroundColor(statusColor)
                .shadow(color: statusColor.opacity(0.4), radius: 6)
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            GridCell(
                                title: localBoard[index],
                                isEnabled: isCellActionable(at: index),
                                action: { handleCellTap(at: index) }
                            )
                        }
                    }
                }
            }
            
            Button(action: { triggerResetAction() }) {
                Text("Reset Current Grid")
                    .font(.body)
                    .bold()
                    .frame(maxWidth: 180)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 5)
        }
    }
    
    // MARK: - Control Helpers
    
    private func exitToMainMenu() {
        if currentScreen == "online_match" {
            gameManager.disconnect()
        }
        currentScreen = "menu"
    }
    
    private var currentStatusText: String {
        switch currentScreen {
        case "online_match":
            if gameManager.match != true { return "Connecting Matrix..." }
            return gameManager.isMyTurn ? "Your Turn (Piece: \(gameManager.localPlayerPiece == .x ? "X" : "O"))" : "Opponent is thinking..."
        default:
            return localStatusMessage
        }
    }
    
    private var statusColor: Color {
        switch currentScreen {
        case "online_match":
            if gameManager.match != true { return .secondary }
            return gameManager.isMyTurn ? .green : .orange
        default:
            if localWinner != nil { return .yellow }
            if !localBoard.contains("") { return .secondary }
            return isLocalXTurn ? .green : .purple
        }
    }
    
    private func isCellActionable(at index: Int) -> Bool {
        if !localBoard[index].isEmpty { return false }
        switch currentScreen {
        case "online_match": return gameManager.match == true && gameManager.isMyTurn
        case "local_play": return localWinner == nil
        case "ai_play": return localWinner == nil && isLocalXTurn
        default: return false
        }
    }
    
    private func handleCellTap(at index: Int) {
        switch currentScreen {
        case "online_match":
            localBoard[index] = gameManager.localPlayerPiece == .x ? "X" : "O"
            gameManager.sendMove(at: index)
            
        case "local_play":
            // 👥 FIXED: Clean state rotation for real local pass-and-play operations
            localBoard[index] = isLocalXTurn ? "X" : "O"
            if evaluateOfflineState() { return }
            isLocalXTurn.toggle() // Flips gracefully back and forth now!
            localStatusMessage = isLocalXTurn ? "Player X's Turn" : "Player O's Turn"
            
        case "ai_play":
            localBoard[index] = "X"
            isLocalXTurn = false
            localStatusMessage = "Bot is calculating..."
            if evaluateOfflineState() { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let aiMove = AILogic.computeMove(board: localBoard, difficulty: aiDifficulty, aiPiece: "O") {
                    localBoard[aiMove] = "O"
                }
                isLocalXTurn = true
                _ = evaluateOfflineState()
            }
        default: break
        }
    }
    
    private func triggerResetAction() {
        if currentScreen == "online_match" { gameManager.sendResetRequest() } else { resetLocalBoard() }
    }
    
    private func resetLocalBoard() {
        localBoard = Array(repeating: "", count: 9)
        isLocalXTurn = true
        localWinner = nil
        localStatusMessage = currentScreen == "ai_play" ? "Your Turn (Piece: X)" : "Player X's Turn"
    }
    
    private func evaluateOfflineState() -> Bool {
        let winPatterns = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
        for pattern in winPatterns {
            let p1 = localBoard[pattern[0]], p2 = localBoard[pattern[1]], p3 = localBoard[pattern[2]]
            if !p1.isEmpty && p1 == p2 && p2 == p3 {
                localWinner = p1
                if currentScreen == "ai_play" {
                    localStatusMessage = p1 == "X" ? "🎉 Victory! You beat the bot!" : "🤖 Bot wins! Better luck next time."
                } else {
                    localStatusMessage = "🏆 Player \(p1) Wins!"
                }
                return true
            }
        }
        if !localBoard.contains("") {
            localStatusMessage = "🤝 Grid locked down! It's a tie."
            return true
        }
        return false
    }
}

// MARK: - CORE INTERACTIVE GRID CELL MODULE
struct GridCell: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    private var cellBackgroundColor: Color {
        return title.isEmpty ? Color.white.opacity(0.04) : Color.white.opacity(0.09)
    }
    
    private var pieceTextColor: Color {
        return title == "X" ? Color.green : Color.purple
    }
    
    private var frameStrokeColor: Color {
        if title.isEmpty {
            return Color.white.opacity(0.1)
        } else if title == "X" {
            return Color.green.opacity(0.4)
        } else {
            return Color.purple.opacity(0.4)
        }
    }
    
    private var neonShadowColor: Color {
        if title == "X" {
            return Color.green.opacity(0.2)
        } else if title == "O" {
            return Color.purple.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 45, weight: .bold, design: .monospaced))
                .frame(width: 95, height: 95)
                .background(cellBackgroundColor)
                .foregroundColor(pieceTextColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(frameStrokeColor, lineWidth: 1)
                )
                .shadow(color: neonShadowColor, radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - EXPANDABLE ACTION BUTTON MODULE
struct MenuActionButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let glowColor: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isDisabled ? .secondary : glowColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(isDisabled ? .secondary : .white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.white.opacity(isDisabled ? 0.01 : 0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDisabled ? Color.white.opacity(0.05) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isDisabled ? .clear : glowColor.opacity(0.1), radius: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
