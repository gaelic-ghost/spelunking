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
        case "log-snapshot":
            let lastInterval = optionValue("--last", in: arguments) ?? "10m"
            let limit = optionValue("--limit", in: arguments).flatMap(Int.init) ?? 80
            printLogSnapshot(try inspector.logSnapshot(lastInterval: lastInterval, limit: limit))
        case "xpc-ping-empty":
            let service = arguments.dropFirst().first ?? SPKWallpaperAgentInspector.normalMachService
            printXPCProbe(inspector.probeEmptyXPCMessage(machService: service))
        case "normal-xpc-probe":
            let request = try normalXPCProbeRequest(arguments: arguments)
            printNormalXPCProbe(inspector.probeNormalXPCMessage(request))
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
        case "restart-probe-plan":
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printRestartProbeResult(try inspector.restartProbe(signalName: signalName, execute: false))
        case "restart-probe":
            guard arguments.contains("--execute") else {
                throw CLIError.missingExecuteFlag("Refusing to restart-probe WallpaperAgent without --execute. Use restart-probe-plan for a dry run.")
            }
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printRestartProbeResult(try inspector.restartProbe(signalName: signalName, execute: true))
        case "launchctl-kill-plan":
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printLaunchctlKillProbeResult(try inspector.launchctlKillProbe(signalName: signalName, execute: false))
        case "launchctl-kill":
            guard arguments.contains("--execute") else {
                throw CLIError.missingExecuteFlag("Refusing to run launchctl kill for WallpaperAgent without --execute. Use launchctl-kill-plan for a dry run.")
            }
            let signalName = optionValue("--signal", in: arguments) ?? "TERM"
            printLaunchctlKillProbeResult(try inspector.launchctlKillProbe(signalName: signalName, execute: true))
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
        case "redraw-probe-plan":
            #if canImport(AppKit)
            printRedrawProbeResult(try SPKWallpaperStaticRedraw().redrawProbe(execute: false))
            #else
            throw CLIError.unsupportedPlatform("Static desktop redraw probe requires AppKit.")
            #endif
        case "redraw-probe":
            guard arguments.contains("--execute") else {
                throw CLIError.missingExecuteFlag("Refusing to redraw-probe desktop images without --execute. Use redraw-probe-plan for a dry run.")
            }
            #if canImport(AppKit)
            printRedrawProbeResult(try SPKWallpaperStaticRedraw().redrawProbe(execute: true))
            #else
            throw CLIError.unsupportedPlatform("Static desktop redraw probe requires AppKit.")
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
              spelunk wallpaper-agent log-snapshot [--last 10m] [--limit 80]
              spelunk wallpaper-agent xpc-ping-empty [mach-service]
              spelunk wallpaper-agent normal-xpc-probe [--request diagnostic-state|snapshot-all-spaces|get-caches]
              spelunk wallpaper-agent debug-xpc-probe [--extension identifier] [--request access-downloaded|access-all|download-state] [--asset-id id]
              spelunk wallpaper-agent sip-validation-report
              spelunk wallpaper-agent signal-plan [--signal TERM]
              spelunk wallpaper-agent signal --execute [--signal TERM]
              spelunk wallpaper-agent restart-probe-plan [--signal TERM]
              spelunk wallpaper-agent restart-probe --execute [--signal TERM]
              spelunk wallpaper-agent launchctl-kill-plan [--signal TERM]
              spelunk wallpaper-agent launchctl-kill --execute [--signal TERM]
              spelunk wallpaper-agent redraw-static-plan
              spelunk wallpaper-agent redraw-static --execute
              spelunk wallpaper-agent redraw-probe-plan
              spelunk wallpaper-agent redraw-probe --execute
            """
        )
    }

    private static func printWallpaperUsage() {
        print(
            """
            WallpaperAgent commands:
              inventory
              log-snapshot [--last 10m] [--limit 80]
              xpc-ping-empty [mach-service]
              normal-xpc-probe [--request diagnostic-state|snapshot-all-spaces|get-caches]
              debug-xpc-probe [--extension identifier] [--request access-downloaded|access-all|download-state] [--asset-id id]
              sip-validation-report
              signal-plan [--signal TERM]
              signal --execute [--signal TERM]
              restart-probe-plan [--signal TERM]
              restart-probe --execute [--signal TERM]
              launchctl-kill-plan [--signal TERM]
              launchctl-kill --execute [--signal TERM]
              redraw-static-plan
              redraw-static --execute
              redraw-probe-plan
              redraw-probe --execute
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

    private static func printLogSnapshot(_ snapshot: SPKWallpaperLogSnapshot) {
        print("lastInterval: \(snapshot.lastInterval)")
        print("limit: \(snapshot.limit)")
        print("truncated: \(snapshot.truncated)")
        print("predicate: \(snapshot.predicate)")
        print("lines:")
        if snapshot.lines.isEmpty {
            print("  <none>")
        } else {
            for line in snapshot.lines {
                print("  \(line)")
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

    private static func printNormalXPCProbe(_ result: SPKWallpaperNormalXPCProbeResult) {
        print("machService: \(result.machService)")
        print("request: \(result.requestDescription)")
        print("succeeded: \(result.succeeded)")
        if let decodedDataByteCount = result.decodedDataByteCount {
            print("decodedDataByteCount: \(decodedDataByteCount)")
        }
        if let replyDescription = result.rawReplyDescription {
            print("rawReply: \(replyDescription)")
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

    private static func printRestartProbeResult(_ result: SPKWallpaperRestartProbeResult) {
        print("execute: \(result.execute)")
        print("signal: \(result.signal)")
        print("waitSeconds: \(result.waitSeconds)")
        print("targetedPIDs: \(result.targetedPIDs.map(String.init).joined(separator: ", "))")
        print("beforePIDs: \(result.before.processes.map(\.pid).map(String.init).joined(separator: ", "))")
        if let after = result.after {
            print("afterPIDs: \(after.processes.map(\.pid).map(String.init).joined(separator: ", "))")
        } else {
            print("afterPIDs: <not collected>")
        }
        if let respawnObserved = result.respawnObserved {
            print("respawnObserved: \(respawnObserved)")
        } else {
            print("respawnObserved: <not executed>")
        }
    }

    private static func printLaunchctlKillProbeResult(_ result: SPKWallpaperLaunchctlKillProbeResult) {
        print("execute: \(result.execute)")
        print("signal: \(result.signal)")
        print("signalName: \(result.signalName)")
        print("waitSeconds: \(result.waitSeconds)")
        print("serviceTarget: \(result.serviceTarget)")
        print("command: /bin/launchctl \(result.commandArguments.joined(separator: " "))")
        print("beforePIDs: \(result.before.processes.map(\.pid).map(String.init).joined(separator: ", "))")
        if let after = result.after {
            print("afterPIDs: \(after.processes.map(\.pid).map(String.init).joined(separator: ", "))")
        } else {
            print("afterPIDs: <not collected>")
        }
        if let exitCode = result.exitCode {
            print("exitCode: \(exitCode)")
        } else {
            print("exitCode: <not executed>")
        }
        if let standardOutput = result.standardOutput, !standardOutput.isEmpty {
            print("stdout: \(standardOutput.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if let standardError = result.standardError, !standardError.isEmpty {
            print("stderr: \(standardError.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if let respawnObserved = result.respawnObserved {
            print("respawnObserved: \(respawnObserved)")
        } else {
            print("respawnObserved: <not executed>")
        }
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

    private static func printRedrawProbeResult(_ result: SPKDesktopImageRedrawProbeResult) {
        print("execute: \(result.execute)")
        for entry in result.entries {
            print("screen: \(entry.screenName)")
            print("  beforeImageURL: \(entry.beforeImageURL ?? "<none>")")
            print("  afterImageURL: \(entry.afterImageURL ?? "<not collected>")")
            print("  beforeOptionKeys: \(entry.beforeOptionKeys.joined(separator: ", "))")
            print("  afterOptionKeys: \(entry.afterOptionKeys?.joined(separator: ", ") ?? "<not collected>")")
            print("  reapplied: \(entry.reapplied)")
            if let preservedImageURL = entry.preservedImageURL {
                print("  preservedImageURL: \(preservedImageURL)")
            } else {
                print("  preservedImageURL: <not executed>")
            }
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
        print("redrawProbePlan:")
        #if canImport(AppKit)
        printRedrawProbeResult(try SPKWallpaperStaticRedraw().redrawProbe(execute: false))
        #else
        print("error: Static desktop redraw probe planning requires AppKit.")
        #endif

        print("")
        print("signalPlan:")
        printSignalResult(try inspector.signalAgent(signalName: "TERM", execute: false))

        print("")
        print("restartProbePlan:")
        printRestartProbeResult(try inspector.restartProbe(signalName: "TERM", execute: false))

        print("")
        print("launchctlKillPlan:")
        printLaunchctlKillProbeResult(try inspector.launchctlKillProbe(signalName: "TERM", execute: false))

        print("")
        print("logSnapshot:")
        printLogSnapshot(try inspector.logSnapshot(lastInterval: "10m", limit: 40))

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

    private static func normalXPCProbeRequest(arguments: [String]) throws -> SPKWallpaperNormalXPCProbeRequest {
        let requestName = optionValue("--request", in: arguments) ?? "diagnostic-state"

        let request: SPKWallpaperNormalXPCProbeRequest.NormalRequest
        switch requestName {
        case "diagnostic-state":
            request = .diagnosticState
        case "snapshot-all-spaces":
            request = .snapshotAllSpaces
        case "get-caches":
            request = .getCaches
        default:
            throw CLIError.invalidArgument("Unsupported normal-xpc-probe request '\(requestName)'. Use diagnostic-state, snapshot-all-spaces, or get-caches.")
        }

        return SPKWallpaperNormalXPCProbeRequest(request: request)
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
