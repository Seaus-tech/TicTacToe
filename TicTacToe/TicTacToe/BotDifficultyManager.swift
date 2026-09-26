import SwiftUI
import GameKit
import Combine

@MainActor
class BotDifficultyManager: ObservableObject {
    @Published var selectedLevel: Int = 1
    
    private let saveName = "com.seaustech.neogrid.botlevel"
    private let localLevelKey = "com.seaustech.neogrid.localBotLevel"
    
    init() {
        fetchDifficulty()
    }
    
    // MARK: - Save Layer with Automatic Local Fallback
    func saveDifficultyToCloud(level: Int) {
        // Fallback step 1: Always update UI state immediately for responsiveness
        self.selectedLevel = level
        
        // If the player isn't even authenticated in Game Center, jump straight to local preference storage
        guard GKLocalPlayer.local.isAuthenticated else {
            saveToLocalStorage(level: level)
            return
        }
        
        let levelData = Data(String(level).utf8)
        
        // Attempt the official Game Center iCloud sandbox save container pipeline
        GKLocalPlayer.local.saveGameData(levelData, withName: saveName) { [weak self] savedGame, error in
            guard let self = self else { return }
            
            if let error = error {
                // iCloud fails (e.g., due to your current Personal Development Team restrictions)
                print("⚠️ Game Center Cloud Sync skipped or failed: \(error.localizedDescription)")
                print("🔄 Diverting layout save path to secure local storage fallback...")
                
                Task { @MainActor in
                    self.saveToLocalStorage(level: level)
                }
            } else {
                print("🌌 Premium Sync Successful: Level \(level) broadcast directly to Game Center Cloud.")
            }
        }
    }
    
    // MARK: - Fetch Layer with Automatic Cross-Check
    func fetchDifficulty() {
        // Step 1: Initialize baseline with local disk preferences instantly
        let localSavedLevel = UserDefaults.standard.integer(forKey: localLevelKey)
        if localSavedLevel >= 1 && localSavedLevel <= 5 {
            self.selectedLevel = localSavedLevel
        }
        
        // Step 2: If premium cloud containers are active, pull down the override values
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        GKLocalPlayer.local.fetchSavedGames { [weak self] savedGames, error in
            guard let self = self,
                  let savedGame = savedGames?.first(where: { $0.name == self.saveName }) else { return }
            
            savedGame.loadData { data, error in
                if let data = data,
                   let levelString = String(data: data, encoding: .utf8),
                   let levelInt = Int(levelString) {
                    DispatchQueue.main.async {
                        self.selectedLevel = levelInt
                        // Keep local storage mirrored just in case
                        UserDefaults.standard.set(levelInt, forKey: self.localLevelKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func saveToLocalStorage(level: Int) {
        UserDefaults.standard.set(level, forKey: localLevelKey)
        print("💾 Local Storage Synced: Tier \(level) locked into local app preferences container.")
    }
}

