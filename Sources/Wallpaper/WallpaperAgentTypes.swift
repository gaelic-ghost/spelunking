import Foundation

public enum ContentType: Codable, CaseIterable, CustomStringConvertible, Equatable, Sendable {
    case desktop
    case screenSaver

    public var description: String {
        switch self {
        case .desktop:
            "desktop"
        case .screenSaver:
            "screenSaver"
        }
    }
}

public enum ViewModelRefreshReason: Codable, Equatable, Sendable {
    case launch
    case navigation
    case wallpaperInstallation
}

public enum AgentXPCMessage: Codable, Equatable, Sendable {
    case ensureViewModelIsUpToDate([ContentType], ViewModelRefreshReason)
    case diagnosticState
    case snapshotAllSpaces
    case getCaches
}
