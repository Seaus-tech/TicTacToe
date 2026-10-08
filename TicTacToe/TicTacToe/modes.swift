// MARK: - File 1: Modes.swift
import SwiftUI

/// Defines the available gameplay rule variations for NEO-GRID
enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case quantumFading = "Quantum Fading"
    case inverse = "Inverse (Misere)"
    case gravityDrop = "Gravity Drop"
    
    var id: String { self.rawValue }
    
    /// Description of the rule mechanics to show the player
    var description: String {
        switch self {
        case .classic:
            return "Standard TicTacToe rules. Get 3 in a row to win."
        case .quantumFading:
            return "Pieces fade away after 3 total turns by that player! Keeps the grid dynamic and active."
        case .inverse:
            return "Avoid winning at all costs! The first person to get 3 in a row loses the match instantly."
        case .gravityDrop:
            return "Pieces fall down to the lowest empty row in that column, mimicking Connect Four mechanics!"
        }
    }
    
    /// Subtitle highlighting the tactical shift
    var subtitle: String {
        switch self {
        case .classic:
            return "Perfect for testing your core skills."
        case .quantumFading:
            return "Endgames never become stale static loops."
        case .inverse:
            return "Forces you to think completely backwards."
        case .gravityDrop:
            return "Modifies column physics and board control rules."
        }
    }
}
