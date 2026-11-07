using System;
using System.Collections.Generic;
using System.Linq;

namespace TicTacToe_Windows
{
	public enum GameDifficulty { Easy, Medium, Hard }
	public enum Player { None, X, O }

	public class GameEngine
	{
		public Player[] Board { get; private; } = new Player[9];
		public Player CurrentTurn { get; private; } = Player.X;
		public GameDifficulty Difficulty { get; set; } = GameDifficulty.Hard;
		public bool IsGameOver { get; private; }
		public Player Winner { get; private; }

		private readonly Random _random = new Random();

		// Standard Tic-Tac-Toe winning combinations
		private readonly int[][] _winningLines = new int[][]
		{
			new[] {0, 1, 2}, new[] {3, 4, 5}, new[] {6, 7, 8}, // Rows
            new[] {0, 3, 6}, new[] {1, 4, 7}, new[] {2, 5, 8}, // Columns
            new[] {0, 4, 8}, new[] {2, 4, 6}                  // Diagonals
        };

		public void ResetGame()
		{
			Array.Fill(Board, Player.None);
			CurrentTurn = Player.X;
			IsGameOver = false;
			Winner = Player.None;
		}

		public bool MakeMove(int index)
		{
			if (index < 0 || index > 8 || Board[index] != Player.None || IsGameOver)
				return false;

			Board[index] = CurrentTurn;
			CheckGameState();

			if (!IsGameOver)
			{
				CurrentTurn = (CurrentTurn == Player.X) ? Player.O : Player.X;
			}
			return true;
		}

		public int GetAIMove()
		{
			var availableMoves = GetAvailableMoves();
			if (availableMoves.Count == 0) return -1;

			// Easy: Completely random choices
			if (Difficulty == GameDifficulty.Easy)
			{
				return availableMoves[_random.Next(availableMoves.Count)];
			}

			// Medium: 50% tactical defense/offense, 50% random fallback
			if (Difficulty == GameDifficulty.Medium && _random.Next(0, 2) == 0)
			{
				return availableMoves[_random.Next(availableMoves.Count)];
			}

			// Hard/Defensive-Offensive evaluation core
			// Rule 1: Win if an offensive winning move exists
			foreach (var move in availableMoves)
			{
				if (SimulateMoveAndCheckWin(move, CurrentTurn)) return move;
			}

			// Rule 2: Block if a defensive threat exists
			Player opponent = (CurrentTurn == Player.X) ? Player.O : Player.X;
			foreach (var move in availableMoves)
			{
				if (SimulateMoveAndCheckWin(move, opponent)) return move;
			}

			// Rule 3: Strategic center control
			if (availableMoves.Contains(4)) return 4;

			// Rule 4: Strategic corners
			var corners = new List<int> { 0, 2, 6, 8 }.Intersect(availableMoves).ToList();
			if (corners.Count > 0) return corners[_random.Next(corners.Count)];

			// Fallback to whatever is open
			return availableMoves[_random.Next(availableMoves.Count)];
		}

		private List<int> GetAvailableMoves()
		{
			var moves = new List<int>();
			for (int i = 0; i < 9; i++)
			{
				if (Board[i] == Player.None) moves.Add(i);
			}
			return moves;
		}

		private bool SimulateMoveAndCheckWin(int index, Player player)
		{
			Board[index] = player;
			bool isWin = CheckWinCondition(player);
			Board[index] = Player.None; // Revert
			return isWin;
		}

		private void CheckGameState()
		{
			if (CheckWinCondition(CurrentTurn))
			{
				Winner = CurrentTurn;
				IsGameOver = true;
			}
			else if (!Board.Contains(Player.None))
			{
				Winner = Player.None; // Draw
				IsGameOver = true;
			}
		}

		private bool CheckWinCondition(Player player)
		{
			return _winningLines.Any(line => line.All(idx => Board[idx] == player));
		}
	}
}
