import Foundation

public struct SPKCommandResult: Equatable, Sendable {
    public var executablePath: String
    public var arguments: [String]
    public var exitCode: Int32
    public var standardOutput: String
    public var standardError: String

    public var succeeded: Bool {
        exitCode == 0
    }
}

public enum SPKProcessRunnerError: Error, CustomStringConvertible {
    case missingExecutablePath(String)

    public var description: String {
        switch self {
        case .missingExecutablePath(let path):
            "Could not run command because the executable path does not exist: \(path)"
        }
    }
}

public struct SPKProcessRunner: Sendable {
    public init() {}

    public func run(_ executablePath: String, arguments: [String] = []) throws -> SPKCommandResult {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw SPKProcessRunnerError.missingExecutablePath(executablePath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        return SPKCommandResult(
            executablePath: executablePath,
            arguments: arguments,
            exitCode: process.terminationStatus,
            standardOutput: String(decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            standardError: String(decoding: standardError.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }
}
