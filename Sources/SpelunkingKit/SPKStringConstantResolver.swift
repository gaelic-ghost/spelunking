import Darwin
import Foundation

public struct SPKStringConstantResolution: Codable, Equatable, Sendable {
    public var symbol: String
    public var lookupSymbol: String
    public var kind: SPKStringConstantKind
    public var value: String?
    public var error: String?

    public init(
        symbol: String,
        lookupSymbol: String,
        kind: SPKStringConstantKind,
        value: String?,
        error: String?
    ) {
        self.symbol = symbol
        self.lookupSymbol = lookupSymbol
        self.kind = kind
        self.value = value
        self.error = error
    }
}

public enum SPKStringConstantKind: String, Codable, Equatable, Sendable {
    case nsStringGlobal
    case cStringInline
    case cStringPointer
}

public struct SPKStringConstantImageResult: Codable, Equatable, Sendable {
    public var image: SPKLoadedImage
    public var constants: [SPKStringConstantResolution]

    public init(image: SPKLoadedImage, constants: [SPKStringConstantResolution]) {
        self.image = image
        self.constants = constants
    }
}

public enum SPKStringConstantResolver {
    public static func resolveStringConstants(
        imagePath: String,
        symbols: [String],
        kind: SPKStringConstantKind = .nsStringGlobal
    ) -> SPKStringConstantImageResult {
        let loadResult = loadImage(imagePath)
        guard loadResult.loaded else {
            return SPKStringConstantImageResult(
                image: loadResult,
                constants: symbols.map {
                    SPKStringConstantResolution(
                        symbol: $0,
                        lookupSymbol: normalizedSymbolName($0),
                        kind: kind,
                        value: nil,
                        error: "image did not load"
                    )
                }
            )
        }

        guard let handle = dlopen(imagePath, RTLD_LAZY | RTLD_LOCAL) else {
            return SPKStringConstantImageResult(
                image: loadResult,
                constants: symbols.map {
                    SPKStringConstantResolution(
                        symbol: $0,
                        lookupSymbol: normalizedSymbolName($0),
                        kind: kind,
                        value: nil,
                        error: "image loaded earlier, but a second dlopen returned nil"
                    )
                }
            )
        }

        return SPKStringConstantImageResult(
            image: loadResult,
            constants: symbols.map { resolveConstant(handle: handle, symbol: $0, kind: kind) }
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

    private static func resolveConstant(
        handle: UnsafeMutableRawPointer,
        symbol: String,
        kind: SPKStringConstantKind
    ) -> SPKStringConstantResolution {
        let lookupSymbol = normalizedSymbolName(symbol)
        guard let symbolAddress = dlsym(handle, lookupSymbol) else {
            return SPKStringConstantResolution(
                symbol: symbol,
                lookupSymbol: lookupSymbol,
                kind: kind,
                value: nil,
                error: dlerror().map { String(cString: $0) } ?? "symbol not found"
            )
        }

        switch kind {
        case .nsStringGlobal:
            return resolveNSStringGlobal(symbol: symbol, lookupSymbol: lookupSymbol, symbolAddress: symbolAddress)
        case .cStringInline:
            return SPKStringConstantResolution(
                symbol: symbol,
                lookupSymbol: lookupSymbol,
                kind: kind,
                value: String(cString: symbolAddress.assumingMemoryBound(to: CChar.self)),
                error: nil
            )
        case .cStringPointer:
            let stringAddress = symbolAddress
                .assumingMemoryBound(to: UnsafePointer<CChar>?.self)
                .pointee
            guard let stringAddress else {
                return SPKStringConstantResolution(
                    symbol: symbol,
                    lookupSymbol: lookupSymbol,
                    kind: kind,
                    value: nil,
                    error: "symbol resolved to a nil C string pointer"
                )
            }
            return SPKStringConstantResolution(
                symbol: symbol,
                lookupSymbol: lookupSymbol,
                kind: kind,
                value: String(cString: stringAddress),
                error: nil
            )
        }
    }

    private static func resolveNSStringGlobal(
        symbol: String,
        lookupSymbol: String,
        symbolAddress: UnsafeMutableRawPointer
    ) -> SPKStringConstantResolution {
        let objectAddress = symbolAddress
            .assumingMemoryBound(to: UnsafeRawPointer?.self)
            .pointee

        guard let objectAddress else {
            return SPKStringConstantResolution(
                symbol: symbol,
                lookupSymbol: lookupSymbol,
                kind: .nsStringGlobal,
                value: nil,
                error: "symbol resolved to a nil object pointer"
            )
        }

        let object = Unmanaged<AnyObject>.fromOpaque(objectAddress).takeUnretainedValue()
        guard let value = object as? String else {
            return SPKStringConstantResolution(
                symbol: symbol,
                lookupSymbol: lookupSymbol,
                kind: .nsStringGlobal,
                value: nil,
                error: "symbol resolved, but value was \(type(of: object)) instead of NSString/String"
            )
        }

        return SPKStringConstantResolution(
            symbol: symbol,
            lookupSymbol: lookupSymbol,
            kind: .nsStringGlobal,
            value: value,
            error: nil
        )
    }

    private static func normalizedSymbolName(_ symbol: String) -> String {
        symbol.hasPrefix("_") ? String(symbol.dropFirst()) : symbol
    }
}
