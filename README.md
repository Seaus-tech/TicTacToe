# 🚀 NEO-GRID: Multiplatform Neon Tic-Tac-Toe

<p align="center">
  <strong>A futuristic, neon-styled Tic-Tac-Toe game engine built natively using SwiftUI.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS-blue?style=flat-square&logo=apple" alt="Platforms" />
  <img src="https://img.shields.io/badge/Language-Swift-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Framework-SwiftUI-orange?style=flat-square&logo=swift" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Server-Node.js%20%7C%20WebSocket-green?style=flat-square&logo=node.js" alt="Node.js" />
</p>

---

## 🌌 Overview

NEO-GRID is a futuristic Tic-Tac-Toe game supporting full cross-platform operations across iOS, macOS, tvOS, and visionOS. It features a strategic local AI engine and real-time multiplayer online mode powered by a custom WebSocket configuration.

---

## ✨ Features

- 🟩 **Single Player Matrix** — Algorithmic defensive-offensive evaluation core with customizable difficulty levels (Easy, Medium, Hard)
- 🟦 **Local Double Player** — Native shared-device multiplayer mechanics with adaptive focus tracking
- 🟪 **Quantum Online Mode** — Bypasses proprietary signing restrictions using a custom WebSocket tunnel layer for instant move relays

---

## 🛠️ System Architecture

- **Client App** — Written completely in native Swift and SwiftUI using modern programmatic state hooks (`@StateObject`, `@Published`) to handle cross-platform screen updates smoothly
- **Game Server** — A lightweight, decoupled Node.js network switchboard that handles concurrent socket requests and routes data payloads between remote network nodes with zero configuration files

---

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- Node.js 18+ for the multiplayer server

### Running the Server

To run the online multiplayer layer locally:

```bash
# Enter server directory
cd Server

# Install runtime socket dependencies
npm install ws

# Start the connection switchboard
node server.js
```

Or use the automated launch script:

```bash
./launch_server.sh
```

---

## 📂 Repository Structure

```
TicTacToe/
├── TicTacToe/              # SwiftUI client source
│   ├── ContentView.swift   # Main game view
│   └── Models.swift        # Game logic and state
├── Server/                 # Node.js WebSocket server
│   └── server.js           # Main server script
├── launch_server.sh        # Automated server launcher
├── users.json              # User data store
└── README.md               # This file
```

---

## 🎮 Game Controls

- **Single Player**: Select difficulty and play against AI
- **Local Multiplayer**: Two players share the same device
- **Online Mode**: Connect to the server and play remotely

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

---

<p align="center">
  <sub>© 2026 Seaus Tech. All rights reserved.</sub>
</p>