import Foundation
import GameKit
import SwiftUI
import Combine

// MARK: - Move packet types sent over GKMatch data channel
private enum PacketType: UInt8 {
    case move  = 1
    case reset = 2
}

class OnlineGameManager: NSObject, ObservableObject,
                         GKMatchmakerViewControllerDelegate,
                         GKMatchDelegate {

    // MARK: - Published state
    @Published var isPlayerAuthenticated: Bool = false
    @Published var localPlayerName: String     = "Guest"
    @Published var authenticationError: String? = nil
    @Published var currentMatch: GKMatch?      = nil
    @Published var matchInfoMessage: String    = "READY FOR NET LINK INITIALIZATION"

    // MARK: - Callbacks → wired from ContentView
    var onMoveReceived: ((Int) -> Void)?
    var onOpponentDisconnected: (() -> Void)?
    var onMatchStarted: ((_ isFirstPlayer: Bool) -> Void)?
    var onResetReceived: (() -> Void)?

    // First-player flag (whoever sees the matchmaker first gets X)
    private var isFirstPlayer: Bool = true

    override init() {
        super.init()
        authenticateLocalPlayer()
    }

    // MARK: - Game Center Authentication
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let vc = viewController {
                    self?.presentAuthentication(vc)
                } else if localPlayer.isAuthenticated {
                    self?.isPlayerAuthenticated = true
                    self?.localPlayerName       = localPlayer.displayName
                    self?.authenticationError   = nil
                } else {
                    self?.isPlayerAuthenticated  = false
                    self?.authenticationError    = error?.localizedDescription ?? "Unknown Game Center Error"
                }
            }
        }
    }

    // MARK: - Game Center Leaderboard
    func reportScoreToLeaderboard(wins: Int) {
        guard isPlayerAuthenticated else { return }
        GKLeaderboard.submitScore(wins, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: ["com.seaus.neogrid.total_wins"]) { error in
            if let error = error {
                print("Leaderboard sync failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Game Center Achievement
    func reportWinAchievement(currentStreakCount: Int) {
        guard isPlayerAuthenticated else { return }
        let achievement = GKAchievement(identifier: "com.seaus.neogrid.win_streak")
        achievement.percentComplete   = min((Double(currentStreakCount) / 3.0) * 100.0, 100.0)
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Achievement sync failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Present Matchmaker
    func presentMatchmakerInterface() {
        guard isPlayerAuthenticated else { return }
        let request = GKMatchRequest()
        request.minPlayers            = 2
        request.maxPlayers            = 2
        request.defaultNumberOfPlayers = 2

        guard let mmvc = GKMatchmakerViewController(matchRequest: request) else { return }
        mmvc.matchmakerDelegate = self
        presentViewController(mmvc)
    }

    // MARK: - Send Move
    func sendGameMove(cellIndex: Int) {
        guard let match = currentMatch else { return }
        // Packet: [type, index]
        let packet = Data([PacketType.move.rawValue, UInt8(cellIndex)])
        try? match.sendData(toAllPlayers: packet, with: .reliable)
    }

    // MARK: - Send Reset
    func sendReset() {
        guard let match = currentMatch else { return }
        let packet = Data([PacketType.reset.rawValue])
        try? match.sendData(toAllPlayers: packet, with: .reliable)
    }

    // MARK: - GKMatchmakerViewControllerDelegate
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFind match: GKMatch) {
        dismissViewController(viewController)
        self.currentMatch  = match
        match.delegate     = self
        // The player who triggered the matchmaker is "first" (gets X)
        isFirstPlayer      = true
        DispatchQueue.main.async {
            self.matchInfoMessage = "Match found! Game starting…"
            self.onMatchStarted?(self.isFirstPlayer)
        }
    }

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        dismissViewController(viewController)
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFailWithError error: Error) {
        dismissViewController(viewController)
        DispatchQueue.main.async {
            self.matchInfoMessage = "Matchmaking error: \(error.localizedDescription)"
        }
    }

    // MARK: - GKMatchDelegate — incoming data
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let typeByte = data.first, let type = PacketType(rawValue: typeByte) else { return }
        DispatchQueue.main.async {
            switch type {
            case .move:
                if data.count >= 2 {
                    self.onMoveReceived?(Int(data[1]))
                }
            case .reset:
                self.onResetReceived?()
            }
        }
    }

    // MARK: - GKMatchDelegate — connection state
    func match(_ match: GKMatch, player: GKPlayer,
               didChange state: GKPlayerConnectionState) {
        if state == .disconnected {
            DispatchQueue.main.async {
                self.onOpponentDisconnected?()
            }
        }
    }

    // MARK: - Helpers
    private func presentViewController(_ vc: AnyObject) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let uivc = vc as? UIViewController {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    uivc.modalPresentationStyle = .formSheet
                }
                root.present(uivc, animated: true)
            }
        }
        #elseif os(macOS)
        if let nsvc = vc as? NSViewController,
           let main = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            main.contentViewController?.presentAsSheet(nsvc)
        }
        #endif
    }

    private func dismissViewController(_ vc: AnyObject) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let uivc = vc as? UIViewController { uivc.dismiss(animated: true) }
        #elseif os(macOS)
        if let nsvc = vc as? NSViewController { nsvc.presentingViewController?.dismiss(nsvc) }
        #endif
    }

    private func presentAuthentication(_ vc: AnyObject) {
        presentViewController(vc)
    }
}
