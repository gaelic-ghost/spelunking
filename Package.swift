// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Spelunking",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SpelunkingKit",
            targets: ["SpelunkingKit"]
        ),
        .library(
            name: "WallpaperTypes",
            targets: ["WallpaperTypes"]
        ),
        .executable(
            name: "spelunk",
            targets: ["spelunk"]
        )
    ],
    targets: [
        .target(
            name: "SpelunkingKit",
            dependencies: ["WallpaperTypes"]
        ),
        .target(
            name: "WallpaperTypes"
        ),
        .executableTarget(
            name: "spelunk",
            dependencies: ["SpelunkingKit"]
        ),
        .testTarget(
            name: "SpelunkingKitTests",
            dependencies: ["SpelunkingKit", "WallpaperTypes"]
        )
    ],
    swiftLanguageModes: [.v6]
)
