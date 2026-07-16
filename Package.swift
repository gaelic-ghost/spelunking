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
            name: "Wallpaper",
            targets: ["Wallpaper"]
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
            dependencies: ["Wallpaper", "WallpaperTypes"]
        ),
        .target(
            name: "Wallpaper"
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
            dependencies: ["SpelunkingKit", "Wallpaper", "WallpaperTypes"]
        )
    ],
    swiftLanguageModes: [.v6]
)
