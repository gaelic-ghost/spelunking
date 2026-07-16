# Messages Experiments

## Read-Only Experiments

- [x] Verify app path and bundle metadata.
- [x] Capture app extension, plugin, URL, AppleScript, and intent surfaces.
- [x] Dump AppleScript dictionary.
- [x] Inventory `chat.db` tables and columns without row data.
- [x] Capture `chat.db` schema, indexes, and triggers without row data.
- [x] Capture app entitlements.
- [x] Capture app binary linked libraries.
- [x] Skim SDK `.tbd` metadata for `IMCore`.
- [x] Run a filtered dyld shared cache export probe.
- [x] Inventory launchd jobs and XPC service plists.
- [x] Read public iPhoneOS SDK headers for Messages, MessageUI, and Shared With You.
- [x] Demangle private SDK `.tbd` Swift symbols for IMCore import/export families.
- [x] Capture private SDK notification constant families.
- [x] Capture read-only Objective-C runtime metadata for IM private frameworks with `spelunk objc-runtime`.
- [x] First-pass classify notification delivery mechanisms from launchd and SDK symbol evidence.
- [x] Generate first-pass class/protocol/selector inventory for `IMDPersistence`, `IMDaemonCore`, and `MessagesKit`.
- [x] Capture bounded default-level log stream while opening Messages.
- [x] Probe root URL schemes without recipients or message payloads.
- [x] Resolve first-pass runtime string values for selected IMCore and IMDPersistence notification constants.
- [ ] Extract live dyld shared cache images for full IM private framework metadata.
- [ ] Observe notification delivery with controlled read-only observers or log predicates.
- [ ] Attach read-only logging predicates while manually using Messages.

## Mutating Experiments

Run only after read-only baselines are committed and a specific question needs mutation.

- [ ] Use AppleScript `send` to a controlled test recipient or local test chat.
- [ ] Create a controlled test attachment send.
- [ ] Exercise payload-bearing `sms:` and `imessage:` URL handling with controlled non-sensitive test recipients.
- [ ] Trigger a scheduled message in a controlled test chat.

## Experiment Template

### Name

Status: planned

Command:

```sh

```

Expected behavior:

Observed behavior:

Permissions, entitlements, or SIP notes:

Follow-up:

## Privacy Rules For This Target

- Do not capture message text, addresses, participant names, attachment file names, or row-level data unless Gale explicitly asks for that controlled evidence.
- Prefer schema, symbol, entitlement, command, and interface evidence.
- If a runtime experiment needs a real message, use an intentionally created test thread and label that fact in the evidence.
