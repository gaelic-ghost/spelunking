import Darwin
import Dispatch
import Foundation

typealias MRMediaRemoteGetNowPlayingInfo = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (CFDictionary?) -> Void
) -> Void

typealias MRMediaRemoteRegisterForNowPlayingNotifications = @convention(c) (DispatchQueue) -> Void
typealias MRMediaRemoteSetWantsNowPlayingNotifications = @convention(c) (Bool) -> Void

typealias MRMediaRemoteGetNowPlayingBool = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (Bool) -> Void
) -> Void

typealias MRMediaRemoteGetNowPlayingInt32 = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (Int32) -> Void
) -> Void

typealias MRMediaRemoteGetNowPlayingClient = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (AnyObject?) -> Void
) -> Void

enum SPKProbeError: Error, CustomStringConvertible {
    case frameworkLoadFailed([String])
    case missingSymbol(String)
    case callbackTimedOut(seconds: Int)

    var description: String {
        switch self {
        case let .frameworkLoadFailed(errors):
            return "Could not load MediaRemote.framework from dyld cache or framework paths. Tried paths failed with: \(errors.joined(separator: " | "))"
        case let .missingSymbol(symbol):
            return "Could not find required MediaRemote symbol \(symbol). The active OS may have changed the private API surface."
        case let .callbackTimedOut(seconds):
            return "Timed out after \(seconds)s waiting for MRMediaRemoteGetNowPlayingInfo callback. mediaremoted may be unavailable or the private API signature may have changed."
        }
    }
}

@main
struct SPKMRNowPlayingProbe {
    static func main() {
        do {
            try run()
        } catch {
            fputs("mr-now-playing-probe: \(error)\n", stderr)
            exit(1)
        }
    }

    private static func run() throws {
        let handle = try loadMediaRemote()
        let arguments = Set(CommandLine.arguments.dropFirst())
        let shouldPrime = arguments.contains("--prime") || arguments.contains("--all")
        let shouldReadApplication = arguments.contains("--application") || arguments.contains("--all")

        if shouldPrime {
            try primeNowPlayingNotifications(handle: handle)
        }

        if shouldReadApplication {
            try readNowPlayingApplication(handle: handle)
        }

        try readNowPlayingInfo(handle: handle)
    }

    private static func readNowPlayingInfo(handle: UnsafeMutableRawPointer) throws {
        let symbolName = "MRMediaRemoteGetNowPlayingInfo"

        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let getNowPlayingInfo = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingInfo.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.now-playing-probe")
        let semaphore = DispatchSemaphore(value: 0)
        let timeoutSeconds = 5

        print("MediaRemote read-only now-playing probe")
        print("Symbol: \(symbolName)")

        getNowPlayingInfo(callbackQueue) { dictionary in
            defer { semaphore.signal() }

            guard let dictionary else {
                print("Result: callback returned nil dictionary")
                return
            }

            let nowPlayingInfo = dictionary as NSDictionary
            print("Result: callback returned \(nowPlayingInfo.count) key(s)")

            for key in nowPlayingInfo.allKeys.map(String.init(describing:)).sorted() {
                guard let value = nowPlayingInfo[key] else {
                    continue
                }

                print("\(key): \(summarize(value))")
            }
        }

        guard semaphore.wait(timeout: .now() + .seconds(timeoutSeconds)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: timeoutSeconds)
        }
    }

    private static func primeNowPlayingNotifications(handle: UnsafeMutableRawPointer) throws {
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.now-playing-prime")

        if let symbol = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            let register = unsafeBitCast(symbol, to: MRMediaRemoteRegisterForNowPlayingNotifications.self)
            register(callbackQueue)
            print("Primed: MRMediaRemoteRegisterForNowPlayingNotifications")
        } else {
            throw SPKProbeError.missingSymbol("MRMediaRemoteRegisterForNowPlayingNotifications")
        }

        if let symbol = dlsym(handle, "MRMediaRemoteSetWantsNowPlayingNotifications") {
            let setWants = unsafeBitCast(symbol, to: MRMediaRemoteSetWantsNowPlayingNotifications.self)
            setWants(true)
            print("Primed: MRMediaRemoteSetWantsNowPlayingNotifications(true)")
        } else {
            throw SPKProbeError.missingSymbol("MRMediaRemoteSetWantsNowPlayingNotifications")
        }

        Thread.sleep(forTimeInterval: 0.5)
    }

    private static func readNowPlayingApplication(handle: UnsafeMutableRawPointer) throws {
        print("MediaRemote read-only now-playing application probe")

        try readBool(
            handle: handle,
            symbolName: "MRMediaRemoteGetNowPlayingApplicationIsPlaying",
            label: "Application is playing"
        )
        try readInt32(
            handle: handle,
            symbolName: "MRMediaRemoteGetNowPlayingApplicationPID",
            label: "Application PID"
        )
        try readClient(handle: handle)
    }

    private static func readBool(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        label: String
    ) throws {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingBool.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        function(callbackQueue) { value in
            print("\(label): \(value)")
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }
    }

    private static func readInt32(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        label: String
    ) throws {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingInt32.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        function(callbackQueue) { value in
            print("\(label): \(value)")
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }
    }

    private static func readClient(handle: UnsafeMutableRawPointer) throws {
        let symbolName = "MRMediaRemoteGetNowPlayingClient"

        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingClient.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        function(callbackQueue) { client in
            if let client {
                print("Now-playing client: \(type(of: client)) \(client)")
            } else {
                print("Now-playing client: <nil>")
            }

            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }
    }

    private static func loadMediaRemote() throws -> UnsafeMutableRawPointer {
        let paths = [
            "/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote",
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        ]

        var errors: [String] = []

        for path in paths {
            if let handle = dlopen(path, RTLD_NOW) {
                return handle
            }

            errors.append("\(path): \(String(cString: dlerror()))")
        }

        throw SPKProbeError.frameworkLoadFailed(errors)
    }

    private static func summarize(_ value: Any) -> String {
        switch value {
        case let data as Data:
            return "<Data \(data.count) byte(s)>"
        case let dictionary as NSDictionary:
            return "<Dictionary \(dictionary.count) key(s)>"
        case let array as NSArray:
            return "<Array \(array.count) item(s)>"
        default:
            return String(describing: value)
        }
    }
}
