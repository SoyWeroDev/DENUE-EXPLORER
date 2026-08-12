// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "DENUEExplorer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DENUEExplorer", targets: ["App"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [],
            path: "Sources"
        )
    ]
)
