import Darwin
import Foundation
import ObjectiveC

public struct SPKObjCRuntimeInventory: Codable, Equatable, Sendable {
    public var loadedImages: [SPKLoadedImage]
    public var classes: [SPKObjCClassSummary]
    public var protocols: [SPKObjCProtocolSummary]

    public init(
        loadedImages: [SPKLoadedImage],
        classes: [SPKObjCClassSummary],
        protocols: [SPKObjCProtocolSummary]
    ) {
        self.loadedImages = loadedImages
        self.classes = classes
        self.protocols = protocols
    }
}

public struct SPKLoadedImage: Codable, Equatable, Sendable {
    public var path: String
    public var loaded: Bool
    public var error: String?

    public init(path: String, loaded: Bool, error: String?) {
        self.path = path
        self.loaded = loaded
        self.error = error
    }
}

public struct SPKObjCClassSummary: Codable, Equatable, Sendable {
    public var name: String
    public var imagePath: String?
    public var superclassName: String?
    public var protocols: [String]
    public var properties: [String]
    public var instanceMethods: [String]
    public var classMethods: [String]

    public init(
        name: String,
        imagePath: String?,
        superclassName: String?,
        protocols: [String],
        properties: [String],
        instanceMethods: [String],
        classMethods: [String]
    ) {
        self.name = name
        self.imagePath = imagePath
        self.superclassName = superclassName
        self.protocols = protocols
        self.properties = properties
        self.instanceMethods = instanceMethods
        self.classMethods = classMethods
    }
}

public struct SPKObjCProtocolSummary: Codable, Equatable, Sendable {
    public var name: String
    public var requiredInstanceMethods: [String]
    public var optionalInstanceMethods: [String]

    public init(
        name: String,
        requiredInstanceMethods: [String],
        optionalInstanceMethods: [String]
    ) {
        self.name = name
        self.requiredInstanceMethods = requiredInstanceMethods
        self.optionalInstanceMethods = optionalInstanceMethods
    }
}

public enum SPKObjCRuntimeInspector {
    public static func snapshot(
        loading imagePaths: [String],
        matchingPrefixes prefixes: [String],
        includeProperties: Bool = false,
        includeMethods: Bool = false,
        includeProtocols: Bool = false
    ) -> SPKObjCRuntimeInventory {
        let loadedImages = imagePaths.map(loadImage)
        let classSummaries = matchingClasses(prefixes: prefixes).map {
            summarizeClass(
                $0,
                includeProperties: includeProperties,
                includeMethods: includeMethods
            )
        }
        let protocolSummaries = includeProtocols
            ? matchingProtocols(prefixes: prefixes).map {
                summarizeProtocol($0)
            }
            : []

        return SPKObjCRuntimeInventory(
            loadedImages: loadedImages,
            classes: classSummaries.sorted { $0.name < $1.name },
            protocols: protocolSummaries.sorted { $0.name < $1.name }
        )
    }

    private static func loadImage(_ path: String) -> SPKLoadedImage {
        dlerror()
        guard dlopen(path, RTLD_LAZY | RTLD_LOCAL) != nil else {
            let message = dlerror().map { String(cString: $0) } ?? "dyld did not return a diagnostic"
            return SPKLoadedImage(path: path, loaded: false, error: message)
        }

        return SPKLoadedImage(path: path, loaded: true, error: nil)
    }

    private static func matchingClasses(prefixes: [String]) -> [AnyClass] {
        let count = objc_getClassList(nil, 0)
        guard count > 0 else {
            return []
        }

        let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(count))
        defer {
            classes.deallocate()
        }

        let actualCount = objc_getClassList(AutoreleasingUnsafeMutablePointer(classes), count)
        return (0 ..< Int(actualCount)).compactMap { index in
            guard let candidate = classes[index] else {
                return nil
            }

            let className = String(cString: class_getName(candidate))
            return matches(className, prefixes: prefixes) ? candidate : nil
        }
    }

    private static func matchingProtocols(prefixes: [String]) -> [Protocol] {
        var count: UInt32 = 0
        guard let protocols = objc_copyProtocolList(&count) else {
            return []
        }
        defer {
            free(UnsafeMutableRawPointer(protocols))
        }

        return (0 ..< Int(count)).compactMap { index in
            let candidate = protocols[index]
            let protocolName = String(cString: protocol_getName(candidate))
            return matches(protocolName, prefixes: prefixes) ? candidate : nil
        }
    }

    private static func summarizeClass(
        _ cls: AnyClass,
        includeProperties: Bool,
        includeMethods: Bool
    ) -> SPKObjCClassSummary {
        let metaclass: AnyClass? = object_getClass(cls)
        return SPKObjCClassSummary(
            name: String(cString: class_getName(cls)),
            imagePath: class_getImageName(cls).map { String(cString: $0) },
            superclassName: class_getSuperclass(cls).map { String(cString: class_getName($0)) },
            protocols: classProtocols(cls),
            properties: includeProperties ? classProperties(cls) : [],
            instanceMethods: includeMethods ? classMethods(cls) : [],
            classMethods: includeMethods ? metaclass.map(classMethods) ?? [] : []
        )
    }

    private static func summarizeProtocol(_ proto: Protocol) -> SPKObjCProtocolSummary {
        SPKObjCProtocolSummary(
            name: String(cString: protocol_getName(proto)),
            requiredInstanceMethods: protocolMethods(proto, required: true),
            optionalInstanceMethods: protocolMethods(proto, required: false)
        )
    }

    private static func matches(_ value: String, prefixes: [String]) -> Bool {
        prefixes.isEmpty || prefixes.contains { value.hasPrefix($0) }
    }

    private static func classProtocols(_ cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let protocols = class_copyProtocolList(cls, &count) else {
            return []
        }
        defer {
            free(UnsafeMutableRawPointer(protocols))
        }

        return (0 ..< Int(count))
            .map { String(cString: protocol_getName(protocols[$0])) }
            .sorted()
    }

    private static func classProperties(_ cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(cls, &count) else {
            return []
        }
        defer {
            free(properties)
        }

        return (0 ..< Int(count))
            .map { String(cString: property_getName(properties[$0])) }
            .sorted()
    }

    private static func classMethods(_ cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(cls, &count) else {
            return []
        }
        defer {
            free(methods)
        }

        return (0 ..< Int(count))
            .map { String(cString: sel_getName(method_getName(methods[$0]))) }
            .sorted()
    }

    private static func protocolMethods(_ proto: Protocol, required: Bool) -> [String] {
        var count: UInt32 = 0
        guard let methods = protocol_copyMethodDescriptionList(proto, required, true, &count) else {
            return []
        }
        defer {
            free(methods)
        }

        return (0 ..< Int(count))
            .compactMap { methods[$0].name }
            .map { String(cString: sel_getName($0)) }
            .sorted()
    }
}
