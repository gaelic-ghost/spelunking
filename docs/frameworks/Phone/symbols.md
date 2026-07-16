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

Framework directories exist for `CallsXPC`, `CallsPersistence`, and `TelephonyUtilities`. Many root Mach-O paths are dyld-cache install names rather than ordinary on-disk files; `dlopen` can still resolve some of them through the active dyld shared cache.

Use these sources together:

- dyld shared cache extraction for full live macOS symbols and Objective-C metadata
- SDK `.tbd` files for exported symbol names
- generated Swift interfaces when available
- runtime class listing from a small read-only helper

## Generated Interface Status

No generated private framework interfaces have been produced yet.

Raw capture:

- `research/Phone/runtime/dyld-cache-interface-boundary-macos-26.5.2.txt`

Local tool availability checked on 2026-07-16:

- `dyld_shared_cache_util`: not found on PATH or through `xcrun --find`
- `class-dump`: not found
- `class-dump-swift`: not found
- `swift-reflection-dump`: not found
- `jtool2`: not found
- available: `dyld_info`, `nm`, `otool`, `swift-api-digester`, and `swift-symbolgraph-extract`

Live dyld shared cache map entries confirmed these target images in the active arm64e shared cache:

- `/System/Library/PrivateFrameworks/TelephonyUtilities.framework/Versions/A/TelephonyUtilities`
- `/System/Library/PrivateFrameworks/CallHistory.framework/Versions/A/CallHistory`
- `/System/Library/PrivateFrameworks/CallsPersistence.framework/Versions/A/CallsPersistence`
- `/System/Library/PrivateFrameworks/CallsXPC.framework/Versions/A/CallsXPC`
- `/System/Library/PrivateFrameworks/PhoneAppIntents.framework/Versions/A/PhoneAppIntents`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsAppServices.framework/Versions/A/CallsAppServices`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsAppUI.framework/Versions/A/CallsAppUI`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsDialer.framework/Versions/A/CallsDialer`
- `/System/iOSSupport/System/Library/PrivateFrameworks/CallsSearch.framework/Versions/A/CallsSearch`
- `/System/iOSSupport/System/Library/PrivateFrameworks/PhoneKit.framework/Versions/A/PhoneKit`

SDK representation checked in the macOS 27.0 SDK:

- `CallsXPC.framework` exposes `CallsXPC.tbd`
- `CallsPersistence.framework` exposes `CallsPersistence.tbd`
- `PhoneAppIntents.framework` exposes `PhoneAppIntents.tbd`

No `.swiftinterface`, `.private.swiftinterface`, or `.swiftmodule` files were found for the selected Phone private frameworks in the checked macOS 27.0 SDK private framework directories or the active `/System/Library/PrivateFrameworks` directories.

Boundary: the current repository has live dyld-cache residency evidence, exported symbols, `.tbd` metadata, and Objective-C runtime metadata, but not full generated headers/interfaces for these private frameworks. The next interface-generation lane needs a dyld shared cache extractor, class-dump-capable Objective-C metadata path, or another equivalent metadata tool before the remaining checklist item can be closed.

## Objective-C Runtime Capture

Raw capture:

- `research/Phone/runtime/objc-runtime-callservices-macos-26.5.2.json`
- `research/Phone/runtime/objc-runtime-callsxpc-phoneintents-macos-26.5.2.json`

The runtime capture loaded `TelephonyUtilities`, `CallHistory`, and public `CallKit`. It attempted `CallHistoryDB`, but dyld reported that install name was not present as a file or in the dyld cache on this machine.

The `TU*`, `CH*`, `Call*`, `CX*`, and `Phone*` capture found:

- 439 matching classes
- 181 matching protocols

The `Calls*`, `CX*`, `CH*`, `Phone*`, and selected `TU*` capture loaded `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents` and found:

- 225 matching classes
- 97 matching protocols

Notable observed classes include:

- `CHManager`, `CHRecentCall`, `CHHandle`, `CHPersistentContainer`, `CHTransaction`
- `CallDBManager`, `CallDBManagerClient`, `CallDBManagerServer`, `CallHistoryDBHandle`
- `TUCall`, `TUCallCenter`, `TUCallProvider`, `TUCallServicesInterface`, `TUCallHistoryController`, `TUCallHistoryManager`
- `TUConversation`, `TUConversationManager`, `TUConversationProvider`, `TUConversationParticipant`
- `CXCall`, `CXCallController`, `CXProvider`, `CXTransaction`, `CXCallDirectoryManager`, `CXVoicemail`

Selector/property examples from the capture:

- `CHManager`: recent-call fetch/count/coalesce, read-state, deletion/reset, database-size, sync-transaction, and call-timer selectors
- `CHRecentCall`: call status/type/category, caller display fields, remote participant handles, emergency media, junk/verification/trust fields, duration/date, and message state
- `CHHandle`: normalized value, raw value, type, pseudonym, and temporary-handle checks
- `TU*`: live call, provider, conversation, call-history-controller, recording, translation, continuity, and collaboration surfaces

## Dyld Shared Cache Export Probe

Verified with:

```sh
dyld_info -exports -objc -all_dyld_cache
```

`dyld_info` can print exports from cache images, but not live Objective-C class/category metadata from cache dylibs on this machine.

Observed high-signal exports and classes:

- `TelephonyUtilities.VoiceSpamReportManagerProtocol`
- `TelephonyUtilities.VoiceSpamReportManager`
- `TelephonyUtilities.BadgeCounts`
- `TelephonyUtilities.AnalyticsLogger`
- `OBJC_CLASS_$_INSearchCallHistoryIntent`
- `OBJC_CLASS_$_INSearchCallHistoryIntentResponse`
- `OBJC_CLASS_$_SAPhoneCallHistory`
- `OBJC_CLASS_$_SAPhoneCallSearchResult`
- `CKSQLiteContainerAttribution_PhoneFaceTimeCallHistory`
- `CKSQLiteContainerAttribution_PhoneFaceTimeMessageStore`
- `kGEOCallHistoryRecentsClearedNotification`

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

Demangled highlights:

- `XPCMessage`: associated `Reply` and `Failure`, encodable/decodable, static `messageIdentifier`.
- `XPCInterface`: associated host messages, client messages, interface kind, and identity.
- `XPCIdentity.machService(String)`.
- `XPCHostConnection`: has bundle identifier, UUID id, async send, and one-way send overloads.
- `XPCHost`: request handler, message handlers, cancellation handler, start, one-to-one current connection, and one-to-many connection iteration.
- `XPCHost.ConnectionRequest`: exposes bundle identifier and entitlement value lookup.
- `XPCClient`: async send, sync send, message handlers, cancellation handler, and destroy connection.

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

Demangled highlights:

- `SyncableEntity`: entity name, id, insert/update/equality, and unique key requirements.
- `DataStoreWrapper`: async fetch, fetch count, fetch object IDs, insert, update, delete, delegate.
- `DataStoreWrapperDelegate`: added/updated/deleted syncables, reconnect, and refetch callbacks.
- `DataStoreWrapperError`: batch delete, synchronization, persistent history change, update, deletion, save, fetch, invalid state, store load, and invalid entity name.

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

Additional demangled Phone App Intents surface:

- `PhonePerson`: wraps `IntentPerson` and conforms to App Entity/App Value/display/transfer protocols.
- `CallRecord.CallRecordQuery`: async query by string identifiers.
- `CallMessage`: voicemail/call-message entity with message file, optional transcript, read state, duration, date, sender, and linked call record.
- `CallMessage.CallMessageQuery`: async query by UUIDs.
- `CallStatus.from(TUCallStatus)`: maps private TelephonyUtilities call status into the App Intents enum.

## Constants And Notifications

Captured from SDK `.tbd` exports. These names prove exported constants/symbols exist; they do not yet prove delivery mechanism or posting behavior.

High-signal `TelephonyUtilities` notification families:

- call center: `TUCallCenterCallConnectedNotification`, `TUCallCenterCallStatusChangedNotification`, `TUCallCenterCallStartedConnectingNotification`, `TUCallCenterCallerIDChangedNotification`, `TUCallCenterConferenceParticipantsChangedNotification`
- call state: `TUCallIsOnHoldChangedNotification`, `TUCallIsSendingAudioChangedNotification`, `TUCallIsSendingVideoChangedNotification`, `TUCallIsUplinkMutedChangedNotification`, `TUCallRecordingStateChangedNotification`, `TUCallTranslationStateChangedNotification`
- call history: `TUCallHistoryControllerRecentCallsDidChangeNotification`, `TUCallHistoryControllerUnreadCallCountDidChangeNotification`
- capabilities: `TUCallCapabilitiesFaceTimeAvailabilityChangedNotification`, `TUCallCapabilitiesSupportsTelephonyCallsChangedNotification`, `TUCallCapabilitiesWiFiCallingChangedNotification`, `TUCallCapabilitiesRelayCallingChangedNotification`
- conversation/provider: `TUConversationManagerDidBecomeAvailableNotification`, `TUCallProviderManagerProvidersChangedNotification`, `TUCallConversationChangedNotification`
- audio/video devices: `TUAudioSystemUplinkMuteStatusChangedNotification`, `TUVideoDeviceControllerDeviceBecameAvailableNotification`, `TUVideoDeviceControllerDidStartPreviewNotification`, `TUVideoDeviceControllerUserPreferredCameraChangedNotification`
- privacy/safety: `TUPrivacyRulesChangedNotification`, `TUCallScreeningDidFinishAnnouncementNotification`

High-signal `CallHistory` constants:

- `CHCallInteractionsDidChangeDarwinNotification`
- `kCallHistoryCallRecordInsertedNotification`
- `kCallHistoryDatabaseChangedNotification`
- `kCallHistoryDatabasePluginUpdateNotification`
- `kCallHistoryDatabaseRemoteUpdateReadNotification`
- `kCallHistorySyncHelperReadyNotification`
- `kCallHistoryTimersChangedNotification`

Next sources:

- launchd notify trigger snapshots and targeted `notifyutil -g` probes
- log stream predicates for call-service subsystem names
- controlled runtime observer helper to classify notification center vs Darwin notify behavior

See `notifications.md` for the current delivery-mechanism classification.

## Version Differences

Known first-pass difference:

- The active macOS 26.5.2 private framework directories often lack direct root binaries.
- The macOS 27.0 SDK exposes `.tbd` symbol metadata for private frameworks including `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`.

No semantic symbol diff has been performed yet.
