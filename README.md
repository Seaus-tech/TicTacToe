# 🚀 NEO-GRID: Multiplatform Neon Tic-Tac-Toe

A futuristic, neon-styled Tic-Tac-Toe game engine built natively using **SwiftUI**. This project supports full cross-platform operations across **iOS, macOS, tvOS, and visionOS**, featuring both a highly strategic local AI engine and a real-time multiplayer online network layer powered by a custom WebSocket configuration.

## 🛠️ System Architecture

- **Client App:** Written completely in native Swift and SwiftUI using modern programmatic state hooks (`@StateObject`, `@Published`) to handle cross-platform screen updates smoothly.
- **Game Server:** A lightweight, decoupled Node.js network switchboard that handles concurrent socket requests and routes binary/string data payloads between remote network nodes with zero configuration files.

## 📡 Feature Breakdown

- 🟩 **Single Player Matrix:** Driven by an algorithmic defensive-offensive evaluation core featuring customizable operating difficulties (Easy, Medium, Hard).
- 🟦 **Local Double Player:** Native shared-device multiplayer mechanics with adaptive focus tracking support.
- 🟪 **Quantum Online Mode:** Bypasses proprietary signing restrictions by utilizing a custom local WebSocket tunnel layer for instant move relays.

---

## 🚀 Getting Started

### 1. Fire Up the Network Matrix
To run the online multiplayer layer locally without needing an Apple Developer Account signature, navigate to your server directory and run the Node.js switchboard:

```bash
# Enter server directory
cd Server

# Install runtime socket dependencies
npm install ws

# Start the connection switchboard
node server.js
