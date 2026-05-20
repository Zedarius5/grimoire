// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Grimoire",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GrimoireKit", targets: ["GrimoireKit"]),
    ],
    targets: [
        .executableTarget(
            name: "Grimoire",
            dependencies: ["GrimoireKit"],
            path: "Sources/Grimoire",
            resources: [
                // game-icons.net SVGs used by `StatusBox` and the icon
                // browser. Kept in their own subdirectory so future asset
                // sets can sit alongside without colliding.
                .process("Resources/game-icons"),
            ]
        ),
        .target(
            name: "GrimoireKit",
            path: "Sources/GrimoireKit"
        ),
        .testTarget(
            name: "GrimoireKitTests",
            dependencies: ["GrimoireKit"],
            path: "Tests/GrimoireKitTests"
        ),
    ]
)
