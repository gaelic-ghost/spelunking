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

typealias MRMediaRemoteGetOrigin = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (Bool, AnyObject?) -> Void
) -> Void

typealias MRMediaRemoteGetOrigins = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (NSArray?) -> Void
) -> Void

typealias MRMediaRemoteGetObjectsForOrigin = @convention(c) (
    AnyObject,
    DispatchQueue,
    @escaping @convention(block) (NSArray?) -> Void
) -> Void

typealias MRMediaRemoteGetObjectForOrigin = @convention(c) (
    AnyObject,
    DispatchQueue,
    @escaping @convention(block) (AnyObject?) -> Void
) -> Void

typealias MROriginGetDisplayName = @convention(c) (AnyObject) -> CFString?
typealias MROriginGetOriginType = @convention(c) (AnyObject) -> Int32
typealias MROriginGetUniqueIdentifier = @convention(c) (AnyObject) -> Int32
typealias MROriginIsLocalOrigin = @convention(c) (AnyObject) -> Bool
typealias MRNowPlayingPlayerPathCopyStringRepresentation = @convention(c) (AnyObject) -> CFString?
typealias MRNowPlayingPlayerPathGetObject = @convention(c) (AnyObject) -> AnyObject?
typealias MRNowPlayingPlayerGetString = @convention(c) (AnyObject) -> CFString?
typealias MRNowPlayingPlayerGetInt32 = @convention(c) (AnyObject) -> Int32
typealias MRNowPlayingClientGetString = @convention(c) (AnyObject) -> CFString?
typealias MRNowPlayingClientGetInt32 = @convention(c) (AnyObject) -> Int32

enum SPKProbeError: Error, CustomStringConvertible {
    case frameworkLoadFailed([String])
    case missingSymbol(String)
    case callbackTimedOut(operation: String, seconds: Int)

    var description: String {
        switch self {
        case let .frameworkLoadFailed(errors):
            return "Could not load MediaRemote.framework from dyld cache or framework paths. Tried paths failed with: \(errors.joined(separator: " | "))"
        case let .missingSymbol(symbol):
            return "Could not find required MediaRemote symbol \(symbol). The active OS may have changed the private API surface."
        case let .callbackTimedOut(operation, seconds):
            return "Timed out after \(seconds)s waiting for \(operation). mediaremoted may be unavailable or the private API signature may have changed."
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
        let shouldReadOrigins = arguments.contains("--origins") || arguments.contains("--all")
        let shouldRequestQueues = arguments.contains("--queue")
        let shouldReadInternalRequests = arguments.contains("--internal-requests")
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

        if shouldReadOrigins {
            try readOrigins(
                handle: handle,
                shouldRequestQueues: shouldRequestQueues,
                shouldReadInternalRequests: shouldReadInternalRequests
            )
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: timeoutSeconds)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
        }

        return result
    }

    private static func readOrigins(
        handle: UnsafeMutableRawPointer,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) throws {
        print("MediaRemote read-only origin probe")

        readOriginIfAvailable(
            handle: handle,
            symbolName: "MRMediaRemoteGetLocalOrigin",
            label: "Local origin",
            shouldRequestQueues: shouldRequestQueues,
            shouldReadInternalRequests: shouldReadInternalRequests
        )
        readOriginIfAvailable(
            handle: handle,
            symbolName: "MRMediaRemoteGetActiveOrigin",
            label: "Active origin",
            shouldRequestQueues: shouldRequestQueues,
            shouldReadInternalRequests: shouldReadInternalRequests
        )
        readAvailableOriginsIfAvailable(
            handle: handle,
            shouldRequestQueues: shouldRequestQueues,
            shouldReadInternalRequests: shouldReadInternalRequests
        )
    }

    private static func readOriginIfAvailable(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        label: String,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) {
        do {
            try readOrigin(
                handle: handle,
                symbolName: symbolName,
                label: label,
                shouldRequestQueues: shouldRequestQueues,
                shouldReadInternalRequests: shouldReadInternalRequests
            )
        } catch {
            print("\(label): \(error)")
        }
    }

    private static func readAvailableOriginsIfAvailable(
        handle: UnsafeMutableRawPointer,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) {
        do {
            try readAvailableOrigins(
                handle: handle,
                shouldRequestQueues: shouldRequestQueues,
                shouldReadInternalRequests: shouldReadInternalRequests
            )
        } catch {
            print("Available origins: \(error)")
        }
    }

    private static func readOrigin(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        label: String,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) throws {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetOrigin.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        function(callbackQueue) { success, origin in
            defer { semaphore.signal() }

            guard let origin else {
                print("\(label): <nil> success=\(success)")
                return
            }

            print("\(label): success=\(success) \(summarizeOrigin(origin, handle: handle))")
            readOriginDetails(
                handle: handle,
                origin: origin,
                label: label,
                shouldRequestQueues: shouldRequestQueues,
                shouldReadInternalRequests: shouldReadInternalRequests
            )
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
        }
    }

    private static func readAvailableOrigins(
        handle: UnsafeMutableRawPointer,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) throws {
        let symbolName = "MRMediaRemoteGetAvailableOrigins"

        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetOrigins.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)

        function(callbackQueue) { origins in
            defer { semaphore.signal() }

            guard let origins else {
                print("Available origins: <nil>")
                return
            }

            print("Available origins: \(origins.count) item(s)")

            for (index, item) in origins.enumerated() {
                guard let origin = item as AnyObject? else {
                    print("Origin[\(index)]: <nil>")
                    continue
                }

                let label = "Origin[\(index)]"
                print("\(label): \(summarizeOrigin(origin, handle: handle))")
                readOriginDetails(
                    handle: handle,
                    origin: origin,
                    label: label,
                    shouldRequestQueues: shouldRequestQueues,
                    shouldReadInternalRequests: shouldReadInternalRequests
                )
            }
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
        }
    }

    private static func readOriginDetails(
        handle: UnsafeMutableRawPointer,
        origin: AnyObject,
        label: String,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) {
        if let info = try? readInfoForObject(
            handle: handle,
            symbolName: "MRMediaRemoteGetNowPlayingInfoForOrigin",
            object: origin
        ) {
            printDictionary(info, prefix: "\(label) now-playing info")
        }

        do {
            let client = try readObjectForOrigin(
                handle: handle,
                symbolName: "MRMediaRemoteGetNowPlayingClientForOrigin",
                origin: origin
            )
            if let client {
                print("\(label) now-playing client: \(summarizeObject(client, handle: handle))")
            } else {
                print("\(label) now-playing client: <nil>")
            }
        } catch {
            print("\(label) now-playing client: \(error)")
        }

        do {
            let clients = try readObjectsForOrigin(
                handle: handle,
                symbolName: "MRMediaRemoteGetNowPlayingClientsForOrigin",
                origin: origin
            )
            print("\(label) now-playing clients: \(clients?.count ?? 0) item(s)")
        } catch {
            print("\(label) now-playing clients: \(error)")
        }

        do {
            let playerPaths = try readObjectsForOrigin(
                handle: handle,
                symbolName: "MRMediaRemoteGetActivePlayerPathsForOrigin",
                origin: origin
            )
            guard let playerPaths else {
                print("\(label) active player paths: <nil>")
                return
            }

            print("\(label) active player paths: \(playerPaths.count) item(s)")

            for (index, item) in playerPaths.enumerated() {
                guard let playerPath = item as AnyObject? else {
                    print("\(label) playerPath[\(index)]: <nil>")
                    continue
                }

                let playerPathLabel = "\(label) playerPath[\(index)]"
                print("\(playerPathLabel): \(summarizePlayerPath(playerPath, handle: handle))")
                readPlayerPathDetails(
                    handle: handle,
                    playerPath: playerPath,
                    label: playerPathLabel,
                    shouldRequestQueues: shouldRequestQueues,
                    shouldReadInternalRequests: shouldReadInternalRequests
                )
            }
        } catch {
            print("\(label) active player paths: \(error)")
        }
    }

    private static func readPlayerPathDetails(
        handle: UnsafeMutableRawPointer,
        playerPath: AnyObject,
        label: String,
        shouldRequestQueues: Bool,
        shouldReadInternalRequests: Bool
    ) {
        if let client = objectFromPlayerPath(handle: handle, playerPath: playerPath, symbolName: "MRNowPlayingPlayerPathGetClient") {
            print("\(label) client: \(summarizeClient(client, handle: handle))")
        }

        if let player = objectFromPlayerPath(handle: handle, playerPath: playerPath, symbolName: "MRNowPlayingPlayerPathGetPlayer") {
            print("\(label) player: \(summarizePlayer(player, handle: handle))")

            if shouldRequestQueues {
                print("\(label) playback queue: disabled; MRMediaRemoteRequestNowPlayingPlaybackQueueForPlayerSync crashed with path-derived MRPlayer")
            }
        }

        if let origin = objectFromPlayerPath(handle: handle, playerPath: playerPath, symbolName: "MRNowPlayingPlayerPathGetOrigin") {
            print("\(label) origin: \(summarizeOrigin(origin, handle: handle))")
        }

        if shouldReadInternalRequests {
            readInternalPlayerPathWrappers(playerPath: playerPath, label: label)
        }
    }

    private static func readInternalPlayerPathWrappers(playerPath: AnyObject, label: String) {
        _ = playerPath
        print("\(label) internal wrappers: disabled; constructing MRNowPlayingPlayerClient or MRNowPlayingPlayerClientRequests from MRPlayerPath crashed in Swift runtime bridging")
        print("\(label) internal wrappers: crash reports mr-now-playing-probe-2026-07-16-041234.ips and mr-now-playing-probe-2026-07-16-041335.ips")
    }

    private static func objectFromPlayerPath(
        handle: UnsafeMutableRawPointer,
        playerPath: AnyObject,
        symbolName: String
    ) -> AnyObject? {
        guard let symbol = dlsym(handle, symbolName) else {
            print("Player path detail: missing symbol \(symbolName)")
            return nil
        }

        let function = unsafeBitCast(symbol, to: MRNowPlayingPlayerPathGetObject.self)
        return function(playerPath)
    }

    private static func readObjectsForOrigin(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        origin: AnyObject
    ) throws -> NSArray? {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetObjectsForOrigin.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)
        var result: NSArray?

        function(origin, callbackQueue) { objects in
            result = objects
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
        }

        return result
    }

    private static func readObjectForOrigin(
        handle: UnsafeMutableRawPointer,
        symbolName: String,
        origin: AnyObject
    ) throws -> AnyObject? {
        guard let symbol = dlsym(handle, symbolName) else {
            throw SPKProbeError.missingSymbol(symbolName)
        }

        let function = unsafeBitCast(symbol, to: MRMediaRemoteGetObjectForOrigin.self)
        let callbackQueue = DispatchQueue(label: "com.galewilliams.spelunking.mediaremote.\(symbolName)")
        let semaphore = DispatchSemaphore(value: 0)
        var result: AnyObject?

        function(origin, callbackQueue) { object in
            result = object
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + .seconds(5)) == .success else {
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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
            throw SPKProbeError.callbackTimedOut(operation: symbolName, seconds: 5)
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

    private static func summarizeOrigin(_ origin: AnyObject, handle: UnsafeMutableRawPointer) -> String {
        var parts = ["\(type(of: origin))", "\(origin)"]

        if let symbol = dlsym(handle, "MROriginGetDisplayName") {
            let function = unsafeBitCast(symbol, to: MROriginGetDisplayName.self)
            if let displayName = function(origin) {
                parts.append("displayName=\(displayName)")
            }
        }

        if let symbol = dlsym(handle, "MROriginGetUniqueIdentifier") {
            let function = unsafeBitCast(symbol, to: MROriginGetUniqueIdentifier.self)
            parts.append("uniqueIdentifier=\(function(origin))")
        }

        if let symbol = dlsym(handle, "MROriginGetOriginType") {
            let function = unsafeBitCast(symbol, to: MROriginGetOriginType.self)
            parts.append("originType=\(function(origin))")
        }

        if let symbol = dlsym(handle, "MROriginIsLocalOrigin") {
            let function = unsafeBitCast(symbol, to: MROriginIsLocalOrigin.self)
            parts.append("isLocal=\(function(origin))")
        }

        return parts.joined(separator: " ")
    }

    private static func summarizePlayerPath(_ playerPath: AnyObject, handle: UnsafeMutableRawPointer) -> String {
        if let symbol = dlsym(handle, "MRNowPlayingPlayerPathCopyStringRepresentation") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingPlayerPathCopyStringRepresentation.self)
            if let representation = function(playerPath) {
                return "\(type(of: playerPath)) \(representation)"
            }
        }

        return "\(type(of: playerPath)) \(playerPath)"
    }

    private static func summarizeClient(_ client: AnyObject, handle: UnsafeMutableRawPointer) -> String {
        var parts = ["\(type(of: client))", "\(client)"]

        if let symbol = dlsym(handle, "MRNowPlayingClientGetBundleIdentifier") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingClientGetString.self)
            if let bundleIdentifier = function(client) {
                parts.append("bundleIdentifier=\(bundleIdentifier)")
            }
        }

        if let symbol = dlsym(handle, "MRNowPlayingClientGetDisplayName") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingClientGetString.self)
            if let displayName = function(client) {
                parts.append("displayName=\(displayName)")
            }
        }

        if let symbol = dlsym(handle, "MRNowPlayingClientGetParentAppBundleIdentifier") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingClientGetString.self)
            if let parentBundleIdentifier = function(client) {
                parts.append("parentBundleIdentifier=\(parentBundleIdentifier)")
            }
        }

        if let symbol = dlsym(handle, "MRNowPlayingClientGetProcessIdentifier") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingClientGetInt32.self)
            parts.append("processIdentifier=\(function(client))")
        }

        return parts.joined(separator: " ")
    }

    private static func summarizePlayer(_ player: AnyObject, handle: UnsafeMutableRawPointer) -> String {
        var parts = ["\(type(of: player))", "\(player)"]

        if let symbol = dlsym(handle, "MRNowPlayingPlayerGetIdentifier") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingPlayerGetString.self)
            if let identifier = function(player) {
                parts.append("identifier=\(identifier)")
            }
        }

        if let symbol = dlsym(handle, "MRNowPlayingPlayerGetDisplayName") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingPlayerGetString.self)
            if let displayName = function(player) {
                parts.append("displayName=\(displayName)")
            }
        }

        if let symbol = dlsym(handle, "MRNowPlayingPlayerGetAudioSessionType") {
            let function = unsafeBitCast(symbol, to: MRNowPlayingPlayerGetInt32.self)
            parts.append("audioSessionType=\(function(player))")
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
