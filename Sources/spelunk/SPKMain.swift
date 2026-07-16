import Darwin
import Foundation
import SpelunkingKit

@main
struct SPKMain {
    @MainActor
    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("spelunk: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }

    @MainActor
    private static func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            printTargets()
            return
        }

        switch command {
        case "targets":
            printTargets()
        case "wallpaper-agent":
            try runWallpaperAgent(arguments: Array(arguments.dropFirst()))
        default:
            printUsage()
            Foundation.exit(64)
        }
    }

    @MainActor
    private static func runWallpaperAgent(arguments: [String]) throws {
        let subcommand = arguments.first ?? "inventory"
        let inspector = SPKWallpaperAgentInspector()

        switch subcommand {
        case "inventory":
            printSnapshot(try inspector.snapshot())
        case "xpc-ping-empty":
            let service = arguments.dropFirst().first ?? SPKWallpaperAgentInspector.normalMachService
            printXPCProbe(inspector.probeEmptyXPCMessage(machService: service))
        case "debug-xpc-probe":
            let request = try debugXPCProbeRequest(arguments: arguments)
            printDebugXPCProbe(inspector.probeDebugXPCMessage(request))
        case "sip-validation-report":
            try printSIPValidationReport(inspector: inspector)
        case "signal-plan":
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printSignalResult(try inspector.signalAgent(signalName: signalName, execute: false))
        case "signal":
            guard arguments.contains("--execute") else {
                throw CLIError.missingExecuteFlag("Refusing to signal WallpaperAgent without --execute. Use signal-plan for a dry run.")
            }
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printSignalResult(try inspector.signalAgent(signalName: signalName, execute: true))
        case "redraw-static-plan":
            #if canImport(AppKit)
            printRedrawResult(try SPKWallpaperStaticRedraw().reapplyCurrentDesktopImages(execute: false))
            #else
            throw CLIError.unsupportedPlatform("Static desktop redraw requires AppKit.")
            #endif
        case "redraw-static":
            guard arguments.contains("--execute") else {
                throw CLIError.missingExecuteFlag("Refusing to reapply desktop images without --execute. Use redraw-static-plan for a dry run.")
            }
            #if canImport(AppKit)
            printRedrawResult(try SPKWallpaperStaticRedraw().reapplyCurrentDesktopImages(execute: true))
            #else
            throw CLIError.unsupportedPlatform("Static desktop redraw requires AppKit.")
            #endif
        default:
            printWallpaperUsage()
            Foundation.exit(64)
        }
    }

    private static func printTargets() {
        for target in [SPKResearchTarget.mediaRemote, .wallpaperAgent] {
            print(target.name)
            print("  \(target.summary)")
            print("  Docs: \(target.documentationPath)")
            print("  Research: \(target.researchPath)")
        }
    }

    private static func printUsage() {
        print(
            """
            Usage:
              spelunk targets
              spelunk wallpaper-agent inventory
              spelunk wallpaper-agent xpc-ping-empty [mach-service]
              spelunk wallpaper-agent debug-xpc-probe [--extension identifier] [--request access-downloaded|access-all|download-state] [--asset-id id]
              spelunk wallpaper-agent sip-validation-report
              spelunk wallpaper-agent signal-plan [--signal TERM]
              spelunk wallpaper-agent signal --execute [--signal TERM]
              spelunk wallpaper-agent redraw-static-plan
              spelunk wallpaper-agent redraw-static --execute
            """
        )
    }

    private static func printWallpaperUsage() {
        print(
            """
            WallpaperAgent commands:
              inventory
              xpc-ping-empty [mach-service]
              debug-xpc-probe [--extension identifier] [--request access-downloaded|access-all|download-state] [--asset-id id]
              sip-validation-report
              signal-plan [--signal TERM]
              signal --execute [--signal TERM]
              redraw-static-plan
              redraw-static --execute
            """
        )
    }

    private static func printSnapshot(_ snapshot: SPKWallpaperAgentSnapshot) {
        print("WallpaperAgent snapshot")
        print("uid: \(snapshot.uid)")
        print("processes:")
        for process in snapshot.processes {
            print("  pid=\(process.pid) ppid=\(process.parentPID.map(String.init) ?? "?") uid=\(process.uid.map(String.init) ?? "?") user=\(process.user ?? "?")")
            print("    \(process.command)")
        }
        print("mach services:")
        for service in snapshot.machServices {
            print("  \(service.visibleInUserBootstrap ? "visible" : "missing") \(service.name)")
            if let line = service.launchctlLine {
                print("    \(line)")
            }
        }
    }

    private static func printXPCProbe(_ result: SPKWallpaperXPCProbeResult) {
        print("machService: \(result.machService)")
        print("succeeded: \(result.succeeded)")
        if let replyDescription = result.replyDescription {
            print("reply: \(replyDescription)")
        }
        if let errorDescription = result.errorDescription {
            print("error: \(errorDescription)")
        }
    }

    private static func printSignalResult(_ result: SPKWallpaperSignalResult) {
        print("execute: \(result.execute)")
        print("signal: \(result.signal)")
        print("targetedPIDs: \(result.targetedPIDs.map(String.init).joined(separator: ", "))")
    }

    private static func printRedrawResult(_ result: SPKDesktopImageRedrawResult) {
        print("execute: \(result.execute)")
        for entry in result.entries {
            print("screen: \(entry.screenName)")
            print("  imageURL: \(entry.imageURL ?? "<none>")")
            print("  optionKeys: \(entry.optionKeys.joined(separator: ", "))")
            print("  reapplied: \(entry.reapplied)")
        }
    }

    @MainActor
    private static func printSIPValidationReport(inspector: SPKWallpaperAgentInspector) throws {
        let sipStatus = try inspector.sipStatus()
        print("SIP validation report")
        print("sipStatus: \(sipStatus.rawStatus)")
        print("sipEnabled: \(sipStatus.isEnabled)")

        print("")
        print("inventory:")
        printSnapshot(try inspector.snapshot())

        print("")
        print("debugXPCReadProbe:")
        printDebugXPCProbe(
            inspector.probeDebugXPCMessage(
                SPKWallpaperDebugXPCProbeRequest(
                    extensionIdentifier: "com.apple.wallpaper.extension.aerials",
                    request: .accessDownloadedAssets
                )
            )
        )

        print("")
        print("staticRedrawPlan:")
        #if canImport(AppKit)
        printRedrawResult(try SPKWallpaperStaticRedraw().reapplyCurrentDesktopImages(execute: false))
        #else
        print("error: Static desktop redraw planning requires AppKit.")
        #endif

        print("")
        print("signalPlan:")
        printSignalResult(try inspector.signalAgent(signalName: "TERM", execute: false))

        print("")
        if sipStatus.isEnabled {
            print("sipProofClaim: eligible if the debug XPC probe succeeded and the non-mutating plans found the expected userland surfaces.")
        } else {
            print("sipProofClaim: not eligible because SIP is not enabled for this boot.")
        }
    }

    private static func printDebugXPCProbe(_ result: SPKWallpaperDebugXPCProbeResult) {
        print("machService: \(result.machService)")
        print("extensionIdentifier: \(result.extensionIdentifier)")
        print("request: \(result.requestDescription)")
        print("succeeded: \(result.succeeded)")
        if let response = result.decodedResponse {
            print("decodedResponse: \(response)")
            if case .allAssets(let list) = response {
                print("assets:")
                for asset in list.assets {
                    print("  id=\(asset.id) downloaded=\(asset.isDownloaded) name=\(asset.name)")
                }
            }
        }
        if let replyDescription = result.rawReplyDescription {
            print("rawReply: \(replyDescription)")
        }
        if let errorDescription = result.errorDescription {
            print("error: \(errorDescription)")
        }
    }

    private static func debugXPCProbeRequest(arguments: [String]) throws -> SPKWallpaperDebugXPCProbeRequest {
        let extensionIdentifier = optionValue("--extension", in: arguments) ?? "com.apple.wallpaper.extension.aerials"
        let requestName = optionValue("--request", in: arguments) ?? "access-downloaded"

        let request: SPKWallpaperDebugXPCProbeRequest.DebugRequest
        switch requestName {
        case "access-downloaded":
            request = .accessDownloadedAssets
        case "access-all":
            request = .accessAllAssets
        case "download-state":
            guard let assetID = optionValue("--asset-id", in: arguments), !assetID.isEmpty else {
                throw CLIError.invalidArgument("debug-xpc-probe --request download-state requires --asset-id.")
            }
            request = .downloadAssetState(assetID)
        default:
            throw CLIError.invalidArgument("Unsupported debug-xpc-probe request '\(requestName)'. Use access-downloaded, access-all, or download-state.")
        }

        return SPKWallpaperDebugXPCProbeRequest(extensionIdentifier: extensionIdentifier, request: request)
    }

    private static func optionValue(_ option: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: option) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return arguments[valueIndex]
    }
}

private enum CLIError: Error, CustomStringConvertible {
    case missingExecuteFlag(String)
    case invalidArgument(String)
    case unsupportedPlatform(String)

    var description: String {
        switch self {
        case .missingExecuteFlag(let message), .invalidArgument(let message), .unsupportedPlatform(let message):
            message
        }
    }
}
