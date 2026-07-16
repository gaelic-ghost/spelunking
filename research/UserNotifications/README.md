# UserNotifications Research Evidence

## Scope

Raw evidence for the macOS desktop-notification accessibility research lane. This target is read-only: it studies the Notification Center UI tree and accessibility notifications without invoking AX actions, dismissing notifications, or changing user notification state.

## Environment

- Active OS: macOS 26.5.2 (25F84).
- Toolchain: Xcode 27.0 (27A5218g).
- Notification Center bundle identifier: `com.apple.notificationcenterui`.

## Evidence Commands

Run from the repository root:

```sh
sw_vers
xcodebuild -version
ps -axo pid=,comm= | rg -i 'notification|usernot|controlcenter|systemui'
swift run spelunk notifications --max-depth 6
```

The probe reports whether the host has Accessibility trust, the active Notification Center PID, supported or rejected AX observer registrations, and a depth-limited snapshot of accessible strings and children.

See [the initial runtime inventory](2026-07-16-runtime-inventory.md) for the captured process, launch, linkage, and private-export evidence.

## Interpretation Rules

- Treat successful AX observer registration as a verified capability for this OS and process only.
- Treat field names and values in a captured tree as verified only for that captured UI state.
- Treat absent strings as ambiguous: notification preview settings, Focus, grouping, or a changed UI hierarchy may explain them.
- Do not infer a durable cross-app notification database or API from this UI-level evidence.
- Treat launchd Mach-service names and private binary exports as routing or implementation evidence only. They are not approved client APIs.

## Capture Hygiene

Probe output can contain personal notification content. Keep unredacted captures local and out of Git. Promote only redacted structural observations into `docs/frameworks/UserNotifications/`.
