# 2026-07-16 Runtime Inventory

## Environment

- macOS 26.5.2 (25F84)
- Xcode 27.0 (27A5218g)
- User session: the active console user

## Verified Processes

The following relevant processes were running when captured:

| Process | PID | Evidence | Interpretation |
| --- | ---: | --- | --- |
| `NotificationCenter.app` | 702 | `ps` | User-interface host for Notification Center. |
| `usernoted` | 692 | `ps`, launchd | Per-user notification daemon. |
| `usernotificationsd` | 658 | `ps` | Support daemon inside `UserNotificationsCore.framework`. |
| `ControlCenter.app` | 606 | `ps` | Adjacent system UI surface; not established as a notification-content source. |
| `SystemUIServer` | 607 | `ps` | Adjacent system UI surface; not established as a notification-content source. |

## Verified Accessibility Probe

The depth-zero read-only probe was run against the active Notification Center process. Accessibility trust was available. The probe found PID 702 and reported success for all of the following process-level registrations:

- `AXWindowCreated`
- `AXFocusedWindowChanged`
- `AXTitleChanged`
- `AXValueChanged`
- `AXUIElementDestroyed`

The root element reported role `AXApplication` and title `Notification Center`; depth zero returned no children. This verifies observer-registration capability only. It does not establish which callbacks fire for a real banner or persisted notification card, nor which content fields those UI states expose.

## Verified Launch Surfaces

`/System/Library/LaunchAgents/com.apple.notificationcenterui.plist` defines the persistent user agent `com.apple.notificationcenterui.agent`. Its declared Mach services are:

- `com.apple.notificationcenterui.customalerts`
- `com.apple.notificationcenterui.main`
- `com.apple.notificationcenterui.menu`
- `com.apple.notificationcenterui.nctool`
- `com.apple.notificationcenterui.pip`
- `com.apple.notificationcenterui.siri`
- `com.apple.widget-observation`

`/System/Library/LaunchAgents/com.apple.usernoted.plist` defines the persistent per-user daemon `com.apple.usernoted`. Its declared Mach services include:

- `com.apple.usernoted.client`
- `com.apple.usernoted.daemon_client`
- `com.apple.usernoted.dock`
- `com.apple.usernoted.events`
- `com.apple.usernoted.multi_client`
- `com.apple.usernoted.notificationcenter`
- `com.apple.usernoted.prefs`
- `com.apple.usernoted.push`
- `com.apple.usernotifications.remotenotificationservice`
- `com.apple.usernotifications.usernotificationservice`

`/System/Library/LaunchDaemons/com.apple.UserNotificationCenter.plist` declares `com.apple.UNCUserNotification`, hosted by `/System/Library/CoreServices/uncd`.

These names establish routing surfaces only. No client protocol, caller authorization, entitlement requirement, or safe read-only behavior has been verified. Do not connect to them from research tools without a separately scoped experiment.

## Framework and Linkage Evidence

The active system contains public `UserNotifications.framework`, `UserNotificationsUI.framework`, and `Accessibility.framework`, plus private `NotificationCenterUI.framework`, `UserNotificationsCore.framework`, `UserNotificationsKit.framework`, `UserNotificationsServices.framework`, and `UserNotificationsSettings.framework`.

`NotificationCenter.app` directly links `UserNotifications.framework`, `UserNotificationsUI.framework`, `UserNotificationsCore.framework`, `UserNotificationsKit.framework`, `UserNotificationsServices.framework`, `NotificationPreferences.framework`, and `DoNotDisturb.framework`. This establishes an implementation relationship, not a supported integration contract.

The active macOS 27 beta SDK headers retain legacy `NSUserNotificationCenter` and `NSUserNotification`, marking their delegate APIs deprecated since macOS 11 and directing callers to UserNotifications. The same SDK header for `NSDistributedNotificationCenter` warns that it does not implement secure communication; payloads are untrusted input.

## Private Export Evidence

`xcrun dyld_info -exports` exposed private `UserNotificationsCore` symbols whose demangled names include `NotificationCenterServiceClient`, `notificationRecords(forBundleIdentifier:)`, `allBundleIdentifiersForBadges()`, `save`, `removeAllNotificationRecords`, and `performAction`. `UserNotificationsKit` exports include `NCNotificationSourceCategorizer` and `eligibleForSummarization`.

This is inference from private binary exports. It indicates that Apple has internal record, source-categorization, summarization, and action surfaces. It does not prove that an ordinary user process can call them, obtain cross-app data, or do so while preserving SIP-enabled and read-only constraints.

## Repeatable Commands

```sh
sw_vers
xcodebuild -version
ps -axo pid=,ppid=,user=,comm= | rg -i 'notification|usernot|controlcenter|systemui'
plutil -p /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
plutil -p /System/Library/LaunchAgents/com.apple.usernoted.plist
plutil -p /System/Library/LaunchDaemons/com.apple.UserNotificationCenter.plist
otool -L /System/Library/CoreServices/NotificationCenter.app/Contents/MacOS/NotificationCenter
xcrun dyld_info -exports /System/Library/PrivateFrameworks/UserNotificationsCore.framework/UserNotificationsCore
```
