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
                // SGE login helper (our Ruby wrapper around Lich's EAccess).
                // Bundled so the app resolves it at runtime via Bundle.module
                // instead of a hardcoded checkout path — works on any Mac.
                .copy("Resources/sge_auth.rb"),
                // Starter highlight rules and spell presets, loaded on first
                // run (no saved config) so a new user sees how groups,
                // notify rules, and preset styling are meant to be used.
                .copy("Resources/default-highlights.json"),
                .copy("Resources/default-spell-presets.json"),
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
