# Phone Symbols

## App Binary Dependencies

Verified with:

```sh
otool -L /System/Applications/Phone.app/Contents/MacOS/Phone
```

High-signal linked libraries:

- `/System/iOSSupport/System/Library/PrivateFrameworks/PhoneKit.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsAppUI.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsAppServices.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsDialer.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsSearch.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/FaceTimeMac.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/FaceTimeAuthentication.framework`
- `/System/Library/PrivateFrameworks/FaceTimeMacHelperCore.framework`
- `/System/Library/PrivateFrameworks/FaceTimeDockSupport.framework`
- `/System/Library/PrivateFrameworks/CallHistory.framework`
- `/System/Library/PrivateFrameworks/FaceTimeMessageStore.framework`
- `/System/Library/PrivateFrameworks/IDS.framework`
- `/System/Library/PrivateFrameworks/TelephonyUtilities.framework`
- `/System/Library/Frameworks/LiveCommunicationKit.framework`

Inference: `Phone.app` is not only a dialer. It is a Swift/UIKit app layered over FaceTime, Calls, IDS, TelephonyUtilities, CallHistory, LiveCommunicationKit, Contacts, and ConversationKit surfaces.

## Framework Availability Notes

Framework directories exist for `CallsXPC`, `CallsPersistence`, and `TelephonyUtilities`, but direct root Mach-O paths were not present for several active private frameworks on this machine.

Use one of these next:

- dyld shared cache extraction for live macOS symbols
- SDK `.tbd` files for exported symbol names
- generated Swift interfaces when available
- runtime class listing from a small read-only helper

## SDK `.tbd` Highlights

### CallsXPC

Verified from `MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsXPC.framework/CallsXPC.tbd`.

Observed exported Swift families:

- `XPCMessage`
- `XPCInterface`
- `XPCIdentity`
- `XPCMessages`
- typed payload decoder maps
- result/error wrappers
- client and host message groups

Inference: `CallsXPC` provides a typed Swift message layer for call-service communication.

### CallsPersistence

Verified from `MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsPersistence.framework/CallsPersistence.tbd`.

Observed exported Swift families:

- `DataStoreWrapper`
- `DataStoreWrapperError`
- `DataStoreWrapperDelegate`
- `Syncable`
- `SyncableEntity`
- fetch/save/update/delete and persistent-history error cases

Inference: `CallsPersistence` wraps a Core Data or Core Data-like persistence layer for call records/messages and syncable call entities.

### PhoneAppIntents

Verified from `MacOSX27.0.sdk/System/Library/PrivateFrameworks/PhoneAppIntents.framework/PhoneAppIntents.tbd`.

Observed exported Swift families:

- `PhonePerson`
- `CallRecord`
- `CallMessage`
- `CallAVMode`
- `CallStatus`
- transient/persistent App Intents entity conformances
- dynamic entity queries
- display representations and transfer representations

High-signal model fields visible in symbol names:

- `CallRecord.id`
- `CallRecord.date`
- `CallRecord.type`
- `CallRecord.duration`
- `CallRecord.provider`
- `CallRecord.audioVisualMode`
- `CallRecord.remoteParticipants`
- `CallMessage.callRecord`
- `CallStatus.active`
- `CallStatus.ringing`
- `CallStatus.sending`
- `CallStatus.onHold`
- `CallStatus.disconnecting`
- `CallStatus.disconnected`
- `CallStatus.unknown`
- `CallAVMode.audio`
- `CallAVMode.video`

## Constants And Notifications

Not yet captured from live runtime.

Planned sources:

- strings and Objective-C metadata from dyld-cache extracted private frameworks
- `notifyutil -l` filtered for Phone, Calls, TelephonyUtilities, and FaceTime identifiers
- log stream predicates for call-service subsystem names
- generated headers or Swift interfaces

## Version Differences

Known first-pass difference:

- The active macOS 26.5.2 private framework directories often lack direct root binaries.
- The macOS 27.0 SDK exposes `.tbd` symbol metadata for private frameworks including `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`.

No semantic symbol diff has been performed yet.

