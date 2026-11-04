// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TicTacToe",
    products: [
        .executable(name: "TicTacToe", targets: ["TicTacToeTarget"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/moreSwift/swift-cross-ui",
            .upToNextMinor(from: "0.2.0")
        )
    ],
    targets: [
        .executableTarget(
            name: "TicTacToeTarget",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui")
            ],
            path: "TicTacToe",
            exclude: [
                ".DS_Store",
                "AppIcon.icon",
                "AuthView.swift",
                "BotDifficultyManager.swift",
                "ContentView.swift",
                "DifficultySelectorView.swift",
                "GameViewModel.swift",
                "Info.plist",
                "modes.swift",
                "OnlineGameManager.swift",
                "PiecePickerSheet.swift",
                "Player.swift",
                "ReleaseNotesData.swift",
                "TicTacToe.entitlements",
                "View+Glass.swift",
                "WhatsNewView.swift"
            ],
            sources: [
                "TicTacToeApp.swift",
                "WindowsContentView.swift",
                "AILogic.swift"
            ]
        )
    ]
)