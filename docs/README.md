# Documentation

This directory holds durable writeups promoted from raw research.

Use `docs/frameworks/<Name>/` for framework, daemon, service, and subsystem writeups. Keep raw dumps, generated headers, command transcripts, and scratch notes under `research/<Name>/` until they are cleaned up enough to be useful later.

Cross-target status:

- [Messages and Phone research status](frameworks/messages-phone-status.md)

## Target Directory

| Target | Status | Start Here | Safest First Command |
| --- | --- | --- | --- |
| MediaRemote | Baseline in progress | [MediaRemote overview](frameworks/MediaRemote/README.md) | `swift run mr-now-playing-probe` |
| Messages | Read-only baseline established | [Messages overview](frameworks/Messages/README.md) | `swift run spelunk targets` |
| Phone | Read-only baseline established | [Phone overview](frameworks/Phone/README.md) | `swift run spelunk targets` |
| UserNotifications | Read-only baseline established | [UserNotifications overview](frameworks/UserNotifications/README.md) | `swift run spelunk notifications --max-depth 6` |

The commands above do not intentionally mutate media, message, call, notification, account, or system-service state. Some probes still load private frameworks, contact system daemons, or inspect Accessibility surfaces. Read the target overview for OS, permission, privacy, and runtime boundaries before collecting evidence.

Each target writeup should include:

- scope
- environment
- evidence inventory
- types and symbols
- interesting functions and signatures
- hooks, notifications, callbacks, XPC, and daemon edges
- permissions, entitlements, sandbox, and SIP notes
- experiments
- open questions
- references
