import SwiftUI
import AVFoundation
import Combine

// MARK: - Game Result
enum GameResult {
    case win(String)   // token that won
    case draw
    case ongoing
}

// MARK: - GameViewModel
@MainActor
class GameViewModel: ObservableObject {

    // Board state
    @Published var board: [String] = Array(repeating: "", count: 9)
    @Published var currentToken: String = "X"       // whose turn it is
    @Published var humanPiece: String = "X"         // piece the human chose
    @Published var gameResult: GameResult = .ongoing
    @Published var winningLine: [Int]? = nil

    // Session scores
    @Published var scoreX: Int     = 0
    @Published var scoreO: Int     = 0
    @Published var drawCount: Int  = 0

    // Career / streak
    @Published var winStreak: Int        = 0
    @Published var totalCareerWins: Int  = 0

    // Piece-pick sheet
    @Published var showPiecePicker: Bool = false

    // Online opponent disconnect
    @Published var opponentDisconnected: Bool = false

    // Active match mode (set by ContentView before each game)
    var matchMode: MatchMode = .bot
    var botLevel: Int = 1

    // Reference back to online manager so we can send moves
    weak var onlineManager: OnlineGameManager?

    // Audio
    private var tapPlayer: AVAudioPlayer?
    private var winPlayer: AVAudioPlayer?
    private var drawPlayer: AVAudioPlayer?

    init() {
        setupAudio()
    }

    // MARK: - Audio Setup
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

    // MARK: - Derived helpers
    var botPiece: String { humanPiece == "X" ? "O" : "X" }
    var isGameOver: Bool {
        if case .ongoing = gameResult { return false }
        return true
    }

    var resultMessage: String? {
        switch gameResult {
        case .win(let t):
            switch matchMode {
            case .bot:       return t == humanPiece ? "You Win! 🎉" : "Bot Wins!"
            case .localPassAndPlay: return "\(t) Wins! 🎉"
            case .online:    return t == humanPiece ? "You Win! 🎉" : "Opponent Wins!"
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

    // MARK: - New Game
    func startNewGame(keepPiece: Bool = true) {
        board              = Array(repeating: "", count: 9)
        winningLine        = nil
        gameResult         = .ongoing
        opponentDisconnected = false
        currentToken       = "X"

        // If bot goes first (human chose O), trigger immediately
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

    // MARK: - Cell Tap (Human)
    func humanTapped(index: Int) {
        guard canPlace(at: index) else { return }
        guard currentToken == humanPiece || matchMode == .localPassAndPlay else { return }
        place(token: currentToken, at: index)

        if matchMode == .online {
            onlineManager?.sendGameMove(cellIndex: index)
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

    // MARK: - Incoming online move
    func receiveOnlineMove(index: Int) {
        guard canPlace(at: index) else { return }
        let opponentPiece = humanPiece == "X" ? "O" : "X"
        place(token: opponentPiece, at: index)
        if case .ongoing = gameResult {
            currentToken = humanPiece
        }
    }

    // MARK: - Bot Move
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
            place(token: botPiece, at: cell)
        }
        // Only hand back to the human if the game is still going
        if case .ongoing = gameResult {
            currentToken = humanPiece
        }
    }

    // MARK: - Core placement
    private func canPlace(at index: Int) -> Bool {
        guard index >= 0 && index < 9 else { return false }
        guard board[index].isEmpty else { return false }
        guard case .ongoing = gameResult else { return false }
        return true
    }

    private func place(token: String, at index: Int) {
        board[index] = token
        playTap()

        let result = evaluate(token: token)
        gameResult = result

        switch result {
        case .win(let winner):
            winningLine = findWinningLine(for: winner)
            updateScores(winner: winner)
            playWin()
            hapticNotification(type: 0)
            reportToGameCenter(winner: winner)

        case .draw:
            updateScores(winner: nil)
            playDraw()
            hapticNotification(type: 1)

        case .ongoing:
            hapticImpact()
        }
    }

    // MARK: - Win evaluation
    static let winPatterns: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],   // rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8],   // columns
        [0, 4, 8], [2, 4, 6]               // diagonals
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

    // MARK: - Scores & Streaks
    private func updateScores(winner: String?) {
        if let w = winner {
            if w == "X" { scoreX += 1 } else { scoreO += 1 }
            if w == humanPiece {
                winStreak      += 1
                totalCareerWins += 1
            } else {
                winStreak = 0
            }
        } else {
            drawCount += 1
            winStreak  = 0
        }
    }

    // MARK: - Game Center reporting
    private func reportToGameCenter(winner: String) {
        guard winner == humanPiece else { return }
        onlineManager?.reportScoreToLeaderboard(wins: totalCareerWins)
        onlineManager?.reportWinAchievement(currentStreakCount: winStreak)
    }

    // MARK: - Sound
    private func playTap() {
        tapPlayer?.stop(); tapPlayer?.currentTime = 0; tapPlayer?.play()
    }
    private func playWin() {
        winPlayer?.stop(); winPlayer?.currentTime = 0; winPlayer?.play()
    }
    private func playDraw() {
        drawPlayer?.stop(); drawPlayer?.currentTime = 0; drawPlayer?.play()
    }

    // MARK: - Haptics
    private func hapticImpact() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func hapticNotification(type: Int) {
        // type: 0 = success, 1 = warning
        #if os(iOS)
        let fbType: UINotificationFeedbackGenerator.FeedbackType = type == 0 ? .success : .warning
        UINotificationFeedbackGenerator().notificationOccurred(fbType)
        #endif
    }
}
