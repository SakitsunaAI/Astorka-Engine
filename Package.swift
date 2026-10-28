// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstorkaEngine",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AstorkaCore",
            targets: ["AstorkaCore"]
        ),
        .executable(
            name: "astorka-cli",
            targets: ["AstorkaCLI"]
        ),
        .executable(
            name: "astorka-player",
            targets: ["AstorkaPlayer"]
        ),
        .executable(
            name: "astorka-editor",
            targets: ["AstorkaEditor"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AstorkaCore",
            dependencies: [],
            path: "Sources/AstorkaCore"
        ),
        .executableTarget(
            name: "AstorkaCLI",
            dependencies: ["AstorkaCore"],
            path: "Sources/AstorkaCLI"
        ),
        .executableTarget(
            name: "AstorkaPlayer",
            dependencies: ["AstorkaCore"],
            path: "Sources/AstorkaPlayer"
        ),
        .executableTarget(
            name: "AstorkaEditor",
            dependencies: ["AstorkaCore"],
            path: "Sources/AstorkaEditor"
        ),
        .testTarget(
            name: "AstorkaCoreTests",
            dependencies: ["AstorkaCore"],
            path: "Tests/AstorkaCoreTests"
        ),
    ]
)
