import SwiftUI

struct AuthView: View {
    @StateObject private var gameManager = OnlineGameManager()
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var useOfflineBypass = false
    @State private var pulseVector = false
    
    var body: some View {
        Group {
            if gameManager.isAuthenticated || useOfflineBypass {
                ContentView(gameManager: gameManager)
            } else {
                ZStack {
                    Color(red: 0.05, green: 0.04, blue: 0.08)
                        .edgesIgnoringSafeArea(.all)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.35))
                        .frame(width: 450, height: 450)
                        .blur(radius: 90)
                        .offset(x: pulseVector ? 200 : -200, y: pulseVector ? -150 : 150)
                    
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 22) {
                            VStack(spacing: 4) {
                                Text("ARCADE NETWORK INTERFACE")
                                    .font(.system(.title2, design: .monospaced))
                                    .bold()
                                    .foregroundColor(.white)
                                Text("MULTIPLAYER MATRIX NETWORK LINK")
                                    .font(.caption2)
                                    .tracking(2)
                                    .foregroundColor(.purple)
                                    .shadow(color: .purple, radius: 4)
                            }
                            .padding(.bottom, 10)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username").font(.caption).foregroundColor(.secondary).bold()
                                TextField("Enter profile username...", text: $usernameInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password").font(.caption).foregroundColor(.secondary).bold()
                                SecureField("••••••••", text: $passwordInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            if let error = gameManager.authError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 2)
                            }
                            
                            if gameManager.isProcessingAuth {
                                ProgressView("Contacting authentication server...").padding(.vertical, 5)
                            } else {
                                VStack(spacing: 12) {
                                    AppAuthButtons(gameManager: gameManager, usernameInput: usernameInput, passwordInput: passwordInput)
                                    
                                    Button(action: {
                                        gameManager.currentUsername = "Local Guest"
                                        useOfflineBypass = true
                                    }) {
                                        Text("Skip Server (Play Local / Bots)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .underline()
                                            .padding(.top, 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(45)
                        .frame(maxWidth: 440)
                        .liquidGlassStyle()
                        
                        Spacer()
                    }
                    .padding(24)
                }
                .onAppear {
                    withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                        pulseVector = true
                    }
                }
            }
        }
        .onChange(of: gameManager.isAuthenticated) { _, authenticated in
            if !authenticated { useOfflineBypass = false }
        }
    }
}

struct AppAuthButtons: View {
    @ObservedObject var gameManager: OnlineGameManager
    let usernameInput: String
    let passwordInput: String
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                gameManager.login(username: usernameInput, password: passwordInput)
            }) {
                Text("Login")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(usernameInput.isEmpty || passwordInput.isEmpty ? Color.white.opacity(0.05) : Color.purple.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(usernameInput.isEmpty || passwordInput.isEmpty)
            
            Button(action: {
                gameManager.register(username: usernameInput, password: passwordInput)
            }) {
                Text("Register")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(usernameInput.isEmpty || passwordInput.isEmpty ? Color.white.opacity(0.05) : Color.blue.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(usernameInput.isEmpty || passwordInput.isEmpty)
        }
    }
}
