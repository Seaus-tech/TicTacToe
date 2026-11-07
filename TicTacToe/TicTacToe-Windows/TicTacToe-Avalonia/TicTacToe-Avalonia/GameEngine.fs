namespace TicTacToe_Avalonia

open System
open System.Collections.Generic

type Player = None | X | O
type GameDifficulty = Rookie | Cadet | Tactician | Veteran | Nemesis

type GameEngine() =
    let mutable board = Array.create 9 Player.None
    let mutable currentTurn = Player.X
    let mutable difficulty = GameDifficulty.Rookie
    let mutable isGameOver = false
    let mutable winner = Player.None
    let rand = Random()
    let history = ResizeArray<Player array * Player * bool * Player * Player>()

    let winningLines = [|
        [|0; 1; 2|]; [|3; 4; 5|]; [|6; 7; 8|]
        [|0; 3; 6|]; [|1; 4; 7|]; [|2; 5; 8|]
        [|0; 4; 8|]; [|2; 4; 6|]
    |]

    let checkWinCondition (gameBoard: Player array) (player: Player) =
        winningLines
        |> Array.exists (fun line -> line |> Array.forall (fun index -> gameBoard.[index] = player))

    let getAvailableMoves (gameBoard: Player array) =
        [0 .. 8] |> List.filter (fun index -> gameBoard.[index] = Player.None)

    let simulateMoveAndCheckWin (gameBoard: Player array) index player =
        let testBoard = Array.copy gameBoard
        testBoard.[index] <- player
        checkWinCondition testBoard player

    let findCriticalMove gameBoard player moves =
        moves |> List.tryFind (fun index -> simulateMoveAndCheckWin gameBoard index player)

    let minimaxBestMove (gameBoard: Player array) (aiPlayer: Player) moves =
        let opponent = if aiPlayer = Player.X then Player.O else Player.X

        let rec evaluatePosition (position: Player array) nextPlayer depth =
            if checkWinCondition position aiPlayer then 10 - depth
            elif checkWinCondition position opponent then depth - 10
            elif position |> Array.forall (fun cell -> cell <> Player.None) then 0
            else
                let scores =
                    getAvailableMoves position
                    |> List.map (fun index ->
                        let nextPosition = Array.copy position
                        nextPosition.[index] <- nextPlayer
                        let next = if nextPlayer = aiPlayer then opponent else aiPlayer
                        evaluatePosition nextPosition next (depth + 1))

                if nextPlayer = aiPlayer then List.max scores else List.min scores

        let scoredMoves =
            moves
            |> List.map (fun index ->
                let nextPosition = Array.copy gameBoard
                nextPosition.[index] <- aiPlayer
                index, evaluatePosition nextPosition opponent 1)

        let bestScore = scoredMoves |> List.maxBy snd |> snd
        scoredMoves |> List.tryFind (fun (_, score) -> score = bestScore) |> Option.map fst

    member this.Board = board
    member this.CurrentTurn = currentTurn
    member this.IsGameOver = isGameOver
    member this.Winner = winner
    member this.CanUndo = history.Count > 0
    member this.WinningLine =
        if winner = Player.None then
            []
        else
            winningLines
            |> Array.tryFind (fun line -> line |> Array.forall (fun index -> board.[index] = winner))
            |> Option.map Array.toList
            |> Option.defaultValue []

    member this.Difficulty
        with get() = difficulty
        and set(value) = difficulty <- value

    member this.ResetGame() =
        board <- Array.create 9 Player.None
        currentTurn <- Player.X
        isGameOver <- false
        winner <- Player.None
        history.Clear()

    member this.UndoMove(undoBotTurn: bool) =
        let restorePreviousMove () =
            if history.Count = 0 then Option.None
            else
                let historyIndex = history.Count - 1
                let previousBoard, previousTurn, previousGameOver, previousWinner, movedPlayer = history.[historyIndex]
                history.RemoveAt(historyIndex)
                board <- previousBoard
                currentTurn <- previousTurn
                isGameOver <- previousGameOver
                winner <- previousWinner
                Some movedPlayer

        match restorePreviousMove () with
        | Option.Some Player.O when undoBotTurn -> restorePreviousMove () |> ignore
        | _ -> ()

    member this.MakeMove(index: int) =
        if index < 0 || index > 8 || board.[index] <> Player.None || isGameOver then
            false
        else
            history.Add(Array.copy board, currentTurn, isGameOver, winner, currentTurn)
            board.[index] <- currentTurn
            if checkWinCondition board currentTurn then
                winner <- currentTurn
                isGameOver <- true
            elif board |> Array.forall (fun player -> player <> Player.None) then
                winner <- Player.None
                isGameOver <- true
            else
                currentTurn <- if currentTurn = Player.X then Player.O else Player.X
            true

    member this.GetAIMove() =
        let moves = getAvailableMoves board
        let opponent = if currentTurn = Player.X then Player.O else Player.X
        let chooseRandom () = moves.[rand.Next(moves.Length)]
        let chooseCenterThenCorner () =
            if List.contains 4 moves then 4
            else
                let corners = moves |> List.filter (fun index -> [0; 2; 6; 8] |> List.contains index)
                if List.isEmpty corners then chooseRandom () else corners.[rand.Next(corners.Length)]

        if List.isEmpty moves then -1
        else
            match difficulty with
            | GameDifficulty.Rookie -> chooseRandom ()
            | GameDifficulty.Cadet ->
                if rand.NextDouble() < 0.7 then chooseRandom () else chooseCenterThenCorner ()
            | GameDifficulty.Tactician ->
                findCriticalMove board currentTurn moves |> Option.defaultWith chooseCenterThenCorner
            | GameDifficulty.Veteran ->
                match findCriticalMove board currentTurn moves with
                | Option.Some move -> move
                | Option.None -> findCriticalMove board opponent moves |> Option.defaultWith chooseCenterThenCorner
            | GameDifficulty.Nemesis ->
                minimaxBestMove board currentTurn moves |> Option.defaultWith chooseRandom
