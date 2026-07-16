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
    static let messages = SPKResearchTarget(
        name: "Messages.app and IMCore",
        summary: "Local-only Messages, iMessage, chat.db, private framework, agent, hook, and supported API research.",
        documentationPath: "docs/frameworks/Messages",
        researchPath: "research/Messages"
    )

    static let phone = SPKResearchTarget(
        name: "Phone.app and telephony services",
        summary: "Local-only Phone, call history, call services, private framework, agent, hook, and supported API research.",
        documentationPath: "docs/frameworks/Phone",
        researchPath: "research/Phone"
    )

    static let mediaRemote = SPKResearchTarget(
        name: "MediaRemote.framework",
        summary: "Private media-control and now-playing framework research across macOS 26.5 and the macOS 27 beta SDK.",
        documentationPath: "docs/frameworks/MediaRemote",
        researchPath: "research/MediaRemote"
    )
}
