public struct SPKResearchTarget: Equatable, Sendable {
    public var name: String
    public var summary: String
    public var documentationPath: String
    public var researchPath: String

    public init(
        name: String,
        summary: String,
        documentationPath: String,
        researchPath: String
    ) {
        self.name = name
        self.summary = summary
        self.documentationPath = documentationPath
        self.researchPath = researchPath
    }
}

public extension SPKResearchTarget {
    static let mediaRemote = SPKResearchTarget(
        name: "MediaRemote.framework",
        summary: "Private media-control and now-playing framework research across macOS 26.5 and the macOS 27 beta SDK.",
        documentationPath: "docs/frameworks/MediaRemote",
        researchPath: "research/MediaRemote"
    )

    static let wallpaperAgent = SPKResearchTarget(
        name: "WallpaperAgent",
        summary: "WallpaperAgent, Wallpaper Debug XPC, and SIP-enabled userland restart or redraw research.",
        documentationPath: "docs/frameworks/WallpaperAgent",
        researchPath: "research/WallpaperAgent"
    )
}
