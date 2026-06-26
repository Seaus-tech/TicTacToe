import Foundation

struct AILogic {
    static func computeMove(board: [String], difficulty: String, aiPiece: String) -> Int? {
        let playerPiece = aiPiece == "X" ? "O" : "X"
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        
        let emptyIndices = board.indices.filter { board[$0].isEmpty }
        guard !emptyIndices.isEmpty else { return nil }
        
        switch difficulty.lowercased() {
        case "easy":
            return emptyIndices.randomElement()
            
        case "medium":
            // 🎲 50/50 split between tactical awareness and complete random moves
            if Double.random(in: 0...1) > 0.5 {
                return emptyIndices.randomElement()
            }
            fallthrough // Fall into tactical processing for the other 50%
            
        case "hard":
            // 1. Can the AI win right now?
            for pattern in winPatterns {
                let pieces = pattern.map { board[$0] }
                if pieces.filter({ $0 == aiPiece }).count == 2 && pieces.filter({ $0.isEmpty }).count == 1 {
                    if let targetIndex = pattern.first(where: { board[$0].isEmpty }) {
                        return targetIndex
                    }
                }
            }
            
            // 2. Does the AI need to block a human player's winning setup?
            for pattern in winPatterns {
                let pieces = pattern.map { board[$0] }
                if pieces.filter({ $0 == playerPiece }).count == 2 && pieces.filter({ $0.isEmpty }).count == 1 {
                    if let targetIndex = pattern.first(where: { board[$0].isEmpty }) {
                        return targetIndex
                    }
                }
            }
            
            // 3. Take the high-value strategic center cell if open
            if board[4].isEmpty { return 4 }
            
            // 4. Seize open corners
            let corners = [0, 2, 6, 8].filter { board[$0].isEmpty }
            if let cornerMove = corners.randomElement() { return cornerMove }
            
            // 5. Default fallback
            return emptyIndices.randomElement()
            
        default:
            return emptyIndices.randomElement()
        }
    }
}
