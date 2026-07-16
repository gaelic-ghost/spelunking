# Phone Experiments

## Read-Only Experiments

- [x] Verify app path and bundle metadata.
- [x] Confirm absence of an AppleScript dictionary.
- [x] Capture app entitlements.
- [x] Capture app binary linked libraries.
- [x] Skim SDK `.tbd` metadata for `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`.
- [ ] Locate and inventory call-history storage schema without row data.
- [ ] Extract live dyld shared cache symbols for call private frameworks.
- [ ] Generate class/protocol/selector inventory.
- [ ] Observe notification names without placing calls.
- [ ] Attach read-only logging predicates while manually opening Phone.
- [ ] Inspect launchd jobs and XPC service plists.

## Mutating Experiments

Run only after read-only baselines are committed and a specific question needs mutation.

- [ ] Exercise `tel:` URL handling with a non-dialing or canceled flow.
- [ ] Exercise `phoneapp:` or `vmshow:` URL handling in a controlled visible session.
- [ ] Place a controlled test call only with explicit approval.
- [ ] Trigger voicemail or call-record UI paths only with explicit approval.

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

- Do not capture call records, phone numbers, voicemail metadata, contacts, participant names, or row-level data unless Gale explicitly asks for that controlled evidence.
- Prefer schema, symbol, entitlement, command, and interface evidence.
- If a runtime experiment needs a real call, use an intentionally controlled test call and label that fact in the evidence.

