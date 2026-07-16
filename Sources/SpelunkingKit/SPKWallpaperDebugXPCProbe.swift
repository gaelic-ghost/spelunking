import Foundation
import WallpaperTypes
import XPC

public struct SPKWallpaperDebugXPCProbeRequest: Equatable, Sendable {
    public enum DebugRequest: Equatable, Sendable {
        case accessDownloadedAssets
        case accessAllAssets
        case downloadAsset(String)
        case downloadAssetState(String)
        case removeAsset(String)
    }

    public var extensionIdentifier: String
    public var request: DebugRequest

    public init(extensionIdentifier: String, request: DebugRequest) {
        self.extensionIdentifier = extensionIdentifier
        self.request = request
    }
}

public struct SPKWallpaperDebugXPCProbeResult: Equatable, Sendable {
    public var machService: String
    public var extensionIdentifier: String
    public var requestDescription: String
    public var succeeded: Bool
    public var decodedResponse: WallpaperDebugResponse?
    public var rawReplyDescription: String?
    public var errorDescription: String?
}

extension SPKWallpaperAgentInspector {
    public func probeDebugXPCMessage(_ request: SPKWallpaperDebugXPCProbeRequest) -> SPKWallpaperDebugXPCProbeResult {
        let message = WallpaperDebugRequestMessage(
            extensionIdentifier: request.extensionIdentifier,
            request: request.request.wallpaperDebugRequest
        )

        do {
            let session = try XPCSession(
                machService: Self.debugMachService,
                targetQueue: nil,
                options: .inactive,
                cancellationHandler: nil
            )
            try session.activate()
            let reply = try session.sendSync(message)
            session.cancel(reason: "WallpaperAgent debug XPC probe complete")

            do {
                let decoded = try reply.decode(as: WallpaperDebugResponse.self)
                return SPKWallpaperDebugXPCProbeResult(
                    machService: Self.debugMachService,
                    extensionIdentifier: request.extensionIdentifier,
                    requestDescription: request.request.description,
                    succeeded: true,
                    decodedResponse: decoded,
                    rawReplyDescription: String(describing: reply),
                    errorDescription: nil
                )
            } catch {
                return SPKWallpaperDebugXPCProbeResult(
                    machService: Self.debugMachService,
                    extensionIdentifier: request.extensionIdentifier,
                    requestDescription: request.request.description,
                    succeeded: false,
                    decodedResponse: nil,
                    rawReplyDescription: String(describing: reply),
                    errorDescription: "Debug XPC replied, but the response could not be decoded as WallpaperTypes.WallpaperDebugResponse: \(error)"
                )
            }
        } catch {
            return SPKWallpaperDebugXPCProbeResult(
                machService: Self.debugMachService,
                extensionIdentifier: request.extensionIdentifier,
                requestDescription: request.request.description,
                succeeded: false,
                decodedResponse: nil,
                rawReplyDescription: nil,
                errorDescription: String(describing: error)
            )
        }
    }
}

extension SPKWallpaperDebugXPCProbeRequest.DebugRequest: CustomStringConvertible {
    public var description: String {
        switch self {
        case .accessDownloadedAssets:
            "accessAllAssets(downloaded)"
        case .accessAllAssets:
            "accessAllAssets(all)"
        case .downloadAsset(let assetID):
            "downloadAsset(\(assetID))"
        case .downloadAssetState(let assetID):
            "downloadAssetState(\(assetID))"
        case .removeAsset(let assetID):
            "removeAsset(\(assetID))"
        }
    }

    public var isMutating: Bool {
        switch self {
        case .accessDownloadedAssets, .accessAllAssets, .downloadAssetState:
            false
        case .downloadAsset, .removeAsset:
            true
        }
    }

    fileprivate var wallpaperDebugRequest: WallpaperDebugRequest {
        switch self {
        case .accessDownloadedAssets:
            .accessAllAssets(.downloaded)
        case .accessAllAssets:
            .accessAllAssets(.all)
        case .downloadAsset(let assetID):
            .downloadAsset(assetID)
        case .downloadAssetState(let assetID):
            .downloadAssetState(assetID)
        case .removeAsset(let assetID):
            .removeAsset(assetID)
        }
    }
}
