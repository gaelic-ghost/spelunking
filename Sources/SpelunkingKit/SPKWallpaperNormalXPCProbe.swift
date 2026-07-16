import Foundation
import Wallpaper
import XPC

public struct SPKWallpaperNormalXPCProbeRequest: Equatable, Sendable {
    public enum NormalRequest: Equatable, Sendable {
        case diagnosticState
        case snapshotAllSpaces
        case getCaches
    }

    public var request: NormalRequest

    public init(request: NormalRequest) {
        self.request = request
    }
}

public struct SPKWallpaperNormalXPCProbeResult: Equatable, Sendable {
    public var machService: String
    public var requestDescription: String
    public var succeeded: Bool
    public var decodedDataByteCount: Int?
    public var rawReplyDescription: String?
    public var errorDescription: String?
}

extension SPKWallpaperAgentInspector {
    public func probeNormalXPCMessage(_ request: SPKWallpaperNormalXPCProbeRequest) -> SPKWallpaperNormalXPCProbeResult {
        do {
            let session = try XPCSession(
                machService: Self.normalMachService,
                targetQueue: nil,
                options: .inactive,
                cancellationHandler: nil
            )
            try session.activate()
            let reply = try session.sendSync(request.request.agentXPCMessage)
            session.cancel(reason: "WallpaperAgent normal XPC probe complete")

            switch request.request {
            case .diagnosticState:
                do {
                    let data = try reply.decode(as: Data.self)
                    return SPKWallpaperNormalXPCProbeResult(
                        machService: Self.normalMachService,
                        requestDescription: request.request.description,
                        succeeded: true,
                        decodedDataByteCount: data.count,
                        rawReplyDescription: String(describing: reply),
                        errorDescription: nil
                    )
                } catch {
                    return SPKWallpaperNormalXPCProbeResult(
                        machService: Self.normalMachService,
                        requestDescription: request.request.description,
                        succeeded: false,
                        decodedDataByteCount: nil,
                        rawReplyDescription: String(describing: reply),
                        errorDescription: "Normal XPC replied, but diagnosticState could not be decoded as Data: \(error)"
                    )
                }
            case .snapshotAllSpaces, .getCaches:
                return SPKWallpaperNormalXPCProbeResult(
                    machService: Self.normalMachService,
                    requestDescription: request.request.description,
                    succeeded: true,
                    decodedDataByteCount: nil,
                    rawReplyDescription: String(describing: reply),
                    errorDescription: nil
                )
            }
        } catch {
            return SPKWallpaperNormalXPCProbeResult(
                machService: Self.normalMachService,
                requestDescription: request.request.description,
                succeeded: false,
                decodedDataByteCount: nil,
                rawReplyDescription: nil,
                errorDescription: String(describing: error)
            )
        }
    }
}

extension SPKWallpaperNormalXPCProbeRequest.NormalRequest: CustomStringConvertible {
    public var description: String {
        switch self {
        case .diagnosticState:
            "diagnosticState"
        case .snapshotAllSpaces:
            "snapshotAllSpaces"
        case .getCaches:
            "getCaches"
        }
    }

    fileprivate var agentXPCMessage: AgentXPCMessage {
        switch self {
        case .diagnosticState:
            .diagnosticState
        case .snapshotAllSpaces:
            .snapshotAllSpaces
        case .getCaches:
            .getCaches
        }
    }
}
