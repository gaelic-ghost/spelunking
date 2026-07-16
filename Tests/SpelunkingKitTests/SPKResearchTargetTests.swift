import SpelunkingKit
import Testing

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
}
