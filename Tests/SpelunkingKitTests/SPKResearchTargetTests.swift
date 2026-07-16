import Foundation
import SpelunkingKit
import Testing
import WallpaperTypes

@Suite("Research targets")
struct SPKResearchTargetTests {
    @Test("MediaRemote target points at the seeded documentation and research directories")
    func mediaRemotePaths() {
        let target = SPKResearchTarget.mediaRemote

        #expect(target.name == "MediaRemote.framework")
        #expect(target.documentationPath == "docs/frameworks/MediaRemote")
        #expect(target.researchPath == "research/MediaRemote")
    }

    @Test("WallpaperAgent target points at the debug XPC documentation and research directories")
    func wallpaperAgentPaths() {
        let target = SPKResearchTarget.wallpaperAgent

        #expect(target.name == "WallpaperAgent")
        #expect(target.documentationPath == "docs/frameworks/WallpaperAgent")
        #expect(target.researchPath == "research/WallpaperAgent")
    }

    @Test("Wallpaper debug mirror types preserve synthesized enum coding")
    func wallpaperDebugMirrorRoundTrips() throws {
        let message = WallpaperDebugRequestMessage(
            extensionIdentifier: "com.apple.wallpaper.extension.aerials",
            request: .accessAllAssets(.downloaded)
        )

        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(WallpaperDebugRequestMessage.self, from: data)

        #expect(decoded == message)
        #expect(String(decoding: data, as: UTF8.self).contains("\"downloaded\""))
        #expect(!String(decoding: data, as: UTF8.self).contains("rawValue"))
    }
}
