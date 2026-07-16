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

typealias MRMediaRemoteGetNowPlayingClients = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (NSArray?) -> Void
) -> Void

typealias MRMediaRemoteGetNowPlayingPlayer = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (AnyObject?) -> Void
) -> Void

typealias MRMediaRemoteGetNowPlayingInfoForObject = @convention(c) (
    AnyObject,
    DispatchQueue,
    @escaping @convention(block) (CFDictionary?) -> Void
) -> Void

typealias MRNowPlayingClientGetBundleIdentifier = @convention(c) (AnyObject) -> NSString?

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
        let shouldReadClients = arguments.contains("--clients") || arguments.contains("--all")
        let shouldReadPlayer = arguments.contains("--player") || arguments.contains("--all")
        let observeSeconds = parseObserveSeconds(arguments: Array(CommandLine.arguments.dropFirst()))

        if shouldPrime {
            try primeNowPlayingNotifications(handle: handle)
        }

        if let observeSeconds {
            try observeNowPlayingNotifications(handle: handle, seconds: observeSeconds)
        }

        if shouldReadApplication {
            try readNowPlayingApplication(handle: handle)
        }

        if shouldReadClients {
            try readNowPlayingClients(handle: handle)
        }

        if shouldReadPlayer {
            try readNowPlayingPlayer(handle: handle)
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

    private static func readNowPlayingClients(handle: UnsafeMutableRawPointer) throws {
        let symbolName = "MRMediaRemoteGetNowPlayingClients"

        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingClients.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        print("MediaRemote read-only now-playing clients probe")

        function(callbackQueue) { clients in
            defer { semaphore.signal() }

            guard let clients else {
                print("Now-playing clients: <nil>")
                return
            }

            print("Now-playing clients: \(clients.count) item(s)")

            for (index, item) in clients.enumerated() {
                guard let client = item as AnyObject? else {
                    print("Client[\(index)]: <nil>")
                    continue
                }

                print("Client[\(index)]: \(summarizeObject(client, handle: handle))")

                if let info = try? readInfoForObject(
                    handle: handle,
                    symbolName: "MRMediaRemoteGetNowPlayingInfoForClient",
                    object: client
                ) {
                    printDictionary(info, prefix: "Client[\(index)] info")
                }
            }
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }
    }

    private static func readNowPlayingPlayer(handle: UnsafeMutableRawPointer) throws {
        let symbolName = "MRMediaRemoteGetNowPlayingPlayer"

        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingPlayer.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        print("MediaRemote read-only now-playing player probe")

        function(callbackQueue) { player in
            defer { semaphore.signal() }

            guard let player else {
                print("Now-playing player: <nil>")
                return
            }

            print("Now-playing player: \(summarizeObject(player, handle: handle))")

            if let info = try? readInfoForObject(
                handle: handle,
                symbolName: "MRMediaRemoteGetNowPlayingInfoForPlayer",
                object: player
            ) {
                printDictionary(info, prefix: "Player info")
            }
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }
    }

    private static func readInfoForObject(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        object: AnyObject
    ) throws -> NSDictionary? {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetNowPlayingInfoForObject.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)
        var result: NSDictionary?

        function(object, callbackQueue) { dictionary in
            result = dictionary as NSDictionary?
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(seconds: 5)
        }

        return result
    }

    private static func observeNowPlayingNotifications(
        handle: UnsafeMutableRawPointer,
        seconds: Int
    ) throws {
        try primeNowPlayingNotifications(handle: handle)

        print("Observing now-playing notifications for \(seconds)s")

        let notificationNames = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemotePlaybackStateDidChangeNotification",
            "kMRMediaRemoteSupportedCommandsDidChangeNotification"
        ]
        let center = NotificationCenter.default
        var observers: [NSObjectProtocol] = []

        for name in notificationNames {
            let observer = center.addObserver(
                forName: Notification.Name(name),
                object: nil,
                queue: nil
            ) { notification in
                let userInfo = notification.userInfo ?? [:]
                print("Notification: \(notification.name.rawValue) userInfoKeys=\(userInfo.keys.map(String.init(describing:)).sorted())")
            }

            observers.append(observer)
        }

        RunLoop.current.run(until: Date().addingTimeInterval(TimeInterval(seconds)))

        for observer in observers {
            center.removeObserver(observer)
        }
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
                print("Now-playing client: \(summarizeObject(client, handle: handle))")
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

    private static func summarizeObject(_ object: AnyObject, handle: UnsafeMutableRawPointer) -> String {
        var parts = ["\(type(of: object))", "\(object)"]

        if let symbol = dlsym(handle, "MRNowPlayingClientGetBundleIdentifier") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingClientGetBundleIdentifier.self)
            if let bundleID = function(object) {
                parts.append("bundleIdentifier=\(bundleID)")
            }
        }

        return parts.joined(separator: " ")
    }

    private static func printDictionary(_ dictionary: NSDictionary?, prefix: String) {
        guard let dictionary else {
            print("\(prefix): <nil>")
            return
        }

        print("\(prefix): \(dictionary.count) key(s)")

        for key in dictionary.allKeys.map(String.init(describing:)).sorted() {
            guard let value = dictionary[key] else {
                continue
            }

            print("\(prefix).\(key): \(summarize(value))")
        }
    }

    private static func parseObserveSeconds(arguments: [String]) -> Int? {
        guard let observeIndex = arguments.firstIndex(of: "--observe") else {
            return nil
        }

        let nextIndex = arguments.index(after: observeIndex)

        guard nextIndex < arguments.endIndex else {
            return 10
        }

        return Int(arguments[nextIndex]) ?? 10
    }
}
