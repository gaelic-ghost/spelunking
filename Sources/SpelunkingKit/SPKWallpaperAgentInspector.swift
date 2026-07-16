import Darwin
import Foundation
import XPC

public struct SPKWallpaperAgentProcess: Equatable, Sendable {
    public var pid: Int32
    public var parentPID: Int32?
    public var uid: Int?
    public var user: String?
    public var command: String
}

public struct SPKWallpaperMachService: Equatable, Sendable {
    public var name: String
    public var visibleInUserBootstrap: Bool
    public var launchctlLine: String?
}

public struct SPKWallpaperAgentSnapshot: Equatable, Sendable {
    public var uid: Int
    public var processes: [SPKWallpaperAgentProcess]
    public var machServices: [SPKWallpaperMachService]
    public var launchctlStatusLines: [String]
}

public struct SPKWallpaperXPCProbeResult: Equatable, Sendable {
    public var machService: String
    public var succeeded: Bool
    public var replyDescription: String?
    public var errorDescription: String?
}

public struct SPKWallpaperLogSnapshot: Equatable, Sendable {
    public var lastInterval: String
    public var predicate: String
    public var limit: Int
    public var lines: [String]
    public var truncated: Bool
}

public struct SPKWallpaperSignalResult: Equatable, Sendable {
    public var signal: Int32
    public var execute: Bool
    public var targetedPIDs: [Int32]
}

public struct SPKWallpaperRestartProbeResult: Equatable, Sendable {
    public var signal: Int32
    public var execute: Bool
    public var waitSeconds: Double
    public var before: SPKWallpaperAgentSnapshot
    public var targetedPIDs: [Int32]
    public var after: SPKWallpaperAgentSnapshot?
    public var respawnObserved: Bool?
}

public struct SPKWallpaperLaunchctlKillProbeResult: Equatable, Sendable {
    public var signal: Int32
    public var signalName: String
    public var execute: Bool
    public var waitSeconds: Double
    public var serviceTarget: String
    public var commandArguments: [String]
    public var before: SPKWallpaperAgentSnapshot
    public var after: SPKWallpaperAgentSnapshot?
    public var exitCode: Int32?
    public var standardOutput: String?
    public var standardError: String?
    public var respawnObserved: Bool?
}

public struct SPKSIPStatus: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case enabled
        case disabled
        case unknown
    }

    public var state: State
    public var rawStatus: String

    public var isEnabled: Bool {
        state == .enabled
    }
}

public enum SPKWallpaperAgentError: Error, CustomStringConvertible {
    case commandFailed(String)
    case noWallpaperAgentProcess
    case unsupportedSignalName(String)

    public var description: String {
        switch self {
        case .commandFailed(let message):
            "WallpaperAgent probe command failed: \(message)"
        case .noWallpaperAgentProcess:
            "No running WallpaperAgent process was found for the active user; the agent may not be loaded in this Aqua session."
        case .unsupportedSignalName(let name):
            "Unsupported WallpaperAgent signal name '\(name)'. Use TERM, HUP, INT, or KILL."
        }
    }
}

public struct SPKWallpaperAgentInspector: Sendable {
    public static let normalMachService = "com.apple.wallpaper"
    public static let debugMachService = "com.apple.wallpaper.debug.service"

    public static let knownMachServices = [
        "com.apple.wallpaper",
        "com.apple.wallpaper.debug.service",
        "com.apple.wallpaper.CacheDelete",
        "com.apple.usernotifications.delegate.com.apple.wallpaper.notifications.sonoma-first-run",
    ]

    private let runner: SPKProcessRunner

    public init(runner: SPKProcessRunner = SPKProcessRunner()) {
        self.runner = runner
    }

    public func snapshot() throws -> SPKWallpaperAgentSnapshot {
        let uid = try currentUID()
        let launchctlLines = try wallpaperLaunchctlLines(uid: uid)

        return SPKWallpaperAgentSnapshot(
            uid: uid,
            processes: try wallpaperProcesses(),
            machServices: Self.knownMachServices.map { service in
                let line = launchctlLines.first { $0.contains(service) }
                return SPKWallpaperMachService(
                    name: service,
                    visibleInUserBootstrap: line != nil,
                    launchctlLine: line?.trimmingCharacters(in: .whitespaces)
                )
            },
            launchctlStatusLines: launchctlLines
        )
    }

    public func probeEmptyXPCMessage(machService: String) -> SPKWallpaperXPCProbeResult {
        do {
            let session = try XPCSession(
                machService: machService,
                targetQueue: nil,
                options: .inactive,
                cancellationHandler: nil
            )
            try session.activate()
            let reply = try session.sendSync(message: XPCDictionary())
            session.cancel(reason: "WallpaperAgent empty probe complete")

            return SPKWallpaperXPCProbeResult(
                machService: machService,
                succeeded: true,
                replyDescription: String(describing: reply),
                errorDescription: nil
            )
        } catch {
            return SPKWallpaperXPCProbeResult(
                machService: machService,
                succeeded: false,
                replyDescription: nil,
                errorDescription: String(describing: error)
            )
        }
    }

    public func logSnapshot(lastInterval: String = "10m", limit: Int = 80) throws -> SPKWallpaperLogSnapshot {
        let predicate = """
        process == "WallpaperAgent" AND (eventMessage CONTAINS[c] "debug" OR eventMessage CONTAINS[c] "Failed to Decode" OR eventMessage CONTAINS[c] "Accepted XPC" OR eventMessage CONTAINS[c] "reload" OR eventMessage CONTAINS[c] "generation" OR eventMessage CONTAINS[c] "Runtime" OR eventMessage CONTAINS[c] "REBUILD" OR eventMessage CONTAINS[c] "snapshot" OR eventMessage CONTAINS[c] "invalidate")
        """
        let result = try runner.run(
            "/usr/bin/log",
            arguments: [
                "show",
                "--last", lastInterval,
                "--style", "compact",
                "--predicate", predicate,
            ]
        )

        guard result.succeeded else {
            throw SPKWallpaperAgentError.commandFailed("log show for WallpaperAgent returned \(result.exitCode): \(result.standardError)")
        }

        let allLines = result.standardOutput
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
        let boundedLimit = max(1, limit)
        let lines = Array(allLines.suffix(boundedLimit))

        return SPKWallpaperLogSnapshot(
            lastInterval: lastInterval,
            predicate: predicate,
            limit: boundedLimit,
            lines: lines,
            truncated: allLines.count > boundedLimit
        )
    }

    public func signalAgent(signalName: String, execute: Bool) throws -> SPKWallpaperSignalResult {
        let signal = try signalNumber(named: signalName)
        let pids = try wallpaperProcesses().map(\.pid)
        guard !pids.isEmpty else {
            throw SPKWallpaperAgentError.noWallpaperAgentProcess
        }

        if execute {
            for pid in pids {
                Darwin.kill(pid, signal)
            }
        }

        return SPKWallpaperSignalResult(signal: signal, execute: execute, targetedPIDs: pids)
    }

    public func restartProbe(signalName: String, execute: Bool, waitSeconds: Double = 5.0) throws -> SPKWallpaperRestartProbeResult {
        let signal = try signalNumber(named: signalName)
        let before = try snapshot()
        let targetedPIDs = before.processes.map(\.pid)
        guard !targetedPIDs.isEmpty else {
            throw SPKWallpaperAgentError.noWallpaperAgentProcess
        }

        guard execute else {
            return SPKWallpaperRestartProbeResult(
                signal: signal,
                execute: false,
                waitSeconds: waitSeconds,
                before: before,
                targetedPIDs: targetedPIDs,
                after: nil,
                respawnObserved: nil
            )
        }

        for pid in targetedPIDs {
            guard Darwin.kill(pid, signal) == 0 else {
                throw SPKWallpaperAgentError.commandFailed("kill(\(pid), \(signal)) failed with errno \(errno): \(String(cString: strerror(errno)))")
            }
        }

        let deadline = Date().addingTimeInterval(waitSeconds)
        var after = try snapshot()
        while Date() < deadline {
            let current = try snapshot()
            if restartWasObserved(beforePIDs: targetedPIDs, afterPIDs: current.processes.map(\.pid)) {
                after = current
                break
            }
            usleep(250_000)
            after = current
        }

        return SPKWallpaperRestartProbeResult(
            signal: signal,
            execute: true,
            waitSeconds: waitSeconds,
            before: before,
            targetedPIDs: targetedPIDs,
            after: after,
            respawnObserved: restartWasObserved(beforePIDs: targetedPIDs, afterPIDs: after.processes.map(\.pid))
        )
    }

    public func launchctlKillProbe(signalName: String, execute: Bool, waitSeconds: Double = 5.0) throws -> SPKWallpaperLaunchctlKillProbeResult {
        let signal = try signalNumber(named: signalName)
        let launchctlSignalName = try canonicalLaunchctlSignalName(named: signalName)
        let before = try snapshot()
        guard !before.processes.isEmpty else {
            throw SPKWallpaperAgentError.noWallpaperAgentProcess
        }

        let serviceTarget = "gui/\(before.uid)/com.apple.wallpaper.agent"
        let commandArguments = ["kill", launchctlSignalName, serviceTarget]

        guard execute else {
            return SPKWallpaperLaunchctlKillProbeResult(
                signal: signal,
                signalName: launchctlSignalName,
                execute: false,
                waitSeconds: waitSeconds,
                serviceTarget: serviceTarget,
                commandArguments: commandArguments,
                before: before,
                after: nil,
                exitCode: nil,
                standardOutput: nil,
                standardError: nil,
                respawnObserved: nil
            )
        }

        let launchctlResult = try runner.run("/bin/launchctl", arguments: commandArguments)
        let beforePIDs = before.processes.map(\.pid)
        let deadline = Date().addingTimeInterval(waitSeconds)
        var after = try snapshot()
        while Date() < deadline {
            let current = try snapshot()
            if restartWasObserved(beforePIDs: beforePIDs, afterPIDs: current.processes.map(\.pid)) {
                after = current
                break
            }
            usleep(250_000)
            after = current
        }

        return SPKWallpaperLaunchctlKillProbeResult(
            signal: signal,
            signalName: launchctlSignalName,
            execute: true,
            waitSeconds: waitSeconds,
            serviceTarget: serviceTarget,
            commandArguments: commandArguments,
            before: before,
            after: after,
            exitCode: launchctlResult.exitCode,
            standardOutput: launchctlResult.standardOutput,
            standardError: launchctlResult.standardError,
            respawnObserved: restartWasObserved(beforePIDs: beforePIDs, afterPIDs: after.processes.map(\.pid))
        )
    }

    public func sipStatus() throws -> SPKSIPStatus {
        let result = try runner.run("/usr/bin/csrutil", arguments: ["status"])
        let combinedOutput = [result.standardOutput, result.standardError]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard result.succeeded else {
            throw SPKWallpaperAgentError.commandFailed("csrutil status returned \(result.exitCode): \(combinedOutput)")
        }

        let lowercased = combinedOutput.lowercased()
        let state: SPKSIPStatus.State
        if lowercased.contains("status: enabled") {
            state = .enabled
        } else if lowercased.contains("status: disabled") {
            state = .disabled
        } else {
            state = .unknown
        }

        return SPKSIPStatus(state: state, rawStatus: combinedOutput)
    }

    private func currentUID() throws -> Int {
        let result = try runner.run("/usr/bin/id", arguments: ["-u"])
        guard result.succeeded, let uid = Int(result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw SPKWallpaperAgentError.commandFailed("id -u returned \(result.exitCode): \(result.standardError)")
        }
        return uid
    }

    private func wallpaperProcesses() throws -> [SPKWallpaperAgentProcess] {
        let pgrep = try runner.run("/usr/bin/pgrep", arguments: ["-x", "WallpaperAgent"])
        guard pgrep.succeeded || pgrep.exitCode == 1 else {
            throw SPKWallpaperAgentError.commandFailed("pgrep -x WallpaperAgent returned \(pgrep.exitCode): \(pgrep.standardError)")
        }

        let pids = pgrep.standardOutput
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        return try pids.compactMap { pid in
            let result = try runner.run("/bin/ps", arguments: ["-p", "\(pid)", "-o", "pid=,ppid=,uid=,user=,command="])
            guard result.succeeded else {
                throw SPKWallpaperAgentError.commandFailed("ps -p \(pid) returned \(result.exitCode): \(result.standardError)")
            }
            return result.standardOutput
                .split(separator: "\n", omittingEmptySubsequences: true)
                .compactMap(parseWallpaperProcessLine)
                .first
        }
    }

    private func wallpaperLaunchctlLines(uid: Int) throws -> [String] {
        let result = try runner.run("/bin/launchctl", arguments: ["print", "gui/\(uid)/com.apple.wallpaper.agent"])
        guard result.succeeded else {
            throw SPKWallpaperAgentError.commandFailed("launchctl print gui/\(uid)/com.apple.wallpaper.agent returned \(result.exitCode): \(result.standardError)")
        }

        return result.standardOutput
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { $0.localizedCaseInsensitiveContains("wallpaper") }
    }

    private func parseWallpaperProcessLine(_ line: Substring) -> SPKWallpaperAgentProcess? {
        guard line.contains("WallpaperAgent") else {
            return nil
        }

        let fields = line.split(maxSplits: 4, whereSeparator: \.isWhitespace)
        guard fields.count >= 5, let pid = Int32(fields[0]) else {
            return nil
        }

        return SPKWallpaperAgentProcess(
            pid: pid,
            parentPID: Int32(fields[1]),
            uid: Int(fields[2]),
            user: String(fields[3]),
            command: String(fields[4])
        )
    }

    private func restartWasObserved(beforePIDs: [Int32], afterPIDs: [Int32]) -> Bool {
        guard !beforePIDs.isEmpty, !afterPIDs.isEmpty else {
            return false
        }

        return afterPIDs.contains { !beforePIDs.contains($0) }
    }

    private func signalNumber(named name: String) throws -> Int32 {
        switch name.uppercased() {
        case "TERM", "SIGTERM":
            return SIGTERM
        case "HUP", "SIGHUP":
            return SIGHUP
        case "INT", "SIGINT":
            return SIGINT
        case "KILL", "SIGKILL":
            return SIGKILL
        default:
            throw SPKWallpaperAgentError.unsupportedSignalName(name)
        }
    }

    private func canonicalLaunchctlSignalName(named name: String) throws -> String {
        switch try signalNumber(named: name) {
        case SIGTERM:
            return "SIGTERM"
        case SIGHUP:
            return "SIGHUP"
        case SIGINT:
            return "SIGINT"
        case SIGKILL:
            return "SIGKILL"
        default:
            throw SPKWallpaperAgentError.unsupportedSignalName(name)
        }
    }
}
