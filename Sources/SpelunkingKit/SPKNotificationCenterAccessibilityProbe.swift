import AppKit
import ApplicationServices
import Foundation

/// Read-only accessibility inspection for the system Notification Center process.
///
/// The probe never performs an accessibility action or writes notification state.
public struct SPKNotificationCenterAccessibilityProbe: Sendable {
    public static let notificationCenterBundleIdentifier = "com.apple.notificationcenterui"

    public init() {}

    public func inspect(maximumDepth: Int = 6) -> SPKNotificationCenterAccessibilityProbeResult {
        guard AXIsProcessTrusted() else {
            return .accessibilityNotTrusted
        }

        guard let application = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.notificationCenterBundleIdentifier)
            .first else {
            return .notificationCenterNotRunning
        }

        let root = AXUIElementCreateApplication(application.processIdentifier)
        return .success(
            processIdentifier: application.processIdentifier,
            observerRegistrations: observerRegistrations(for: root, processIdentifier: application.processIdentifier),
            rootElement: snapshot(of: root, depth: 0, maximumDepth: max(0, maximumDepth))
        )
    }
}

public enum SPKNotificationCenterAccessibilityProbeResult: Encodable, Sendable {
    case accessibilityNotTrusted
    case notificationCenterNotRunning
    case success(
        processIdentifier: pid_t,
        observerRegistrations: [SPKAccessibilityObserverRegistration],
        rootElement: SPKAccessibilityElementSnapshot
    )

    private enum CodingKeys: String, CodingKey {
        case status
        case message
        case processIdentifier
        case observerRegistrations
        case rootElement
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .accessibilityNotTrusted:
            try container.encode("accessibility-not-trusted", forKey: .status)
            try container.encode(
                "Accessibility permission is not granted. Enable the command-line host in System Settings > Privacy & Security > Accessibility, then rerun the probe.",
                forKey: .message
            )
        case .notificationCenterNotRunning:
            try container.encode("notification-center-not-running", forKey: .status)
            try container.encode(
                "NotificationCenter.app is not running in this user session, so there is no accessibility tree to inspect.",
                forKey: .message
            )
        case let .success(processIdentifier, observerRegistrations, rootElement):
            try container.encode("ok", forKey: .status)
            try container.encode(processIdentifier, forKey: .processIdentifier)
            try container.encode(observerRegistrations, forKey: .observerRegistrations)
            try container.encode(rootElement, forKey: .rootElement)
        }
    }
}

public struct SPKAccessibilityObserverRegistration: Encodable, Sendable {
    public let notification: String
    public let result: String

    init(notification: String, result: AXError) {
        self.notification = notification
        self.result = result == .success ? "success" : String(describing: result)
    }
}

public struct SPKAccessibilityElementSnapshot: Encodable, Sendable {
    public let role: String?
    public let subrole: String?
    public let title: String?
    public let description: String?
    public let value: String?
    public let identifier: String?
    public let children: [SPKAccessibilityElementSnapshot]
}

private extension SPKNotificationCenterAccessibilityProbe {
    func observerRegistrations(
        for root: AXUIElement,
        processIdentifier: pid_t
    ) -> [SPKAccessibilityObserverRegistration] {
        var observer: AXObserver?
        let creationResult = AXObserverCreate(processIdentifier, { _, _, _, _ in }, &observer)

        guard creationResult == .success, let observer else {
            return [SPKAccessibilityObserverRegistration(notification: "AXObserverCreate", result: creationResult)]
        }

        let notifications: [String] = [
            kAXWindowCreatedNotification,
            kAXFocusedWindowChangedNotification,
            kAXTitleChangedNotification,
            kAXValueChangedNotification,
            kAXUIElementDestroyedNotification
        ]

        return notifications.map { notification in
            SPKAccessibilityObserverRegistration(
                notification: notification,
                result: AXObserverAddNotification(observer, root, notification as CFString, nil)
            )
        }
    }

    func snapshot(
        of element: AXUIElement,
        depth: Int,
        maximumDepth: Int
    ) -> SPKAccessibilityElementSnapshot {
        let children: [SPKAccessibilityElementSnapshot]
        if depth < maximumDepth {
            children = childElements(of: element).map {
                snapshot(of: $0, depth: depth + 1, maximumDepth: maximumDepth)
            }
        } else {
            children = []
        }

        return SPKAccessibilityElementSnapshot(
            role: stringAttribute(kAXRoleAttribute, of: element),
            subrole: stringAttribute(kAXSubroleAttribute, of: element),
            title: stringAttribute(kAXTitleAttribute, of: element),
            description: stringAttribute(kAXDescriptionAttribute, of: element),
            value: stringAttribute(kAXValueAttribute, of: element),
            identifier: stringAttribute(kAXIdentifierAttribute, of: element),
            children: children
        )
    }

    func childElements(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
              let children = value as? [AXUIElement] else {
            return []
        }
        return children
    }

    func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }
}
