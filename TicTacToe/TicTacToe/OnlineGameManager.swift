import Foundation
import SwiftUI
import Combine

class OnlineGameManager: ObservableObject {
    @Published var isAuthenticated = true
    @Published var match: Bool? = nil
    @Published var isMyTurn = false
    @Published var opponentName: String = "Searching..."
    @Published var showMatchmaker = false
    @Published var alertMessage: String? = nil // Tracks network alerts dynamically
    
    var localPlayerPiece: Player = .x
    var onReceiveMove: ((Int) -> Void)?
    var onReceiveReset: (() -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    struct NetworkPacket: Codable {
        let type: String
        let index: Int?
        let piece: String?
        let yourTurn: Bool?
        let opponent: String?
    }

    init() {}
    
    func findMatch() {
        showMatchmaker = true
        opponentName = "Connecting to Core..."
        
        let url = URL(string: "ws://localhost:8080")!
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForData()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.match = nil
            self.showMatchmaker = false
        }
    }
    
    func sendMove(at index: Int) {
        isMyTurn = false
        let packet = NetworkPacket(type: "move", index: index, piece: nil, yourTurn: nil, opponent: nil)
        sendPacket(packet)
    }
    
    func sendResetRequest() {
        let packet = NetworkPacket(type: "reset", index: nil, piece: nil, yourTurn: nil, opponent: nil)
        sendPacket(packet)
    }
    
    private func sendPacket(_ packet: NetworkPacket) {
        guard let data = try? JSONEncoder().encode(packet),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Network transmit failure: \(error.localizedDescription)")
            }
        }
    }
    
    private func listenForData() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("Socket connection lost: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.match = nil
                    self.showMatchmaker = false
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let packet = try? JSONDecoder().decode(NetworkPacket.self, from: data) {
                        DispatchQueue.main.async {
                            self.handleIncomingPacket(packet)
                        }
                    }
                default: break
                }
                self.listenForData()
            }
        }
    }
    
    private func handleIncomingPacket(_ packet: NetworkPacket) {
        switch packet.type {
        case "assign_piece":
            if let pieceStr = packet.piece {
                self.localPlayerPiece = pieceStr == "X" ? .x : .o
            }
            
        case "start_game":
            self.showMatchmaker = false
            self.match = true
            self.isMyTurn = packet.yourTurn ?? false
            self.opponentName = packet.opponent ?? "Remote Player"
            
        case "move":
            if let moveIndex = packet.index {
                self.onReceiveMove?(moveIndex)
                self.isMyTurn = true
            }
            
        case "reset":
            self.onReceiveReset?()
            self.isMyTurn = (self.localPlayerPiece == .x)
            
        case "opponent_disconnected":
            // AUTOMATIC LOBBY RECOVERY: Reset local game states but don't close the socket connection!
            self.match = nil
            self.showMatchmaker = true
            self.opponentName = "Opponent disconnected. Waiting for new challenger..."
            
        case "lobby_full":
            self.disconnect()
            
        default: break
        }
    }
}
