import Foundation
import SwiftUI
import Combine

class OnlineGameManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var isAuthenticated = true
    @Published var match: Bool? = nil
    @Published var isMyTurn = true
    @Published var opponentName: String = "NEO-NET Enemy"
    @Published var showMatchmaker = false
    
    var localPlayerPiece: Player = .x
    var onReceiveMove: ((Int) -> Void)?
    var onReceiveReset: (() -> Void)?

    init() {
        // No super.init() required here anymore!
    }
    
    func findMatch() {
        showMatchmaker = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showMatchmaker = false
            self.match = true
            self.localPlayerPiece = .x
            self.isMyTurn = true
            self.opponentName = "Quantum_Player"
        }
    }
    
    func sendMove(at index: Int) {
        isMyTurn = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isMyTurn = true
            let mockMove = self.getMockNetworkOpponentMove()
            if mockMove != -1 {
                self.onReceiveMove?(mockMove)
            }
        }
    }
    
    func sendResetRequest() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onReceiveReset?()
        }
    }
    
    private func getMockNetworkOpponentMove() -> Int {
        return -1
    }
}

