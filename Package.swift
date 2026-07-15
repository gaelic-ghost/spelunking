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
        .executable(
            name: "spelunk",
            targets: ["spelunk"]
        )
    ],
    targets: [
        .target(
            name: "SpelunkingKit"
        ),
        .executableTarget(
            name: "spelunk",
            dependencies: ["SpelunkingKit"]
        ),
        .testTarget(
            name: "SpelunkingKitTests",
            dependencies: ["SpelunkingKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
