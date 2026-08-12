// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "DENUEExplorer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DENUEExplorer", targets: ["DENUEExplorerApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .executableTarget(
            name: "DENUEExplorerApp",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources"
        )
    ]
)
