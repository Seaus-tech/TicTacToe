import SwiftUI
import AVFoundation
import Combine

enum GameResult {
    case win(String)
    case draw
    case ongoing
}

@MainActor
class GameViewModel: ObservableObject {

    @Published var board: [String] = Array(repeating: "", count: 9)
    @Published var currentToken: String = "X"
    @Published var humanPiece: String = "X"
    @Published var gameResult: GameResult = .ongoing
    @Published var winningLine: [Int]? = nil

    @Published var scoreX: Int     = 0
    @Published var scoreO: Int     = 0
    @Published var drawCount: Int  = 0

    @Published var winStreak: Int        = 0
    @Published var totalCareerWins: Int  = 0

    @Published var showPiecePicker: Bool = false
    @Published var opponentDisconnected: Bool = false

    var matchMode: MatchMode = .bot
    var botLevel: Int = 1
    var activeGameMode: GameMode = .classic
    private var placementHistory: [Int] = []

    weak var onlineManager: OnlineGameManager?

    private var tapPlayer: AVAudioPlayer?
    private var winPlayer: AVAudioPlayer?
    private var drawPlayer: AVAudioPlayer?

    init() {
        setupAudio()
    }

    private func setupAudio() {
        tapPlayer  = makePlayer(for: "tap")
        winPlayer  = makePlayer(for: "win")
        drawPlayer = makePlayer(for: "draw")
    }

    private func makePlayer(for name: String) -> AVAudioPlayer? {
        for ext in ["wav", "mp3", "aiff", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return try? AVAudioPlayer(contentsOf: url)
            }
        }
        return nil
    }

    var botPiece: String { humanPiece == "X" ? "O" : "X" }
    var isGameOver: Bool {
        if case .ongoing = gameResult { return false }
        return true
    }

    var resultMessage: String? {
        switch gameResult {
        case .win(let t):
            if activeGameMode == .inverse {
                let actualWinner = (t == "X") ? "O" : "X"
                switch matchMode {
                case .bot:              return actualWinner == humanPiece ? "You Win! 🎉 (Inverse)" : "Bot Wins! (Inverse)"
                case .localPassAndPlay: return "\(actualWinner) Wins! 🎉 (Inverse)"
                case .online:           return actualWinner == humanPiece ? "You Win! 🎉 (Inverse)" : "Opponent Wins! (Inverse)"
                }
            }
            switch matchMode {
            case .bot:              return t == humanPiece ? "You Win! 🎉" : "Bot Wins!"
            case .localPassAndPlay: return "\(t) Wins! 🎉"
            case .online:           return t == humanPiece ? "You Win! 🎉" : "Opponent Wins!"
            }
        case .draw:    return "It's a Draw!"
        case .ongoing: return nil
        }
    }

    var turnOwnerLabel: String {
        switch matchMode {
        case .bot:             return currentToken == humanPiece ? "Your turn" : "Bot thinking…"
        case .localPassAndPlay: return "\(currentToken)'s turn"
        case .online:          return currentToken == humanPiece ? "Your turn" : "Opponent's turn"
        }
    }

    func startNewGame(keepPiece: Bool = true) {
        board                = Array(repeating: "", count: 9)
        placementHistory.removeAll()
        winningLine          = nil
        gameResult           = .ongoing
        opponentDisconnected = false
        currentToken         = "X"

        if matchMode == .bot && currentToken == botPiece {
            triggerBotMove()
        }

        if matchMode == .online {
            onlineManager?.sendReset()
        }
    }

    func resetScores() {
        scoreX    = 0
        scoreO    = 0
        drawCount = 0
        winStreak = 0
    }

    func resetGameBoardState() {
        self.resetScores()
        print("⚡ Matchboard arrays purged and reset cleanly.")
    }
    
    func humanTapped(index: Int) {
        var finalIndex = index
        
        if activeGameMode == .gravityDrop {
            let column = index % 3
            let columnIndices = [column + 6, column + 3, column]
            if let emptyIndex = columnIndices.first(where: { board[$0].isEmpty }) {
                finalIndex = emptyIndex
            } else {
                return
            }
        }
        
        guard canPlace(at: finalIndex) else { return }
        guard currentToken == humanPiece || matchMode == .localPassAndPlay else { return }
        place(token: currentToken, at: index)

        if matchMode == .online {
            onlineManager?.sendGameMove(cellIndex: finalIndex)
        }

        if case .ongoing = gameResult {
            if matchMode == .bot {
                currentToken = botPiece
                triggerBotMove()
            } else {
                currentToken = (currentToken == "X") ? "O" : "X"
            }
        }
    }

    func receiveOnlineMove(index: Int) {
        var finalIndex = index
        
        if activeGameMode == .gravityDrop {
            let column = index % 3
            let columnIndices = [column + 6, column + 3, column]
            if let emptyIndex = columnIndices.first(where: { board[$0].isEmpty }) {
                finalIndex = emptyIndex
            } else {
                return
            }
        }
        
        guard canPlace(at: finalIndex) else { return }
        let opponentPiece = humanPiece == "X" ? "O" : "X"
        place(token: opponentPiece, at: finalIndex)
        if case .ongoing = gameResult {
            currentToken = humanPiece
        }
    }

    private func triggerBotMove() {
        guard case .ongoing = gameResult else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.executeBotMove()
        }
    }

    private func executeBotMove() {
        guard case .ongoing = gameResult else { return }
        guard board.contains("") else { return }

        if let cell = AILogic.computeMove(board: board, level: botLevel, aiPiece: botPiece) {
            var finalBotIndex = cell
            
            if activeGameMode == .gravityDrop {
                let column = cell % 3
                let columnIndices = [column + 6, column + 3, column]
                if let emptyIndex = columnIndices.first(where: { board[$0].isEmpty }) {
                    finalBotIndex = emptyIndex
                } else {
                    return
                }
            }
            place(token: botPiece, at: finalBotIndex)
        }
        
        if case .ongoing = gameResult {
            currentToken = humanPiece
        }
    }

    private func canPlace(at index: Int) -> Bool {
        guard index >= 0 && index < 9 else { return false }
        guard board[index].isEmpty else { return false }
        guard case .ongoing = gameResult else { return false }
        return true
    }

    private func place(token: String, at index: Int) {
        board[index] = token
        placementHistory.append(index)
        playTap()

        if activeGameMode == .quantumFading {
            let activePlayerMoves = placementHistory.filter { board[$0] == token }
            if activePlayerMoves.count > 3 {
                if let oldestIndex = activePlayerMoves.first {
                    board[oldestIndex] = ""
                    placementHistory.removeAll(where: { $0 == oldestIndex })
                }
            }
        }

        let result = evaluate(token: token)
        gameResult = result

        switch result {
        case .win(let winner):
            winningLine = findWinningLine(for: winner)
            if activeGameMode == .inverse {
                let actualWinner = (winner == "X") ? "O" : "X"
                updateScores(winner: actualWinner)
                if actualWinner == humanPiece {
                    playWin()
                    hapticNotification(type: 0)
                    reportToGameCenter(winner: actualWinner)
                } else {
                    playDraw()
                    hapticNotification(type: 1)
                }
            } else {
                updateScores(winner: winner)
                playWin()
                hapticNotification(type: 0)
                reportToGameCenter(winner: winner)
            }
        case .draw:
            updateScores(winner: nil)
            playDraw()
            hapticNotification(type: 1)
        case .ongoing:
            hapticImpact()
        }
    }

    static let winPatterns: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    private func evaluate(token: String) -> GameResult {
        for pattern in Self.winPatterns {
            if pattern.allSatisfy({ board[$0] == token }) {
                return .win(token)
            }
        }
        if !board.contains("") { return .draw }
        return .ongoing
    }

    private func findWinningLine(for token: String) -> [Int]? {
        Self.winPatterns.first { pattern in
            pattern.allSatisfy { board[$0] == token }
        }
    }

    private func updateScores(winner: String?) {
        if let w = winner {
            if w == "X" { scoreX += 1 } else { scoreO += 1 }
            if w == humanPiece {
                winStreak       += 1
                totalCareerWins += 1
            } else {
                winStreak = 0
            }
        } else {
            drawCount += 1
            winStreak  = 0
        }
    }

    private func reportToGameCenter(winner: String) {
        guard winner == humanPiece else { return }
        onlineManager?.reportScoreToLeaderboard(wins: totalCareerWins)
        onlineManager?.reportWinAchievement(currentStreakCount: winStreak)
    }

    private func playTap() {
        tapPlayer?.stop(); tapPlayer?.currentTime = 0; tapPlayer?.play()
    }
    private func playWin() {
        winPlayer?.stop(); winPlayer?.currentTime = 0; winPlayer?.play()
    }
    private func playDraw() {
        drawPlayer?.stop(); drawPlayer?.currentTime = 0; drawPlayer?.play()
    }

    private func hapticImpact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
    
    private func hapticNotification(type: Int) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        if type == 0 {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.warning)
        }
        #endif
    }
}
