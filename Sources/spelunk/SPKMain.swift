import Foundation
import SpelunkingKit

@main
struct SPKMain {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if arguments.first == "notifications" {
            try inspectNotificationCenter(arguments: Array(arguments.dropFirst()))
            return
        }

        let target = SPKResearchTarget.mediaRemote

        print(target.name)
        print(target.summary)
        print("Docs: \(target.documentationPath)")
        print("Research: \(target.researchPath)")
    }

    private static func inspectNotificationCenter(arguments: [String]) throws {
        let maximumDepth = parseMaximumDepth(arguments) ?? 6
        let result = SPKNotificationCenterAccessibilityProbe().inspect(maximumDepth: maximumDepth)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(decoding: try encoder.encode(result), as: UTF8.self))
    }

    private static func parseMaximumDepth(_ arguments: [String]) -> Int? {
        guard let index = arguments.firstIndex(of: "--max-depth"),
              arguments.indices.contains(index + 1),
              let depth = Int(arguments[index + 1]), depth >= 0 else {
            return nil
        }
        return depth
    }
}
