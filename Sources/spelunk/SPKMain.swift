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
        case "objc-runtime":
            try printObjCRuntimeInventory(arguments: arguments)
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
              spelunk objc-runtime [--image PATH] [--prefix PREFIX] [--methods] [--properties] [--protocols] [--json]

            Commands:
              targets       List seeded research targets.
              objc-runtime  Load framework images read-only and print matching Objective-C runtime metadata.
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
}
