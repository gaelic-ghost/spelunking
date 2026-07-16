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
    case unsupportedPlatform(String)

    var description: String {
        switch self {
        case .missingExecuteFlag(let message), .unsupportedPlatform(let message):
            message
        }
    }
}
