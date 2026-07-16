import CSpelunkingNotify
import Darwin
import Dispatch
import Foundation

public enum SPKNotificationMechanism: String, Codable, Equatable, Sendable {
    case darwinNotify
    case distributedNotificationCenter
}

public struct SPKNotificationWatch: Codable, Equatable, Sendable {
    public var mechanism: SPKNotificationMechanism
    public var name: String
    public var registered: Bool
    public var error: String?

    public init(
        mechanism: SPKNotificationMechanism,
        name: String,
        registered: Bool,
        error: String?
    ) {
        self.mechanism = mechanism
        self.name = name
        self.registered = registered
        self.error = error
    }
}

public struct SPKNotificationEvent: Codable, Equatable, Sendable {
    public var mechanism: SPKNotificationMechanism
    public var name: String
    public var observedAt: String
    public var payloadKeyCount: Int?

    public init(
        mechanism: SPKNotificationMechanism,
        name: String,
        observedAt: String,
        payloadKeyCount: Int?
    ) {
        self.mechanism = mechanism
        self.name = name
        self.observedAt = observedAt
        self.payloadKeyCount = payloadKeyCount
    }
}

public struct SPKNotificationObservationResult: Codable, Equatable, Sendable {
    public var startedAt: String
    public var endedAt: String
    public var durationSeconds: Double
    public var watches: [SPKNotificationWatch]
    public var events: [SPKNotificationEvent]

    public init(
        startedAt: String,
        endedAt: String,
        durationSeconds: Double,
        watches: [SPKNotificationWatch],
        events: [SPKNotificationEvent]
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.watches = watches
        self.events = events
    }
}

public enum SPKNotificationObserver {
    public static func observe(
        darwinNames: [String],
        distributedNames: [String],
        durationSeconds: Double
    ) -> SPKNotificationObservationResult {
        let recorder = SPKNotificationEventRecorder()
        let startedAt = Date()
        var watches: [SPKNotificationWatch] = []
        var darwinTokens: [Int32] = []
        var darwinContexts: [Unmanaged<SPKDarwinNotifyContext>] = []
        var distributedReceivers: [SPKDistributedNotificationReceiver] = []
        let darwinQueue = DispatchQueue(label: "SPKNotificationObserver.darwin")
        let distributedCenter = DistributedNotificationCenter.default()

        for name in darwinNames {
            var token: Int32 = 0
            let context = Unmanaged.passRetained(
                SPKDarwinNotifyContext(name: name, recorder: recorder)
            )
            let status = SPKNotifyRegisterDispatch(
                name,
                &token,
                darwinQueue,
                { _, context in
                    guard let context else {
                        return
                    }
                    let value = Unmanaged<SPKDarwinNotifyContext>
                        .fromOpaque(context)
                        .takeUnretainedValue()
                    value.recorder.record(
                        mechanism: .darwinNotify,
                        name: value.name,
                        payloadKeyCount: nil
                    )
                },
                context.toOpaque()
            )

            if status == SPKNotifyStatusOK() {
                darwinTokens.append(token)
                darwinContexts.append(context)
                watches.append(
                    SPKNotificationWatch(
                        mechanism: .darwinNotify,
                        name: name,
                        registered: true,
                        error: nil
                    )
                )
            } else {
                context.release()
                watches.append(
                    SPKNotificationWatch(
                        mechanism: .darwinNotify,
                        name: name,
                        registered: false,
                        error: "notify_register_dispatch returned status \(status)"
                    )
                )
            }
        }

        for name in distributedNames {
            let receiver = SPKDistributedNotificationReceiver(
                recorder: recorder
            )
            distributedCenter.addObserver(
                receiver,
                selector: #selector(SPKDistributedNotificationReceiver.receive(_:)),
                name: Notification.Name(name),
                object: nil,
                suspensionBehavior: .deliverImmediately
            )
            distributedReceivers.append(receiver)
            watches.append(
                SPKNotificationWatch(
                    mechanism: .distributedNotificationCenter,
                    name: name,
                    registered: true,
                    error: nil
                )
            )
        }

        RunLoop.current.run(until: startedAt.addingTimeInterval(durationSeconds))

        for token in darwinTokens {
            SPKNotifyCancel(token)
        }
        darwinQueue.sync {}
        for context in darwinContexts {
            context.release()
        }
        for receiver in distributedReceivers {
            distributedCenter.removeObserver(receiver)
        }

        let endedAt = Date()
        return SPKNotificationObservationResult(
            startedAt: startedAt.ISO8601Format(),
            endedAt: endedAt.ISO8601Format(),
            durationSeconds: durationSeconds,
            watches: watches,
            events: recorder.snapshot()
        )
    }
}

private final class SPKDistributedNotificationReceiver: NSObject {
    let recorder: SPKNotificationEventRecorder

    init(recorder: SPKNotificationEventRecorder) {
        self.recorder = recorder
    }

    @objc
    func receive(_ notification: Notification) {
        recorder.record(
            mechanism: .distributedNotificationCenter,
            name: notification.name.rawValue,
            payloadKeyCount: notification.userInfo?.keys.count
        )
    }
}

private final class SPKDarwinNotifyContext: @unchecked Sendable {
    let name: String
    let recorder: SPKNotificationEventRecorder

    init(name: String, recorder: SPKNotificationEventRecorder) {
        self.name = name
        self.recorder = recorder
    }
}

private final class SPKNotificationEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [SPKNotificationEvent] = []

    func record(
        mechanism: SPKNotificationMechanism,
        name: String,
        payloadKeyCount: Int?
    ) {
        let event = SPKNotificationEvent(
            mechanism: mechanism,
            name: name,
            observedAt: Date().ISO8601Format(),
            payloadKeyCount: payloadKeyCount
        )
        lock.withLock {
            events.append(event)
        }
    }

    func snapshot() -> [SPKNotificationEvent] {
        lock.withLock {
            events
        }
    }
}
