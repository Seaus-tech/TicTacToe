// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TicTacToe",
    products: [
        .executable(name: "TicTacToe", targets: ["TicTacToeTarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/moreSwift/swift-cross-ui", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "TicTacToeTarget",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui")
            ],
            path: ".", // Points to the root directory where Package.swift lives
            exclude: [
                "TicTacToe.xcodeproj", 
                "TicTacToe/AppIcon.icon", 
                "TicTacToe/Info.plist", 
                "TicTacToe/TicTacToe.entitlements",
                "launch_server.sh",
                "server_launch_debug.log",
                "server_output.log"
            ],
            sources: ["TicTacToe"] // Restricts compile scanning strictly to your source folder
        )
    ]
)