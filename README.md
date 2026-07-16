# 🚀 NEO-GRID: Multiplatform Neon Tic-Tac-Toe

<p align="center>
  <strong>A futuristic, neon-styled Tic-Tac-Toe game engine built natively using SwiftUI.</strong>
</p>

<p align="center>
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS-blue?style=flat-square&logo=apple" alt="Platforms" />
  <img src="https://img.shields.io/badge/Language-Swift-F54A46?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Framework-SwiftUI-F54A46?style=flat-square&logo=swift" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Server-Node.js%20%7C%20WebSocket-339933?style=flat-square&logo=node.js" alt="Node.js" />
</p>

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Server](#running-the-server)
- [Controls](#controls)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Overview

NEO-GRID is a futuristic Tic-Tac-Toe game supporting full cross-platform operations across iOS, macOS, tvOS, and visionOS. It features a strategic local AI engine and real-time multiplayer online mode powered by a custom WebSocket configuration.

## Features

| Mode | Description |
|------|-------------|
| 🟩 **Single Player** | Algorithmic defensive-offensive evaluation core with customizable difficulty (Easy, Medium, Hard) |
| 🟦 **Local Double Player** | Native shared-device multiplayer with adaptive focus tracking |
| 🟪 **Quantum Online Mode** | Custom WebSocket tunnel layer for instant move relays |

## Screenshots

*(Coming soon)*

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / visionOS 1.0+
- Node.js 18+ for the multiplayer server

## Installation

```bash
# Clone the repository
git clone https://github.com/Seaus-tech/TicTacToe.git
cd TicTacToe

# Open in Xcode
open TicTacToe.xcodeproj
```

## Running the Server

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

## Controls

| Mode | Control |
|------|---------|
| All Platforms | Tap to place X or O |
| Online Mode | Connect to server and tap to move |

## Architecture

### Client App

Written completely in native Swift and SwiftUI using modern programmatic state hooks (`@StateObject`, `@Published`) to handle cross-platform screen updates smoothly.

### Game Server

A lightweight, decoupled Node.js network switchboard that handles concurrent socket requests and routes data payloads between remote network nodes with zero configuration files.

## Repository Structure

```
TicTacToe/
├── TicTacToe/              # SwiftUI client source
│   ├── ContentView.swift   # Main game view
│   ├── Models.swift        # Game logic and state
│   └── Views/              # Additional UI components
├── Server/                 # Node.js WebSocket server
│   └── server.js           # Main server script
├── launch_server.sh        # Automated server launcher
├── users.json              # User data store
└── README.md               # This file
```

## Roadmap

- [ ] Add spectator mode for online games
- [ ] Implement game replay system
- [ ] Add custom rule variants
- [ ] Tournament mode

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

© 2026 Seaus Tech. All rights reserved.