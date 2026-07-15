import Darwin
import Dispatch
import Foundation

typealias MRMediaRemoteGetNowPlayingInfo = @convention(c) (
    DispatchQueue,
    @escaping @convention(block) (CFDictionary?) -> Void
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
