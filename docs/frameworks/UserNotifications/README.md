# UserNotifications and Notification Center Accessibility

## Scope

This is the macOS 26.5.2 research map for desktop notifications and Notification Center. It prioritizes useful userland hooks that retain SIP, are read-only, and respect the user-visible privacy model. Private implementation surfaces are catalogued for orientation but are not recommended integration points.

## Environment

- Active OS: macOS 26.5.2 (25F84).
- SDK/toolchain: Xcode 27.0 (27A5218g).
- Notification Center UI host: `NotificationCenter.app`, bundle identifier `com.apple.notificationcenterui`.
- Detailed local evidence: [runtime inventory](../../../research/UserNotifications/2026-07-16-runtime-inventory.md).

## Surface Map

| Surface | Content scope | Permission boundary | SIP-enabled, read-only suitability | Status |
| --- | --- | --- | --- | --- |
| `UNUserNotificationCenter` | Calling app only | Per-app notification authorization | Yes, but not cross-app | Verified public API boundary |
| App-owned notification delegates and extensions | Calling app's notifications only | App extension lifecycle and notification authorization | Yes, but not cross-app | Verified public API boundary |
| `NSUserNotificationCenter` | Calling app only | Legacy Foundation API | Avoid for new work | Verified present in SDK and deprecated since macOS 11 |
| Accessibility tree for `NotificationCenter.app` | Whatever macOS visibly exposes | User-granted Accessibility trust | Yes; primary cross-app research hook | Verified API, per-UI-state content still needs capture |
| `NSDistributedNotificationCenter` | Posted distributed messages, not a notification inbox | Sender must post a known message | Yes, but no system notification-content contract | Verified public API; unsuitable as a general hook |
| `NSWorkspace` process observation | Process lifecycle and PID discovery | None for ordinary process observation | Yes | Public supporting surface |
| Screen capture plus OCR | Pixels only | Screen Recording | Possible fallback, but not semantic and not preferred | Not implemented |
| Unified logging | Diagnostics only; payloads may be absent or redacted | Log privacy controls | Not a content hook | Not used by this research |
| `usernoted` Mach services | Unknown internal payloads | Unknown caller checks and possible entitlements | No supported basis | Local routing evidence only |
| Private UserNotifications frameworks | Potential records, sources, actions | Private contract and unknown authorization | Private-only research lane | Inferred from linkage and exports |

## Public API Boundary

[`UNUserNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) is the central object for notification behavior **for the calling app**. Its [delivered-notification query](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getdeliverednotifications(completionhandler:)) returns that app's local and remote notifications still visible in Notification Center; its [pending-request query](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getpendingnotificationrequests(completionhandler:)) returns that app's scheduled local requests. Neither is a system-wide inbox.

An app needs its own notification authorization to display alerts, sounds, or badges through [requestAuthorization](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)). That authorization does not grant access to other apps' notification payloads.

`UNUserNotificationCenterDelegate` receives delivery and response callbacks for the owning app. A [notification service extension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension) can receive and alter its app's incoming notification request before delivery, while a [notification content extension](https://developer.apple.com/documentation/usernotificationsui/unnotificationcontentextension) customizes and responds within that app's notification UI. These are useful ownership-scoped hooks, not interception points for another app's notifications.

The macOS SDK still includes `NSUserNotificationCenter`, `NSUserNotification`, and its delegate methods, but marks the API deprecated since macOS 11 and directs new work to UserNotifications. Its scheduled and delivered lists are likewise the current application's tracked notifications, so it does not widen cross-app visibility.

[`DistributedNotificationCenter`](https://developer.apple.com/documentation/foundation/distributednotificationcenter) can subscribe to interprocess notifications with an optional name and sender. Apple documents it as a generic dispatch mechanism; there is no public contract that maps desktop-notification delivery or content onto distributed notifications. Do not use wildcard distributed observation as a notification-content collector.

The active SDK header also warns that distributed notifications do not provide secure communication. Treat any distributed payload as untrusted even in an experiment where a known notification name is appropriate.

## Accessibility Hook

Accessibility is the primary SIP-enabled, user-consented research hook for arbitrary notifications **only to the extent that their UI is exposed**. The supported path is:

1. Find the live `com.apple.notificationcenterui` PID with `NSRunningApplication` or `NSWorkspace`.
2. Create an `AXUIElement` for that process.
3. Verify trust using [AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/axisprocesstrustedwithoptions(_:)). The included probe deliberately uses the non-prompting check.
4. Snapshot accessible role, subrole, title, description, value, identifier, and child elements.
5. Attempt `AXObserver` registrations and treat `notificationUnsupported` as evidence, not an implementation failure. Apple documents [AXObserverAddNotification](https://developer.apple.com/documentation/applicationservices/axobserveraddnotification(_:_:_:_:)) as object-specific and explicitly notes that the system-wide AX element cannot be observed.

Run the existing read-only capability probe:

```sh
swift run spelunk notifications --max-depth 6
```

The command never invokes an AX action. It does not click, clear, dismiss, activate, or modify notifications. Its output can contain notification text, so retain only redacted captures.

### Verified Initial Result

On the active macOS 26.5.2 session, a depth-zero probe located Notification Center PID 702, read its root as `AXApplication` titled `Notification Center`, and successfully registered all five initial process-level AX notifications: `AXWindowCreated`, `AXFocusedWindowChanged`, `AXTitleChanged`, `AXValueChanged`, and `AXUIElementDestroyed`. This proves the event-registration hook is available. It does not yet prove which event fires for a specific visible notification or what a deeper card subtree contains.

### Expected Limits

- A banner or card must exist long enough to inspect it.
- Hidden previews, Focus, grouping, notification summaries, and per-app settings may change or suppress exposed text.
- AX roles, hierarchy, identifiers, and supported events are implementation details that must be sampled per macOS release.
- Accessibility authorization is separate from an app's own notification authorization.

## Runtime Topology

The initial local capture verified these roles:

| Agent or process | Scope | Direct evidence | Useful research surface | Read-only standing |
| --- | --- | --- | --- | --- |
| `NotificationCenter.app` | Per-user UI | Running process and launch-agent plist | Accessibility process, AX tree, AX observer | Primary supported hook after Accessibility consent |
| `usernoted` | Per-user daemon | Running process and launch-agent plist | Service-name inventory only | Do not connect without a separate private protocol experiment |
| `usernotificationsd` | Support daemon | Running process under `UserNotificationsCore.framework` | Linkage and binary-export research | No public client contract established |
| `uncd` | System daemon | LaunchDaemon and `com.apple.UNCUserNotification` service | Service-name inventory only | No public client contract established |
| `ControlCenter.app` / `SystemUIServer` | Adjacent UI | Running processes | Compare AX topology only if an experiment shows notification ownership | Not a confirmed notification-content source |

This shows that the stack is multi-process and includes private protocol boundaries. It does **not** show that `usernoted` or `uncd` accept arbitrary third-party read clients.

## Messages and Private Services

The documented, userland-safe messages are AX observer callbacks for the AX object and app-owned UserNotifications delegate callbacks. The local launch definitions also expose internal Mach service names such as `com.apple.usernoted.events` and `com.apple.usernoted.notificationcenter`; these are not public message formats or client APIs.

Avoid blindly connecting to internal service names. Doing so would leave the read-only boundary, has unknown authorization behavior, and produces brittle version-specific tooling. Any future private-protocol work belongs in a separately approved experiment with a no-mutation capture plan.

System logging is useful for debugging a notification experiment only when a specific subsystem emits relevant data. It is not a dependable payload feed: privacy redaction and implementation changes mean absence or truncation is expected. This research does not rely on logs to recover notification content.

## Private Framework Notes

Local linkage and shared-cache exports establish that the following private frameworks participate in the stack:

| Framework | Verified evidence | Inference or use boundary |
| --- | --- | --- |
| `NotificationCenterUI` | Installed locally; linked by the UI host | Presentation implementation; no documented cross-app reader |
| `UserNotificationsCore` | Installed locally; linked by UI host and support daemon; record/action exports visible | Internal repository/client model; private-only lane |
| `UserNotificationsKit` | Installed locally; linked by UI host; source and summarization exports visible | Settings and source-categorization implementation; private-only lane |
| `UserNotificationsServices` | Installed locally; linked by UI host and support daemon | Service-layer implementation; private-only lane |
| `UserNotificationsSettings` | Installed locally; linked by support daemon | Settings implementation; private-only lane |
| `NotificationPreferences` | Linked by UI host | Preference implementation; private-only lane |
| `DoNotDisturb` | Linked by UI host | Focus-related implementation; private-only lane |

The export names indicate internal record lookup, bundle identifier enumeration, action dispatch, notification source categorization, and summarization eligibility. This is **inference**, not an endorsement or verified call path. No private function is used by the package, and no claim is made that these surfaces work without entitlement checks or are safe under SIP-enabled ordinary userland.

## Experiments

### Read-only AX tree capture

1. Arrange a notification whose content you may retain for research.
2. Ensure the terminal or host process has Accessibility trust.
3. Run `swift run spelunk notifications --max-depth 6`.
4. Redact message content, then record the structural fields and process-level observer results.

### Banner versus persisted card

1. Capture once while a transient banner is visible.
2. Capture again with the same notification in Notification Center.
3. Compare roles, identifiers, title/description/value fields, and child ordering.
4. Treat differences as UI-state-specific until repeated.

### Observer capability matrix

The current probe attempts window-created, focused-window-changed, title-changed, value-changed, and element-destroyed registrations. Run it in each UI state above and retain only its registration-result fields when a content-free capture is required.

## Open Questions

- Which process-level AX events are accepted by Notification Center on macOS 26.5.2?
- Which AX subtree corresponds to a transient banner versus a persisted notification card?
- Do grouped notifications expose their summary and individual message text as distinct accessible elements?
- How do hidden-preview and Focus settings alter exposed text?
- Which internal service requests are read-only, and what caller checks protect them? This is deliberately not tested in the SIP-enabled public lane.

## References

- Apple, [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
- Apple, [getDeliveredNotifications](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getdeliverednotifications(completionhandler:))
- Apple, [requestAuthorization](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:))
- Apple, [DistributedNotificationCenter](https://developer.apple.com/documentation/foundation/distributednotificationcenter)
- Apple, [AXObserverAddNotification](https://developer.apple.com/documentation/applicationservices/axobserveraddnotification(_:_:_:_:))
- Apple, [AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/axisprocesstrustedwithoptions(_:))
