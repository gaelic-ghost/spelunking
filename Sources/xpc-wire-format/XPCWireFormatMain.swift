import Dispatch
import Foundation
import XPC

@_silgen_name("xpc_dictionary_get_data")
private func xpc_dictionary_get_data(
    _ dictionary: xpc_object_t,
    _ key: UnsafePointer<CChar>,
    _ length: UnsafeMutablePointer<Int>
) -> UnsafeRawPointer?

enum SPKDebugAssetType: String, Codable, Sendable {
    case all
    case downloaded
}

enum SPKDebugRequest: Codable, Sendable {
    case accessAllAssets(SPKDebugAssetType)
    case downloadAsset(String)
    case downloadAssetState(String)
    case removeAsset(String)
}

struct SPKDebugRequestMessage: Codable, Sendable {
    let extensionIdentifier: String
    let request: SPKDebugRequest
}

enum SPKDebugResponse: Codable, Sendable {
    case error(String)
    case allAssets(SPKWallpaperAssetList)
    case downloadState(SPKWallpaperAssetDownloadState)
    case success
}

struct SPKWallpaperAssetList: Codable, Sendable {
    let assets: [SPKWallpaperAsset]
}

struct SPKWallpaperAsset: Codable, Sendable {
    let name: String
    let id: String
    let isDownloaded: Bool
}

struct SPKWallpaperAssetDownloadState: Codable, Sendable {
    let assetID: String
    let progress: Double
    let isDownloaded: Bool
}

@main
struct XPCWireFormatMain {
    static func main() throws {
        if CommandLine.arguments.contains("--wallpaper-debug") {
            try inspectWallpaperDebugService()
            return
        }

        let received = DispatchSemaphore(value: 0)
        let acceptedSessions = SPKAcceptedSessions()
        let listener = XPCListener(options: .inactive) { incomingRequest in
            let (decision, session) = incomingRequest.accept(
                incomingMessageHandler: { (message: XPCDictionary) -> XPCDictionary? in
                    dump(message, label: "Typed Swift-XPC envelope")
                    received.signal()
                    return XPCDictionary()
                }
            )
            try? session.activate()
            acceptedSessions.append(session)
            return decision
        }
        try listener.activate()

        let session = try XPCSession(endpoint: listener.endpoint, options: .inactive)
        try session.activate()
        try session.send(
            SPKDebugRequestMessage(
                extensionIdentifier: "com.example.wallpaper",
                request: .accessAllAssets(.all)
            )
        )

        guard received.wait(timeout: .now() + 5) == .success else {
            throw SPKWireFormatError.timedOut
        }
        session.cancel(reason: "Completed local envelope inspection.")
        listener.cancel()
    }

    private static func inspectWallpaperDebugService() throws {
        let session = try XPCSession(
            machService: "com.apple.wallpaper.debug.service",
            options: .inactive
        )
        try session.activate()

        let request = SPKDebugRequestMessage(
            extensionIdentifier: "com.apple.wallpaper.extension.aerials",
            request: .accessAllAssets(.all)
        )
        let reply: XPCReceivedMessage = try session.sendSync(request)
        print("Wallpaper Debug XPC accepted accessAllAssets(.all): expectsReply=\(reply.expectsReply), isSync=\(reply.isSync)")
        do {
            let response = try reply.decode(as: SPKDebugResponse.self)
            dump(response)
        } catch {
            print("Wallpaper Debug XPC returned a reply that the current response mirror could not decode: \(error)")
        }
        session.cancel(reason: "Completed read-only Wallpaper Debug XPC inspection.")
    }

    private static func dump(_ response: SPKDebugResponse) {
        switch response {
        case .allAssets(let assets):
            print("Decoded allAssets response with \(assets.assets.count) asset records.")
        case .downloadState(let state):
            print("Decoded downloadState response for \(state.assetID): \(state.progress), downloaded=\(state.isDownloaded).")
        case .error(let message):
            print("Decoded error response: \(message)")
        case .success:
            print("Decoded success response.")
        }
    }

    private static func dump(_ dictionary: XPCDictionary, label: String) {
        print(label)
        dictionary.forEach { key, value in
            print("- \(key): \(String(describing: value))")
        }
        dictionary.withUnsafeUnderlyingDictionary { rawDictionary in
            "_CodableBody".withCString { key in
                var length = 0
                guard let body = xpc_dictionary_get_data(rawDictionary, key, &length) else {
                    return
                }
                let bytes = UnsafeRawBufferPointer(start: body, count: length)
                print("- _CodableBody hex: \(bytes.map { String(format: "%02x", $0) }.joined())")
            }
        }
    }
}

final class SPKAcceptedSessions: @unchecked Sendable {
    private var sessions: [XPCSession] = []

    func append(_ session: XPCSession) {
        sessions.append(session)
    }
}

enum SPKWireFormatError: Error {
    case timedOut
}
