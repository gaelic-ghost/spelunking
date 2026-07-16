import Foundation

public struct WallpaperDebugRequestMessage: Codable, Equatable, Sendable {
    public var extensionIdentifier: String
    public var request: WallpaperDebugRequest

    public init(extensionIdentifier: String, request: WallpaperDebugRequest) {
        self.extensionIdentifier = extensionIdentifier
        self.request = request
    }
}

public enum WallpaperDebugRequest: Codable, Equatable, Sendable {
    case accessAllAssets(WallpaperDebugAssetType)
    case downloadAsset(String)
    case downloadAssetState(String)
    case removeAsset(String)
}

public enum WallpaperDebugAssetType: Codable, Equatable, Sendable {
    case all
    case downloaded
}

public enum WallpaperDebugResponse: Codable, Equatable, Sendable, CustomStringConvertible {
    case success
    case error(String)
    case allAssets(WallpaperAssetList)
    case downloadState(WallpaperAssetDownloadState)

    public var description: String {
        switch self {
        case .success:
            "success"
        case .error(let message):
            "error(\(message))"
        case .allAssets(let list):
            "allAssets(count: \(list.assets.count))"
        case .downloadState(let state):
            "downloadState(assetID: \(state.assetID), progress: \(state.progress), isDownloaded: \(state.isDownloaded))"
        }
    }
}

public struct WallpaperAssetList: Codable, Equatable, Sendable {
    public struct Asset: Codable, Equatable, Sendable {
        public var name: String
        public var id: String
        public var isDownloaded: Bool
    }

    public var assets: [Asset]
}

public struct WallpaperAssetDownloadState: Codable, Equatable, Sendable {
    public var assetID: String
    public var progress: Float
    public var isDownloaded: Bool
}
