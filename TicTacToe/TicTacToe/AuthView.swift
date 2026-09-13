import SwiftUI
import GameKit

struct AuthView: View {
    // Access the global game manager we injected in TicTacToeApp.swift
    @EnvironmentObject var gameManager: OnlineGameManager
    
    var body: some View {
        ZStack {
            // Neon Futuristic Dark Theme Background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            VCenterContent
        }
    }
    
    private var VCenterContent: some View {
        VStack(spacing: 30) {
            // Header Neon Title Accent
            VStack(spacing: 8) {
                Text("NEO-GRID")
                    .font(.system(size: 42, weight: .black, design: .monospaced))
                    .foregroundColor(Color.cyan)
                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                
                Text("QUANTUM PROTOCOL INTERFACE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Status Card Matrix Display Block
            VStack(spacing: 15) {
                if gameManager.isPlayerAuthenticated {
                    // Authenticated State Layout Panel
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.6), radius: 8)
                    
                    Text("SECURE LINK ESTABLISHED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("User: \(gameManager.localPlayerName)")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                } else if let error = gameManager.authenticationError {
                    // Error Connection Fallback Block
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("LINKING PROTOCOL FAILURE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    // Default State: Attempting Initialization Handshake
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(1.5)
                    
                    Text("INITIALIZING GAME CENTER...")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan.opacity(0.4), radius: 5)
                }
            }
            .padding(30)
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gameManager.isPlayerAuthenticated ? Color.green.opacity(0.3) : Color.cyan.opacity(0.2), lineWidth: 1)
            )
            
            Spacer()
            
            // Manual Action Control Deck Interface Row
            if !gameManager.isPlayerAuthenticated {
                Button(action: {
                    gameManager.authenticateLocalPlayer()
                }) {
                    Text("MANUAL CORE AUTHENTICATION")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.cyan)
                        .cornerRadius(10)
                        .shadow(color: .cyan.opacity(0.6), radius: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
}

