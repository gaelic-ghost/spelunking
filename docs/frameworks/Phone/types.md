# Phone Type Inventory

## Scope

This page summarizes read-only Objective-C runtime metadata captured from Phone, CallKit, call-history, and call-service private frameworks on macOS 26.5.2. It is a type and selector map, not a supported interface contract.

Raw evidence:

- `research/Phone/runtime/objc-runtime-callservices-macos-26.5.2.json`
- `research/Phone/runtime/objc-runtime-callsxpc-phoneintents-macos-26.5.2.json`

The latest deeper pass loaded:

- `/System/Library/PrivateFrameworks/CallsXPC.framework/CallsXPC`
- `/System/Library/PrivateFrameworks/CallsPersistence.framework/CallsPersistence`
- `/System/Library/PrivateFrameworks/PhoneAppIntents.framework/PhoneAppIntents`

All three images loaded successfully through the local `spelunk objc-runtime` helper.

## Capture Summary

| Capture | Prefixes | Classes | Protocols | Notes |
| --- | --- | ---: | ---: | --- |
| `objc-runtime-callservices-macos-26.5.2.json` | `TU*`, `CH*`, `Call*`, `CX*`, `Phone*` | 439 | 181 | TelephonyUtilities, CallHistory, and CallKit runtime metadata. |
| `objc-runtime-callsxpc-phoneintents-macos-26.5.2.json` | `Calls*`, `CX*`, `CH*`, `Phone*`, selected `TU*` | 225 | 97 | CallsXPC, CallsPersistence, and PhoneAppIntents-adjacent Objective-C runtime metadata. |

The first pass attempted `CallHistoryDB.framework`; dyld reported no active file or dyld-cache image for that install name on this machine. That absence is an observed loader result, not proof that no call-history database code exists elsewhere.

## High-Signal Families

### Call History And Persistence

Observed classes include:

- `CHManager`
- `CHRecentCall`
- `CHHandle`
- `CHPersistentContainer`
- `CHPersistentStoreDescription`
- `CHTransaction`
- `CHPluginHelper`
- `CHDatabaseLocationProvider`
- `CHNotifyObserver`

Selector names show recent-call fetching, coalescing, read-state changes, unseen missed-call counts, deletion/reset operations, sync transaction generation, database location resolution, and call-timer access.

`CHRecentCall` properties match the Core Data schema in `storage.md`: answered/originated state, call category/type/status, participant handles, junk/confidence fields, emergency media, duration/date, local participant IDs, originating device, provider, and conversation identifiers.

Inference: `CH*` is the object and manager layer over the local call-history store. It is distinct from live call control and from public CallKit provider APIs.

### Contacts, Metadata, And Identification

Observed classes include:

- `CHPhoneBookIOSManager`
- `CHContactProvider`
- `CHSharedAddressBook`
- `CHPhoneNumber`
- `TUMetadataCache`
- `TUMetadataClientController`
- `TUMetadataDestinationID`
- `TUMetadataItem`
- `TUCallDirectoryMetadataCacheDataProvider`

Selectors mention contact lookup, phone-number formatting and normalization, directory labels, location/suggestion metadata, metadata refresh by destination ID, and call-directory identification entries.

Inference: Phone's recents UI and call surfaces enrich raw handles with Contacts, Call Directory, metadata caches, and suggestions. Storage schema alone is not enough to reproduce displayed call identity.

### Live Call And Conversation Services

Observed classes include:

- `TUCall`
- `TUCallCenter`
- `TUCallContainer`
- `TUCallProvider`
- `TUCallProviderManager`
- `TUCallServicesInterface`
- `TUConversation`
- `TUConversationManager`
- `TUConversationProvider`
- `TUDialRequest`
- `TUHandle`

Observed protocols include:

- `TUCallCenterXPCServer`
- `TUCallCenterXPCClient`
- `TUCallServicesXPCServer`
- `TUCallServicesXPCClient`
- `TUCallProviderManagerXPCServer`
- `TUCallProviderManagerXPCClient`
- `TUCallServicesProxyCallActions`
- `TUCallRequest`

High-signal selectors include dialing with request/display context, joining conversations, answering/disconnecting/holding/grouping calls, in-call UI activation, DTMF playback, call filtering, current-call updates, anonymous XPC endpoint fetching, provider lookup, and URL opening through provider managers.

Inference: live call control is mediated by TelephonyUtilities XPC protocols and provider managers. The `Phone.app` entitlement set explains why the app can reach these services; the metadata does not imply unentitled clients can.

### Recording, Translation, Screening, And Screen Share

Observed classes include:

- `TUCallRecordingRequest`
- `TUCallStartRecordingRequest`
- `TUCallStopRecordingRequest`
- `TUCallRecordingSession`
- `TUCallTranslationRequest`
- `TUCallTranslationStartRequest`
- `TUCallTranslationStopRequest`
- `TUCallTranslationSession`
- `TUCallScreenShareAttributes`
- `TUCallFilterController`
- `TUCallServicesClientCapabilities`

Selectors and properties mention recording session UUIDs, recording mode, redisclosure state, local and remote locales, translation links and state, screening eligibility, screen-share attributes, and client capabilities.

Inference: modern Phone/FaceTime call features are first-class private service concepts, not only UI state in the app process.

### Public CallKit Runtime

Observed classes include:

- `CXCall`
- `CXCallController`
- `CXProvider`
- `CXTransaction`
- `CXCallDirectoryManager`
- `CXCallDirectoryStore`
- `CXVoicemail*`
- `CXChannel*`

Observed protocols include:

- `CXProviderDelegate`
- `CXProviderDelegatePrivate`
- `CXProviderHostProtocol`
- `CXProviderVendorProtocol`
- `CXCallControllerHostProtocol`
- `CXCallControllerVendorProtocol`
- `CXCallObserverDelegate`
- `CXCallDirectoryProviderHostProtocol`
- `CXCallDirectoryProviderVendorProtocol`
- `CXVoicemailProviderHostProtocol`
- `CXVoicemailProviderVendorProtocol`

The public families align with supported CallKit, but the runtime capture also exposes private delegate and host/vendor methods for video, joining, relaying, screening, TTY, screen sharing, MMI/USSD, voicemail mutation, and channel/push-to-talk handling.

Inference: CallKit has a public integration layer and a wider private host/vendor layer. Documentation should keep those boundaries separate.

### Phone App Intents And Swift-Only Surfaces

The Objective-C runtime capture did not surface many `PhoneAppIntents` entity names. The macOS 27.0 SDK `.tbd` symbol pass remains the better evidence for those Swift-heavy types:

- `PhonePerson`
- `CallRecord`
- `CallRecordQuery`
- `CallMessage`
- `CallMessageQuery`
- `CallAVMode`
- `CallStatus`
- `CallProvider`
- `CallDestination`
- `CallRecordType`

Inference: `PhoneAppIntents` appears primarily Swift/App Intents-oriented in the SDK evidence, while the Objective-C runtime pass mostly reveals the lower-level CallsXPC, CallsPersistence, CallHistory, CallKit, and TelephonyUtilities bridge surfaces.

## Boundary Notes

- The runtime helper captures names exposed to the Objective-C runtime after `dlopen`; it does not fully decode Swift-only App Intents or XPC generic types.
- Selector names reveal responsibilities but not argument semantics, entitlement checks, side effects, or whether a method is stable across OS builds.
- The capture did not read call rows, phone numbers, names, voicemail metadata, or personal content.
- Full generated interfaces still require dyld-cache extraction, Swift reflection metadata work, or another private metadata path.

