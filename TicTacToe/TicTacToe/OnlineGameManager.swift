import Foundation
import GameKit
import SwiftUI
import Combine

class OnlineGameManager: NSObject, ObservableObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    @Published var isPlayerAuthenticated: Bool = false
    @Published var localPlayerName: String = "Guest"
    @Published var authenticationError: String? = nil
    
    // Multiplayer Connection States
    @Published var currentMatch: GKMatch? = nil
    @Published var matchInfoMessage: String = "READY FOR NET LINK INITIALIZATION"
    
    // Dynamic move packet router callback link to UI
    var onMoveReceived: ((Int) -> Void)?
    
    override init() {
        super.init()
        authenticateLocalPlayer()
    }
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let vc = viewController {
                    self?.presentAuthentication(vc)
                } else if localPlayer.isAuthenticated {
                    self?.isPlayerAuthenticated = true
                    self?.localPlayerName = localPlayer.displayName
                    self?.authenticationError = nil
                    print("Game Center sandbox profile secure: \(localPlayer.displayName)")
                } else {
                    self?.isPlayerAuthenticated = false
                    self?.authenticationError = error?.localizedDescription ?? "Unknown Game Center Error"
                }
            }
        }
    }
    
    // MARK: - Game Center Dashboard Score Reporting Interface
    func reportScoreToLeaderboard(wins: Int) {
        guard isPlayerAuthenticated else { return }
        
        // This identifier maps directly to your configuration settings block inside App Store Connect / Xcode
        let leaderboardID = "com.seaus.neogrid.total_wins"
        
        GKLeaderboard.submitScore(wins, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Failed to sync score matrix to dashboard: \(error.localizedDescription)")
            } else {
                print("Game Center leaderboard successfully updated to: \(wins) wins")
            }
        }
    }
    
    // MARK: - Achievement Progression Pipeline (Dashboard Interface Hook)
    func reportWinAchievement(currentStreakCount: Int) {
        guard isPlayerAuthenticated else { return }
        
        let achievementID = "com.seaus.neogrid.win_streak"
        let achievement = GKAchievement(identifier: achievementID)
        
        let targetWins = 3.0
        let percentage = (Double(currentStreakCount) / targetWins) * 100.0
        
        achievement.percentComplete = min(percentage, 100.0)
        achievement.showsCompletionBanner = true // Triggers Apple's native system card banner popup
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to dispatch achievement sync stream: \(error.localizedDescription)")
            } else {
                print("Game Center achievement system matrix updated: \(achievement.percentComplete)%")
            }
        }
    }
    
    // MARK: - Native Multiplatform Matchmaker Trigger
    func presentMatchmakerInterface() {
        guard isPlayerAuthenticated else { return }
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.defaultNumberOfPlayers = 2
        
        guard let mmvc = GKMatchmakerViewController(matchRequest: request) else { return }
        mmvc.matchmakerDelegate = self
        
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                if UIDevice.current.userInterfaceIdiom == .pad { mmvc.modalPresentationStyle = .formSheet }
                rootVC.present(mmvc, animated: true)
            }
        }
        #elseif os(macOS)
        if let mainWindow = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            mainWindow.contentViewController?.presentAsSheet(mmvc)
        }
        #endif
    }
    
    // MARK: - GKMatchmakerViewControllerDelegate Interface Linkage
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        dismissMatchmaker(viewController)
        self.currentMatch = match
        match.delegate = self
        
        DispatchQueue.main.async {
            self.matchInfoMessage = "QUANTUM TUNNEL SECURED. MATCH START!"
        }
    }
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        dismissMatchmaker(viewController)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        dismissMatchmaker(viewController)
        DispatchQueue.main.async {
            self.matchInfoMessage = "TUNNEL CONFIGURATION ERROR: \(error.localizedDescription)"
        }
    }
    
    private func dismissMatchmaker(_ vc: AnyObject) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let uivc = vc as? UIViewController { uivc.dismiss(animated: true) }
        #elseif os(macOS)
        if let nsvc = vc as? NSViewController { nsvc.presentingViewController?.dismiss(nsvc) }
        #endif
    }
    
    // MARK: - Network Package Dispatch Logic
    func sendGameMove(cellIndex: Int) {
        guard let match = currentMatch else { return }
        let packetData = Data([UInt8(cellIndex)])
        
        do {
            try match.sendData(toAllPlayers: packetData, with: .reliable)
        } catch {
            print("Failed to stream binary turn packet payload: \(error)")
        }
    }
    
    // MARK: - GKMatchDelegate Stream Interceptor
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if let positionIndex = data.first {
            DispatchQueue.main.async {
                self.onMoveReceived?(Int(positionIndex))
            }
        }
    }
    
    private func presentAuthentication(_ vc: AnyObject) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let uiViewController = vc as? UIViewController {
            let connectedScenes = UIApplication.shared.connectedScenes
            if let windowScene = connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.present(uiViewController, animated: true)
            }
        }
        #elseif os(macOS)
        if let nsViewController = vc as? NSViewController {
            if let mainWindow = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                mainWindow.contentViewController?.presentAsSheet(nsViewController)
            }
        }
        #endif
    }
}
