import SwiftCrossUI
import DefaultBackend

struct WindowsContentView: View {
	@State private var board = Array(repeating: "", count: 9)
	@State private var currentToken = "X"
	@State private var isGameOver = false
	@State private var isSinglePlayer = true
	@State private var difficulty = 3
	@State private var status = "Your turn (X)"
	@State private var scoreX = 0
	@State private var scoreO = 0
	@State private var draws = 0

	var body: some View {
		VStack(spacing: 12) {
			Text("NEO-GRID")
				.font(.largeTitle)
			Text(status)

			HStack(spacing: 8) {
				Button(isSinglePlayer ? "Mode: Computer" : "Mode: Two Players") {
					isSinglePlayer.toggle()
					startNewGame()
				}
				if isSinglePlayer {
					Button("AI level: \(difficulty)") {
						difficulty = difficulty == 5 ? 1 : difficulty + 1
					}
				}
			}

			VStack(spacing: 6) {
				HStack(spacing: 6) {
					cellButton(0)
					cellButton(1)
					cellButton(2)
				}
				HStack(spacing: 6) {
					cellButton(3)
					cellButton(4)
					cellButton(5)
				}
				HStack(spacing: 6) {
					cellButton(6)
					cellButton(7)
					cellButton(8)
				}
			}

			Text("X: \(scoreX)    O: \(scoreO)    Draws: \(draws)")
			Button("New Game") {
				startNewGame()
			}
		}
		.padding(20)
	}

	private func cellButton(_ index: Int) -> some View {
		Button {
			playHumanMove(at: index)
		} label: {
			Text(board[index].isEmpty ? " " : board[index])
				.font(.largeTitle)
				.frame(width: 88, height: 76)
		}
	}

	private func playHumanMove(at index: Int) {
		guard !isGameOver, board[index].isEmpty else { return }
		guard !isSinglePlayer || currentToken == "X" else { return }

		place(currentToken, at: index)
		guard !isGameOver else { return }

		if isSinglePlayer {
			currentToken = "O"
			status = "Computer's turn (O)"
			if let move = AILogic.computeMove(board: board, level: difficulty, aiPiece: "O") {
				place("O", at: move)
			}
			if !isGameOver {
				currentToken = "X"
				status = "Your turn (X)"
			}
		} else {
			currentToken = currentToken == "X" ? "O" : "X"
			status = "Player \(currentToken)'s turn"
		}
	}

	private func place(_ token: String, at index: Int) {
		guard !isGameOver, board[index].isEmpty else { return }
		board[index] = token

		if AILogic.winPatterns.contains(where: { line in
			line.allSatisfy { board[$0] == token }
		}) {
			isGameOver = true
			status = "\(token) wins!"
			if token == "X" {
				scoreX += 1
			} else {
				scoreO += 1
			}
		} else if !board.contains("") {
			isGameOver = true
			status = "It's a draw."
			draws += 1
		} else if !isSinglePlayer {
			status = "Player \(token == "X" ? "O" : "X")'s turn"
		}
	}

	private func startNewGame() {
		board = Array(repeating: "", count: 9)
		currentToken = "X"
		isGameOver = false
		status = "Your turn (X)"
	}
}
