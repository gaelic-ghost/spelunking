# Messages Experiments

## Read-Only Experiments

- [x] Verify app path and bundle metadata.
- [x] Dump AppleScript dictionary.
- [x] Inventory `chat.db` tables and columns without row data.
- [x] Capture app entitlements.
- [x] Capture app binary linked libraries.
- [x] Skim SDK `.tbd` metadata for `IMCore`.
- [ ] Extract live dyld shared cache symbols for IM private frameworks.
- [ ] Generate class/protocol/selector inventory.
- [ ] Observe notification names without sending messages.
- [ ] Attach read-only logging predicates while manually using Messages.
- [ ] Inspect launchd jobs and XPC service plists.

## Mutating Experiments

Run only after read-only baselines are committed and a specific question needs mutation.

- [ ] Use AppleScript `send` to a controlled test recipient or local test chat.
- [ ] Create a controlled test attachment send.
- [ ] Exercise `sms:` and `imessage:` URL handling.
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

