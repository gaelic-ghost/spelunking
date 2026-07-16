import Foundation
import SpelunkingKit

@main
struct SPKMain {
    static func main() throws {
        var arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            printHelp()
            return
        }
        arguments.removeFirst()

        switch command {
        case "targets":
            printTargets()
        case "notifications":
            try inspectNotificationCenter(arguments: arguments)
        case "objc-runtime":
            try printObjCRuntimeInventory(arguments: arguments)
        case "string-constants":
            try printStringConstants(arguments: arguments)
        case "notification-observe":
            try printNotificationObservation(arguments: arguments)
        case "help", "--help", "-h":
            printHelp()
        default:
            throw SPKCLIError.invalidArguments("unknown command '\(command)'")
        }
    }

    private static func printTargets() {
        for target in [SPKResearchTarget.messages, .phone, .mediaRemote] {
            print(target.name)
            print(target.summary)
            print("Docs: \(target.documentationPath)")
            print("Research: \(target.researchPath)")
            print("")
        }
    }

    private static func printObjCRuntimeInventory(arguments: [String]) throws {
        var imagePaths: [String] = []
        var prefixes: [String] = []
        var includeMethods = false
        var includeProperties = false
        var includeProtocols = false
        var format = OutputFormat.text

        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--image":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--image requires a framework binary path")
                }
                imagePaths.append(value)
            case "--prefix":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--prefix requires a class or protocol prefix")
                }
                prefixes.append(value)
            case "--methods":
                includeMethods = true
            case "--properties":
                includeProperties = true
            case "--protocols":
                includeProtocols = true
            case "--json":
                format = .json
            default:
                throw SPKCLIError.invalidArguments("unknown objc-runtime option '\(argument)'")
            }
        }

        guard !imagePaths.isEmpty || !prefixes.isEmpty else {
            throw SPKCLIError.invalidArguments("objc-runtime requires at least one --image or --prefix argument")
        }

        let inventory = SPKObjCRuntimeInspector.snapshot(
            loading: imagePaths,
            matchingPrefixes: prefixes,
            includeProperties: includeProperties,
            includeMethods: includeMethods,
            includeProtocols: includeProtocols
        )

        switch format {
        case .text:
            printTextInventory(inventory)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(inventory)
            print(String(decoding: data, as: UTF8.self))
        }
    }

    private static func printStringConstants(arguments: [String]) throws {
        var imagePath: String?
        var symbols: [String] = []
        var kind = SPKStringConstantKind.nsStringGlobal
        var format = OutputFormat.text

        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--image":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--image requires a framework binary path")
                }
                imagePath = value
            case "--symbol":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--symbol requires an exported NSString constant name")
                }
                symbols.append(value)
            case "--kind":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--kind requires nsstring, c-string, or c-string-pointer")
                }
                switch value {
                case "nsstring":
                    kind = .nsStringGlobal
                case "c-string":
                    kind = .cStringInline
                case "c-string-pointer":
                    kind = .cStringPointer
                default:
                    throw SPKCLIError.invalidArguments("--kind requires nsstring, c-string, or c-string-pointer")
                }
            case "--json":
                format = .json
            default:
                throw SPKCLIError.invalidArguments("unknown string-constants option '\(argument)'")
            }
        }

        guard let imagePath else {
            throw SPKCLIError.invalidArguments("string-constants requires --image")
        }
        guard !symbols.isEmpty else {
            throw SPKCLIError.invalidArguments("string-constants requires at least one --symbol")
        }

        let result = SPKStringConstantResolver.resolveStringConstants(
            imagePath: imagePath,
            symbols: symbols,
            kind: kind
        )

        switch format {
        case .text:
            printStringConstantResult(result)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(result)
            print(String(decoding: data, as: UTF8.self))
        }
    }

    private static func printStringConstantResult(_ result: SPKStringConstantImageResult) {
        if result.image.loaded {
            print("Image: \(result.image.path) loaded")
        } else {
            print("Image: \(result.image.path) not loaded (\(result.image.error ?? "no diagnostic"))")
        }

        for constant in result.constants {
            if let value = constant.value {
                print("\(constant.symbol) = \(value)")
            } else {
                print("\(constant.symbol) unresolved (\(constant.error ?? "no diagnostic"))")
            }
        }
    }

    private static func printNotificationObservation(arguments: [String]) throws {
        var darwinNames: [String] = []
        var distributedNames: [String] = []
        var durationSeconds = 10.0
        var format = OutputFormat.text

        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--darwin":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--darwin requires a notification name")
                }
                darwinNames.append(value)
            case "--distributed":
                guard let value = iterator.next() else {
                    throw SPKCLIError.invalidArguments("--distributed requires a notification name")
                }
                distributedNames.append(value)
            case "--seconds":
                guard let value = iterator.next(), let parsed = Double(value), parsed > 0 else {
                    throw SPKCLIError.invalidArguments("--seconds requires a positive number")
                }
                durationSeconds = parsed
            case "--json":
                format = .json
            default:
                throw SPKCLIError.invalidArguments("unknown notification-observe option '\(argument)'")
            }
        }

        guard !darwinNames.isEmpty || !distributedNames.isEmpty else {
            throw SPKCLIError.invalidArguments("notification-observe requires at least one --darwin or --distributed name")
        }

        let result = SPKNotificationObserver.observe(
            darwinNames: darwinNames,
            distributedNames: distributedNames,
            durationSeconds: durationSeconds
        )

        switch format {
        case .text:
            printNotificationObservationResult(result)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(result)
            print(String(decoding: data, as: UTF8.self))
        }
    }

    private static func printNotificationObservationResult(_ result: SPKNotificationObservationResult) {
        print("Started: \(result.startedAt)")
        print("Ended: \(result.endedAt)")
        print("Duration: \(result.durationSeconds)s")
        print("")
        print("Watches:")
        for watch in result.watches {
            if watch.registered {
                print("- \(watch.mechanism.rawValue): \(watch.name) registered")
            } else {
                print("- \(watch.mechanism.rawValue): \(watch.name) failed (\(watch.error ?? "no diagnostic"))")
            }
        }
        print("")
        print("Events (\(result.events.count)):")
        for event in result.events {
            if let payloadKeyCount = event.payloadKeyCount {
                print("- \(event.observedAt) \(event.mechanism.rawValue) \(event.name) payloadKeys=\(payloadKeyCount)")
            } else {
                print("- \(event.observedAt) \(event.mechanism.rawValue) \(event.name)")
            }
        }
    }

    private static func printTextInventory(_ inventory: SPKObjCRuntimeInventory) {
        print("Loaded images:")
        for image in inventory.loadedImages {
            if image.loaded {
                print("- \(image.path): loaded")
            } else {
                print("- \(image.path): not loaded (\(image.error ?? "no diagnostic"))")
            }
        }

        print("")
        print("Classes (\(inventory.classes.count)):")
        for cls in inventory.classes {
            print("- \(cls.name)")
            if let superclassName = cls.superclassName {
                print("  superclass: \(superclassName)")
            }
            if let imagePath = cls.imagePath {
                print("  image: \(imagePath)")
            }
            printIndentedList("protocols", cls.protocols)
            printIndentedList("properties", cls.properties)
            printIndentedList("instance methods", cls.instanceMethods)
            printIndentedList("class methods", cls.classMethods)
        }

        print("")
        print("Protocols (\(inventory.protocols.count)):")
        for proto in inventory.protocols {
            print("- \(proto.name)")
            printIndentedList("required instance methods", proto.requiredInstanceMethods)
            printIndentedList("optional instance methods", proto.optionalInstanceMethods)
        }
    }

    private static func printIndentedList(_ label: String, _ values: [String]) {
        guard !values.isEmpty else {
            return
        }

        print("  \(label):")
        for value in values {
            print("    - \(value)")
        }
    }

    private static func printHelp() {
        print(
            """
            Usage:
              spelunk targets
              spelunk notifications [--max-depth N]
              spelunk objc-runtime [--image PATH] [--prefix PREFIX] [--methods] [--properties] [--protocols] [--json]
              spelunk string-constants --image PATH --symbol SYMBOL [--symbol SYMBOL ...] [--kind nsstring|c-string|c-string-pointer] [--json]
              spelunk notification-observe [--darwin NAME] [--distributed NAME] [--seconds N] [--json]

            Commands:
              targets       List seeded research targets.
              notifications Inspect Notification Center accessibility surfaces as JSON.
              objc-runtime  Load framework images read-only and print matching Objective-C runtime metadata.
              string-constants
                            Load a framework image read-only and print exported NSString constant values.
              notification-observe
                            Observe selected Darwin notify and distributed notification names for a bounded duration.
            """
        )
    }

    private enum OutputFormat {
        case text
        case json
    }

    private enum SPKCLIError: Error, CustomStringConvertible {
        case invalidArguments(String)

        var description: String {
            switch self {
            case .invalidArguments(let message):
                return "Invalid spelunk arguments: \(message)"
            }
        }
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
