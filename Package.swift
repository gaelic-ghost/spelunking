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
            name: "mr-now-playing-probe",
            targets: ["MRNowPlayingProbe"]
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
            name: "MRNowPlayingProbe"
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
