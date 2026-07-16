import Foundation
import SpelunkingKit
import Testing
import Wallpaper
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
        let messages = [
            WallpaperDebugRequestMessage(
                extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                request: .accessAllAssets(.downloaded)
            ),
            WallpaperDebugRequestMessage(
                extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                request: .accessAllAssets(.all)
            ),
            WallpaperDebugRequestMessage(
                extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                request: .downloadAsset("asset-id")
            ),
            WallpaperDebugRequestMessage(
                extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                request: .downloadAssetState("asset-id")
            ),
            WallpaperDebugRequestMessage(
                extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                request: .removeAsset("asset-id")
            ),
        ]

        for message in messages {
            let data = try JSONEncoder().encode(message)
            let decoded = try JSONDecoder().decode(WallpaperDebugRequestMessage.self, from: data)
            let json = String(decoding: data, as: UTF8.self)

            #expect(decoded == message)
            #expect(!json.contains("rawValue"))
        }

        let responses: [WallpaperDebugResponse] = [
            .success,
            .error("message"),
            .allAssets(WallpaperAssetList(assets: [
                WallpaperAssetList.Asset(name: "Tahoe Day", id: "asset-id", isDownloaded: true),
            ])),
            .downloadState(WallpaperAssetDownloadState(assetID: "asset-id", progress: 1.0, isDownloaded: true)),
        ]

        for response in responses {
            let data = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(WallpaperDebugResponse.self, from: data)
            let json = String(decoding: data, as: UTF8.self)

            #expect(decoded == response)
            #expect(!json.contains("rawValue"))
        }
    }

    @Test("Wallpaper normal mirror preserves no-payload enum coding")
    func wallpaperNormalMirrorRoundTrips() throws {
        let message = AgentXPCMessage.diagnosticState

        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(AgentXPCMessage.self, from: data)

        #expect(decoded == message)
        #expect(String(decoding: data, as: UTF8.self).contains("diagnosticState"))
    }

    @Test("Wallpaper normal mirror includes recovered redraw support enums")
    func wallpaperNormalRedrawMirrorRoundTrips() throws {
        let message = AgentXPCMessage.ensureViewModelIsUpToDate([.desktop, .screenSaver], .wallpaperInstallation)

        let data = try JSONEncoder().encode(message)
        let json = String(decoding: data, as: UTF8.self)
        let decoded = try JSONDecoder().decode(AgentXPCMessage.self, from: data)

        #expect(ContentType.allCases == [.desktop, .screenSaver])
        #expect(ContentType.desktop.description == "desktop")
        #expect(ContentType.screenSaver.description == "screenSaver")
        #expect(decoded == message)
        #expect(json.contains("ensureViewModelIsUpToDate"))
        #expect(json.contains("desktop"))
        #expect(json.contains("screenSaver"))
        #expect(json.contains("wallpaperInstallation"))
    }
}
