import Foundation

struct AILogic {

    // All 8 winning lines — [0,1,2] was previously missing, now restored
    static let winPatterns: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],   // rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8],   // columns
        [0, 4, 8], [2, 4, 6]               // diagonals
    ]

    /// Evaluates the board and computes a move based on the selected tier level (1–5).
    static func computeMove(board: [String], level: Int, aiPiece: String) -> Int? {
        let playerPiece  = aiPiece == "X" ? "O" : "X"
        let emptyIndices = board.indices.filter { board[$0].isEmpty }
        guard !emptyIndices.isEmpty else { return nil }

        // ─── TIER 5: Unbeatable Minimax ──────────────────────────────────────────
        if level >= 5 {
            return minimaxBestMove(board: board, aiPiece: aiPiece)
        }

        // ─── TIER 3+: Take winning move immediately ───────────────────────────────
        if level >= 3 {
            if let move = findCriticalMove(board: board, for: aiPiece) {
                return move
            }
        }

        // ─── TIER 4+: Block human's winning move ──────────────────────────────────
        if level >= 4 {
            if let move = findCriticalMove(board: board, for: playerPiece) {
                return move
            }
        }

        // ─── TIER 3+: Prefer center, then corners ────────────────────────────────
        if level >= 3 {
            if board[4].isEmpty { return 4 }
        }

        // ─── Per-Tier Fallback Matrix ─────────────────────────────────────────────
        switch level {
        case 1:
            // Pure random — zero tactical intelligence
            return emptyIndices.randomElement()

        case 2:
            // 70% random blunder, 30% strategic
            if Double.random(in: 0...1) < 0.7 {
                return emptyIndices.randomElement()
            }
            if board[4].isEmpty { return 4 }
            let corners = [0, 2, 6, 8].filter { board[$0].isEmpty }
            return corners.randomElement() ?? emptyIndices.randomElement()

        case 3:
            // Offensively aware, no blocking, center-first
            let corners = [0, 2, 6, 8].filter { board[$0].isEmpty }
            return corners.randomElement() ?? emptyIndices.randomElement()

        default:
            // Tier 4 fallback: center → corners → random
            if board[4].isEmpty { return 4 }
            let corners = [0, 2, 6, 8].filter { board[$0].isEmpty }
            return corners.randomElement() ?? emptyIndices.randomElement()
        }
    }

    // MARK: - Find a Critical Move (win or block)
    /// Returns the index that completes (or blocks) a two-in-a-row for `piece`.
    private static func findCriticalMove(board: [String], for piece: String) -> Int? {
        for pattern in winPatterns {
            let cells = pattern.map { board[$0] }
            if cells.filter({ $0 == piece }).count == 2,
               let emptyPos = pattern.first(where: { board[$0].isEmpty }) {
                return emptyPos
            }
        }
        return nil
    }

    // MARK: - Minimax (Tier 5 — unbeatable)
    private static func minimaxBestMove(board: [String], aiPiece: String) -> Int? {
        let emptyIndices = board.indices.filter { board[$0].isEmpty }
        guard !emptyIndices.isEmpty else { return nil }

        var bestScore = Int.min
        var bestMove: Int? = nil

        for index in emptyIndices {
            var newBoard    = board
            newBoard[index] = aiPiece
            let score       = minimax(board: newBoard, depth: 0, isMaximising: false,
                                      aiPiece: aiPiece, alpha: Int.min, beta: Int.max)
            if score > bestScore {
                bestScore = score
                bestMove  = index
            }
        }
        return bestMove
    }

    /// Alpha-beta pruned minimax — evaluates all future states.
    private static func minimax(board: [String], depth: Int, isMaximising: Bool,
                                 aiPiece: String, alpha: Int, beta: Int) -> Int {
        let playerPiece = aiPiece == "X" ? "O" : "X"

        // Terminal state checks
        if hasWon(board: board, piece: aiPiece)     { return 10 - depth }
        if hasWon(board: board, piece: playerPiece) { return depth - 10 }
        if !board.contains("")                       { return 0 }

        let emptyIndices = board.indices.filter { board[$0].isEmpty }
        var alpha = alpha
        var beta  = beta

        if isMaximising {
            var best = Int.min
            for index in emptyIndices {
                var newBoard    = board
                newBoard[index] = aiPiece
                let score = minimax(board: newBoard, depth: depth + 1, isMaximising: false,
                                    aiPiece: aiPiece, alpha: alpha, beta: beta)
                best  = max(best, score)
                alpha = max(alpha, best)
                if beta <= alpha { break }  // prune
            }
            return best
        } else {
            var best = Int.max
            for index in emptyIndices {
                var newBoard    = board
                newBoard[index] = playerPiece
                let score = minimax(board: newBoard, depth: depth + 1, isMaximising: true,
                                    aiPiece: aiPiece, alpha: alpha, beta: beta)
                best = min(best, score)
                beta = min(beta, best)
                if beta <= alpha { break }  // prune
            }
            return best
        }
    }

    private static func hasWon(board: [String], piece: String) -> Bool {
        winPatterns.contains { pattern in
            pattern.allSatisfy { board[$0] == piece }
        }
    }
}
