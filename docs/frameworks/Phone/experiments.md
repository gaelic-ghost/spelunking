# Phone Experiments

## Read-Only Experiments

- [x] Verify app path and bundle metadata.
- [x] Capture app extension, plugin, URL, AppleScript, and intent surfaces.
- [x] Confirm absence of an AppleScript dictionary.
- [x] Capture app entitlements.
- [x] Capture app binary linked libraries.
- [x] Skim SDK `.tbd` metadata for `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`.
- [x] Run a filtered dyld shared cache export probe.
- [x] Inventory launchd jobs and XPC service plists.
- [x] Locate and inventory call-history storage schema without row data.
- [x] Capture call-history schema and indexes without row data.
- [x] Capture call-history relationship/index/trigger boundary metadata without row data.
- [x] Read public SDK headers/interfaces for CallKit and LiveCommunicationKit.
- [x] Demangle private SDK `.tbd` Swift symbols for PhoneAppIntents, CallsXPC, CallsPersistence, and TelephonyUtilities.
- [x] Capture private SDK notification constant families.
- [x] Capture read-only Objective-C runtime metadata for CallHistory, TelephonyUtilities, and CallKit with `spelunk objc-runtime`.
- [x] First-pass classify notification delivery mechanisms from launchd and SDK symbol evidence.
- [x] Generate first-pass class/protocol/selector inventory for `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`.
- [x] Capture bounded default-level log stream while opening Phone.
- [x] Probe root URL schemes without phone numbers, voicemail IDs, or call targets.
- [x] Resolve first-pass runtime string values for selected TelephonyUtilities and CallHistory notification constants.
- [x] Capture a bounded app-open notification observer baseline without payload values.
- [ ] Extract live dyld shared cache images for full call private framework metadata.
- [ ] Observe notification delivery with controlled read-only observers or log predicates.
- [ ] Attach read-only logging predicates while manually opening Phone.

## Mutating Experiments

Run only after read-only baselines are committed and a specific question needs mutation.

- [ ] Exercise payload-bearing `tel:` URL handling with a non-dialing or canceled flow.
- [ ] Exercise payload-bearing `phoneapp:` or `vmshow:` URL handling in a controlled visible session.
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
