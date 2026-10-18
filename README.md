# 🚀 NEO-GRID: Multiplatform Neon Tic-Tac-Toe

<p align="center>
  <strong>A futuristic, neon-styled Tic-Tac-Toe game engine built natively using SwiftUI.</strong>
</p>

<p align="center>
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Apple%20platforms-blue?style=flat-square" alt="Platforms" />
  <img src="https://img.shields.io/badge/Language-Swift-F54A46?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Framework-SwiftCrossUI%20%7C%20SwiftUI-F54A46?style=flat-square&logo=swift" alt="SwiftCrossUI and SwiftUI" />
  <img src="https://img.shields.io/badge/Windows%20fallback-Node.js%20%7C%20WebSocket-339933?style=flat-square&logo=node.js" alt="Windows-only Node.js fallback" />
</p>

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Windows-only Multiplayer Fallback](#windows-only-multiplayer-fallback)
- [Controls](#controls)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Overview

NEO-GRID is a futuristic Tic-Tac-Toe game with a native SwiftUI/GameKit client for Apple platforms and a SwiftCrossUI/WinUI desktop client for Windows. Both clients provide local play against the AI or another person. Online matchmaking uses GameKit on Apple platforms.

## Features

| Mode | Description |
|------|-------------|
| 🟩 **Single Player** | Algorithmic defensive-offensive evaluation core with customizable difficulty (Easy, Medium, Hard) |
| 🟦 **Local Double Player** | Native shared-device multiplayer with adaptive focus tracking |
| 🟪 **Online Multiplayer** | Game Center matchmaking and move relay on Apple platforms |

## Screenshots

*(Coming soon)*

## Prerequisites

- Windows 10/11: Swift 6.0 or later, Visual Studio 2022 C++ build tools, and Windows SDK
- Xcode 15.0 or later for native Apple builds
- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / visionOS 1.0+ for Apple builds
- Node.js 18+ and npm for the Windows-only multiplayer fallback

## Installation

### Windows

The Windows desktop app is written in Swift and uses SwiftCrossUI's native WinUI backend. Install the official Swift Windows toolchain, Visual Studio C++ build tools, and Windows SDK. Open a Visual Studio Developer PowerShell/Command Prompt for the same target architecture as the Swift toolchain, then run:

```powershell
cd TicTacToe
.\build_windows.ps1
```

The helper forwards the Visual Studio/Windows SDK headers from `INCLUDE` to SwiftPM's C/C++ dependencies (including the WinUI interop and zlib targets). Use `-BuildOnly` to compile without launching. For a release build, run `.\build_windows.ps1 -Configuration release -BuildOnly`; after a successful build, the helper prints the exact executable path. SwiftPM selects the Windows backend through `DefaultBackend`. The Windows target reuses the game AI and provides computer and local two-player modes. GameKit-backed online matchmaking, achievements, and score reporting are available only in the unchanged Apple SwiftUI app.

### Apple platforms

Open `TicTacToe/TicTacToe.xcodeproj` in Xcode and build for a supported Apple platform.

## Windows-only Multiplayer Fallback

Apple builds continue to use GameKit and do not use Node.js. The repository retains a legacy Node.js WebSocket server for Windows-only development; it is separate from the Windows Swift UI client and is not used by Apple builds. To run that server from the repository root, use `.\start_windows.ps1` in PowerShell. The script installs the declared dependency if needed and starts the server on port 8080. The server refuses to run on macOS or Linux.

## Controls

| Mode | Control |
|------|---------|
| Apple platforms | Tap or click to place X or O; online matchmaking uses GameKit |
| Windows desktop | Click to place X or O in computer or local two-player mode |

## Architecture

### Client App

The native Apple client uses SwiftUI and GameKit. The Windows desktop client is also written in Swift and uses SwiftCrossUI's WinUI backend; it shares the AI logic and supports computer and local two-player games. Game Center authentication, achievements, and matchmaking remain Apple-only.

### Multiplayer

Apple builds use GameKit directly. The Windows Swift client currently supports local play; the retained Node.js service is a Windows-only legacy development tool and is not yet connected to that client.

## Repository Structure

```
TicTacToe/
├── TicTacToe/                 # SwiftUI Apple app and SwiftCrossUI Windows app
│   ├── TicTacToeApp.swift
│   ├── WindowsContentView.swift
│   ├── AILogic.swift
│   └── build_windows.ps1       # Windows SDK-aware build/run helper
├── server.js                  # Node.js WebSocket server
├── start_windows.ps1          # Windows-only legacy server launcher
├── package.json               # Windows legacy server dependency
├── users.json                 # User data store
└── README.md                  # This file
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