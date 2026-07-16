# Phone

## Scope

Research `Phone.app`, `com.apple.mobilephone`, call history, telephony/call services, Phone App Intents, FaceTime-adjacent call surfaces, URL schemes, private frameworks, daemons, XPC services, storage, hooks, and supported public call APIs on macOS.

This is private, local-only reverse-engineering research. Do not treat private APIs, entitlements, call-history stores, TelephonyUtilities services, or SIP-disabled behavior as public-release, App Store, customer-facing, or redistributed surfaces unless that separate analysis is explicitly opened.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5.2 |
| Active OS build | 25F84 |
| Xcode path | `/Applications/Xcode-beta.app/Contents/Developer` |
| SDK comparison | macOS 27.0 SDK |
| SDK path | `$(xcrun --show-sdk-path --sdk macosx)` |
| Primary app path | `/System/Applications/Phone.app` |
| Bundle identifier | `com.apple.mobilephone` |
| App version | `1.0` |
| App build | `1` |

## Evidence Inventory

- [x] Active app path
- [x] App bundle identifier and URL schemes
- [x] App extension, plugin, URL, AppleScript, and intent surface inventory
- [x] App entitlement snapshot
- [x] Confirm no AppleScript dictionary via `sdef`
- [x] Active and SDK framework constellation inventory
- [x] App binary linked-library inventory
- [x] SDK `.tbd` symbol skim for `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`
- [x] Filtered dyld shared cache export probe
- [x] LaunchAgent and XPC service inventory
- [x] Call-history storage schema inventory without row data
- [x] Call-history schema/index capture without row data
- [x] Public iPhoneOS 27.0 SDK header/interface inventory for CallKit and LiveCommunicationKit
- [x] Private `.tbd` notification and type-family inventory
- [x] Read-only Objective-C runtime metadata capture for call-history, TelephonyUtilities, and CallKit surfaces
- [x] Read-only Objective-C runtime metadata capture for CallsXPC, CallsPersistence, and PhoneAppIntents surfaces
- [x] Bounded app-open log observation
- [x] First-pass notification delivery classification from launchd and SDK symbol evidence
- [ ] Generated Swift/Objective-C interfaces from dyld cache or SDK metadata
- [ ] OS comparison against another macOS build

## Boundary Map

### Supported Public Surfaces

- `tel:` and FaceTime-related URL schemes for user-visible call initiation.
- CallKit for public call directory, VoIP call UI, and call-related extension surfaces.
- LiveCommunicationKit for public communication experiences where applicable.
- App Intents for app-owned actions, not general private call control.

## Supported API Notes

Verified from iPhoneOS and macOS 27.0 SDK headers/interfaces.

### CallKit

Local SDK headers expose the public call integration model through:

- actions: `CXStartCallAction`, `CXAnswerCallAction`, `CXEndCallAction`, `CXSetHeldCallAction`, `CXSetMutedCallAction`, `CXSetGroupCallAction`, `CXPlayDTMFCallAction`, and `CXSetTranslatingCallAction`
- state/model objects: `CXCall`, `CXCallUpdate`, `CXHandle`, and `CXTransaction`
- orchestration: `CXProvider`, `CXProviderConfiguration`, `CXCallController`, and `CXCallObserver`
- call-directory extension support: `CXCallDirectoryProvider`, `CXCallDirectoryExtensionContext`, and `CXCallDirectoryManager`

Inference: public CallKit supports app-owned calling services and call-directory behavior, but it is not a general interface to Phone’s private call history, voicemail store, or `callservicesd` control surface.

### LiveCommunicationKit

The Swift interface exposes:

- `ConversationManager.Configuration` with ringtone, icon, conversation-group limits, recents inclusion, video support, supported handle types, and audio translation support
- `Conversation` with observable state and local member
- `ConversationAction` plus concrete `StartConversationAction`, `PauseConversationAction`, and `MergeConversationAction`
- `TelephonyConversationManager.sharedInstance`, `cellularServices`, and `startCellularConversation`
- `ConversationHistoryManager.sharedInstance` with recent-conversation queries and mark-read operations
- `ConversationHistoryDidUpdate` as a notification-center async message

Inference: LiveCommunicationKit is the public route for modern conversation experiences and, where supported, default-dialer/cellular conversation integration. It does not expose the private Phone App Intents or TelephonyUtilities storage/control surfaces directly.

### Private Local Surfaces

- `Phone.app` and FaceTime-derived private app stack.
- `TelephonyUtilities`, `CallsXPC`, `CallsPersistence`, `CallHistory`, `CallHistoryToolKit`, `CallsUtilities`, `CallIntelligence`, and related call-service frameworks.
- `callservicesdaemon`, call history controllers, voicemail daemon, CommCenter, IDS, FaceTime message store, and Siri phone intents.
- Private call-history storage and platform entitlements.

These are research surfaces only. They can explain how Phone works locally, but they are not supported integration contracts.

## App Manifest Notes

Verified from `Phone.app/Contents/Info.plist`:

- Bundle identifier is `com.apple.mobilephone`.
- Executable is `Phone`.
- URL schemes include `tel`, `telephony`, `facetime-audio`, `tel-phoneapp`, `phoneapp`, and `vmshow`.
- `NSUserActivityTypes` includes `com.apple.facetime.handoff`.
- `NSDockTilePlugIn` is `PhoneDockTile.docktileplugin`.
- `UIApplicationSceneManifest` declares multi-scene support.
- `UIDeviceFamily` is `6`.

Verified with `sdef /System/Applications/Phone.app`:

- Phone does not expose a scripting dictionary on this machine. `sdef` returned error `-192`.

## Entitlement Notes

Verified from `codesign -d --entitlements :- /System/Applications/Phone.app`.

Notable areas:

- app identity: bundle identifier is `com.apple.mobilephone`, while `application-identifier` and previous identifiers include `0000000000.com.apple.FaceTime`
- call history: `com.apple.private.CallHistory.read-write`, `com.apple.CallHistory.sync.allow`, `com.apple.callhistory.pluginhelper`
- TelephonyUtilities: broad `com.apple.telephonyutilities.callservicesd` privileges, including access/modify calls, background calls, call providers, call capabilities, record calls, screen calls, translate calls, smart holding, media priorities, and participant reactions
- CommCenter: fine-grained access for cellular plan, phone, identity, SMS, data usage, and SPI
- FaceTime/IDS: FaceTime no-prompt, FaceTime message store, IDS messaging/registration, IMAV/IMCore access, and FaceTime live photo service
- storage: `com.apple.private.security.storage.CallHistory`, home-relative read/write for `/Library/CallHistoryDB/`, speed dial preferences, PeoplePicker preferences, and Contacts metadata
- URL privileges: default-handler and sensitive URL privileges for telephony, FaceTime, mobilephone, voicemail, and `sms-private`
- TCC/privacy: microphone, camera, calendar, reminders, contacts, photos, address book, and network privileges
- agent/service edges: mach lookup exceptions for `callservicesdaemon`, `CallHistoryPluginHelper`, `CallHistorySyncHelper`, `voicemail.vmd`, CommCenter, FaceTime message store, group activities, IDS, contacts, suggestions, and communication trust services

Inference: macOS `Phone.app` is a FaceTime/call-services platform app with telephone, FaceTime audio, voicemail, call history, contacts, and call-control privileges layered through private daemons and frameworks. It is not a scriptable analogue of Messages.

## Storage

Verified call-history storage locations:

- `~/Library/Application Support/CallHistoryDB/CallHistory.storedata`
- `~/Library/Application Support/CallHistoryDB/CallHistory.storedata-shm`
- `~/Library/Application Support/CallHistoryDB/CallHistory.storedata-wal`
- `~/Library/Application Support/CallHistoryDB/com.apple.callhistory.databaseInfo.plist`
- `~/Library/Application Support/CallHistoryTransactions/transactions.log`

`com.apple.callhistory.databaseInfo.plist` reports `DatabaseVersionPerm` as `43`.

Verified table inventory from `CallHistory.storedata` without reading row data:

- `ZCALLDBPROPERTIES`
- `ZCALLRECORD`
- `ZEMERGENCYMEDIAITEM`
- `ZHANDLE`
- `Z_2REMOTEPARTICIPANTHANDLES`
- `Z_METADATA`
- `Z_MODELCACHE`
- `Z_PRIMARYKEY`

High-signal schema notes:

- `ZCALLRECORD` is the main call record table. It includes answered/originated/read state, call type/category, disconnect cause, FaceTime data flag, message flag, junk/confidence fields, communication trust score, emergency/video flags, verification status, timestamps, duration, service provider, country code, location/name/address fields, unique identifiers, conversation ID, participant group identifiers, local participant UUIDs, originating device name, and originating UI type.
- `ZHANDLE` stores normalized and raw handle values plus type.
- `Z_2REMOTEPARTICIPANTHANDLES` joins remote participant calls to handles.
- `ZCALLDBPROPERTIES`, `Z_METADATA`, `Z_MODELCACHE`, and `Z_PRIMARYKEY` are Core Data or store bookkeeping tables.
- `ZEMERGENCYMEDIAITEM` tracks emergency media assets and upload state.

No call rows, phone numbers, names, addresses, durations, timestamps, voicemail metadata, or transaction-log contents were captured in this documentation pass.

## Framework And Agent Map

Verified active framework/app inventory includes:

- public: `CallKit`, `CoreTelephony`, `LiveCommunicationKit`, `TelephonyMessagingKit`
- call private: `CallHistory`, `CallHistoryToolKit`, `CallIntelligence`, `CallsPersistence`, `CallsUtilities`, `CallsXPC`, `IncomingCallFilter`
- telephony private: `TelephonyUtilities`, `IPTelephony`, `CorePhoneNumbers`, `PhoneNumbers`, `PhoneNumberResolver`, `TelephonyBlastDoorSupport`
- Phone/Siri private: `PhoneAppIntents`, `PhoneSnippetUI`, `SiriPhoneIntents`, `SiriPhoneCATs`
- FaceTime adjacent: `FaceTimeMacHelperCore`, `FaceTimeMessageStore`, `FaceTimeFeatureControl`, `FaceTimeDockSupport`, notification frameworks, and iOSSupport FaceTime/PhoneKit/Calls frameworks

The active app binary links to iOSSupport private frameworks including:

- `PhoneKit`
- `CallsAppUI`
- `CallsAppServices`
- `CallsDialer`
- `CallsSearch`
- `FaceTimeMac`
- `FaceTimeAuthentication`
- `FaceTimeSettingsUI`
- `ConversationKit`
- `CommunicationsUI`

It also links to macOS private frameworks including:

- `CallHistory`
- `FaceTimeMessageStore`
- `IDS`
- `TelephonyUtilities`
- `CommunicationTrust`

## Runtime Metadata Notes

Verified by the local `spelunk objc-runtime` helper loading:

- `/System/Library/PrivateFrameworks/TelephonyUtilities.framework/TelephonyUtilities`
- `/System/Library/PrivateFrameworks/CallHistory.framework/CallHistory`
- `/System/Library/Frameworks/CallKit.framework/CallKit`
- `/System/Library/PrivateFrameworks/CallsXPC.framework/CallsXPC`
- `/System/Library/PrivateFrameworks/CallsPersistence.framework/CallsPersistence`
- `/System/Library/PrivateFrameworks/PhoneAppIntents.framework/PhoneAppIntents`

The capture also attempted `/System/Library/PrivateFrameworks/CallHistoryDB.framework/CallHistoryDB`; dyld reported no active file or dyld-cache image for that install name on this machine.

The `TU*`, `CH*`, `Call*`, `CX*`, and `Phone*` capture produced 439 Objective-C classes and 181 Objective-C protocols on macOS 26.5.2. This is runtime metadata, not a generated public/private interface; method and property names are observed selectors/properties and still need behavior confirmation.

The `Calls*`, `CX*`, `CH*`, `Phone*`, and selected `TU*` capture produced 225 Objective-C classes and 97 Objective-C protocols. See `types.md` for the stable type-family inventory.

High-signal observed class families:

- call history model/storage: `CHManager`, `CHRecentCall`, `CHHandle`, `CHPersistentContainer`, `CHTransaction`, `CallDBManager`, `CallDBManagerClient`, `CallHistoryDBHandle`
- telephony/call services: `TUCall`, `TUCallCenter`, `TUCallProvider`, `TUCallServicesInterface`, `TUCallHistoryController`, `TUCallHistoryManager`, `TUConversation`, `TUConversationManager`, `TUConversationProvider`
- call features: `TUCallRecording*`, `TUCallTranslation*`, `TUCallScreenShareAttributes`, `TUCollaboration*`, `TUConversationReactionsController`
- public CallKit runtime: `CXCall`, `CXCallController`, `CXProvider`, `CXTransaction`, `CXCallDirectory*`, `CXVoicemail*`

Observed selector/property examples:

- `CHManager` exposes recent-call fetching, coalescing, counting, read-state changes, delete/reset/clear operations, database size, sync transactions, and call-timer methods.
- `CHRecentCall` exposes call status/type/category, answered/originated/read state, participant handles, junk/verification/trust fields, emergency media fields, duration/date, local participant IDs, and message/voicemail-adjacent flags.
- `CHHandle` exposes normalized value, raw value, handle type, pseudonym, and temporary-handle checks.
- `TU*` classes expose the call-services model layer around live calls, conversations, call providers, call history controllers, recording, translation, continuity, and collaboration.

Inference: Phone's local architecture splits persisted recents (`CH*` and `CallDB*`) from live call/conversation services (`TU*`) and public integration (`CX*`). The runtime metadata supports the storage and service split; it does not prove third-party access to private call mutation or history APIs.

See `runtime.md` for app-open log observations covering the FaceTime app controller, Calls recents controller, FaceTimeMac window, Spotlight indexing, and Continuity Capture touchpoints.

## SDK Symbol Notes

Verified from macOS 27.0 SDK `.tbd` files.

`CallsXPC`:

- targets include macOS and Mac Catalyst
- exports Swift symbols for typed XPC messages, interfaces, identities, result errors, payload decoding, client/host message groups, and one-to-one interface kinds

`CallsPersistence`:

- exports Swift symbols around data-store wrappers, syncable entities, persistent history changes, fetch/save/delete/update failures, and delegate notifications for added/updated/deleted syncables

`PhoneAppIntents`:

- exports App Intents entities and values including `PhonePerson`, `CallRecord`, `CallMessage`, `CallAVMode`, and `CallStatus`
- `CallRecord` exposes intent-facing fields such as id, date, type, duration, provider, audio/visual mode, and remote participants
- `CallStatus` includes cases such as active, ringing, sending, on hold, disconnecting, disconnected, and unknown

Inference: the beta SDK exposes a structured App Intents layer for Phone call records/messages and a Swift XPC/persistence stack for private call-service internals.

Demangled `PhoneAppIntents` families from the macOS 27.0 SDK include:

- `PhonePerson`: transient App Entity/App Value wrapper around `IntentPerson`
- `CallAVMode`: AppEnum with `audio` and `video`
- `CallStatus`: AppEnum with `active`, `ringing`, `sending`, `onHold`, `disconnecting`, `disconnected`, and `unknown`; includes a conversion from `TUCallStatus`
- `CallRecord`: App Entity, Indexed Entity, Syncable Entity, and Assistant Entity with `id`, `date`, `type`, `duration`, `provider`, `audioVisualMode`, and `remoteParticipants`
- `CallRecordQuery`: async entity query by string identifiers
- `CallMessage`: App Entity, Indexed Entity, Syncable Entity, Assistant Entity, model-representable, displayable, transferable entity with `id`, `date`, `from`, `duration`, `isRead`, `messageFile`, `voicemailTranscript`, and optional `callRecord`
- `CallMessageQuery`: async entity query by UUIDs
- `CallProvider`, `CallDestination`, and `CallRecordType` supporting call-record representation

Demangled `CallsXPC` families include:

- `XPCMessage`, with associated reply/failure types and static message identifiers
- `XPCInterface`, with host messages, client messages, interface kind, and identity
- `XPCIdentity.machService`
- `XPCMessages` with typed payload decoder maps
- `XPCHostConnection`, `XPCHost`, and `XPCClient`, with async send, sync send, message handlers, cancellation handlers, and entitlement lookup on connection requests
- one-to-one and one-to-many interface kinds

Demangled `CallsPersistence` families include:

- `SyncableEntity` and `Syncable`
- `DataStoreWrapper` with async fetch/count/object-id operations plus insert, update, and delete
- `DataStoreWrapperDelegate` callbacks for added, updated, deleted syncables, reconnect, and refetch requirements
- `DataStoreWrapperError` cases for batch delete, synchronization, persistent history, update, deletion, save, fetch, invalid state, store load, and invalid entity name

Demangled `TelephonyUtilities` families include:

- `VoiceSpamReportTelephonyManagerProtocol` and `VoiceSpamReportTelephonyManager`
- `BadgeCounts` and `BadgeCountCategory`
- `MessageStoreBadgeCounts`
- `RecordingMetadata` and `RecordingMediaComposer`
- `CallContextCardsHolder`

## Dyld Shared Cache Notes

Verified with:

```sh
dyld_info -exports -objc -all_dyld_cache
```

The active arm64e shared cache is split under `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/`.

Observed export/symbol hints:

- `TelephonyUtilities.VoiceSpamReportManagerProtocol`
- `TelephonyUtilities.VoiceSpamReportManager`
- `TelephonyUtilities.BadgeCounts`
- `TelephonyUtilities.AnalyticsLogger`
- `INSearchCallHistoryIntent`
- `INSearchCallHistoryIntentResponse`
- `SAPhoneCallHistory`
- `SAPhoneCallSearchResult`
- `CKSQLiteContainerAttribution_PhoneFaceTimeCallHistory`
- `CKSQLiteContainerAttribution_PhoneFaceTimeMessageStore`
- `kGEOCallHistoryRecentsClearedNotification`

Boundary: `dyld_info` reported that it cannot print live Objective-C metadata from dylibs in the dyld shared cache. A later class/protocol/selector pass needs a different extraction path or a controlled runtime helper.

## Launchd And XPC

Verified LaunchAgents:

| Label | Program | High-signal services or triggers |
| --- | --- | --- |
| `com.apple.callhistoryd` | `CallHistory.framework/Support/callhistoryd` | Mach services `com.apple.callhistoryd.service` and `com.apple.conversation.history` |
| `com.apple.CallHistoryPluginHelper` | `CallHistory.framework/Support/CallHistoryPluginHelper` | Mach service `com.apple.CallHistoryPluginHelper`; notify trigger `com.apple.CallHistoryPluginHelper.launchnotification` |
| `com.apple.CallHistorySyncHelper` | `CallHistory.framework/Support/CallHistorySyncHelper` | Mach services `com.apple.CallHistorySyncHelper` and `.aps`; IDS launch notification |
| `com.apple.callintelligenced` | `CallIntelligence.framework/callintelligenced` | Mach service `com.apple.callintelligenced.service`; first-unlock trigger |
| `com.apple.facetimemessagestored` | `FaceTimeMessageStore.framework/facetimemessagestored` | APS and FaceTime message-store mach services |
| `com.apple.telephonyutilities.callservicesd` | `TelephonyUtilities.framework/callservicesd` | CallKit, FaceTime alloy, call history, call state, conversation, provider, notification, VoIP, and simulated-conversation mach services |

Verified XPC and extension bundles:

| Bundle identifier | Bundle type | Notes |
| --- | --- | --- |
| `com.apple.TelephonyUtilities.PhoneIntentHandler` | intents extension | supports `INAddCallParticipantIntent`, `INJoinCallIntent`, `INStartCallIntent`, `INSearchCallHistoryIntent`, and `INPlayVoicemailIntent` |
| `com.apple.TelephonyBlastDoorService` | XPC service | application service with ProbGuard and shared-cache reslide |
| `com.apple.FaceTime.FTConversationService` | XPC service | FaceTime conversation service |
| `com.apple.FTLivePhotoService` | XPC service | FaceTime live photo service |

Inference: Phone’s user-facing app sits above a broad `callservicesd` broker plus CallHistory, FaceTime, IDS, voicemail, and intent-handler surfaces. The exposed Siri/Intent verbs are narrower than the app’s private TelephonyUtilities entitlement set.

## Open Questions

- Which dyld-cache classes back `PhoneKit`, `CallsAppServices`, `CallsDialer`, and `TelephonyUtilities` behavior?
- Which `callservicesdaemon` XPC interfaces correspond to the broad `com.apple.telephonyutilities.callservicesd` entitlement values?
- Which Phone App Intents are user-invocable, Siri-only, or private/system-only?
- Which URL schemes open visible UI only versus initiating privileged background actions for Apple-signed callers?
- How does `Phone.app` divide responsibilities with `FaceTime.app` on macOS?
- Which remaining unclassified TelephonyUtilities and CallHistory notification constants are distributed, Darwin, notification-center, or internal-only?

## References

- `research/Phone/README.md`
- `docs/frameworks/Phone/surfaces.md`
- `docs/frameworks/Phone/storage.md`
- `docs/frameworks/Phone/symbols.md`
- `docs/frameworks/Phone/notifications.md`
- `docs/frameworks/Phone/experiments.md`
- Apple Developer Documentation: [CallKit framework](https://developer.apple.com/documentation/callkit)
- Apple Developer Documentation: [CoreTelephony framework](https://developer.apple.com/documentation/coretelephony)
- Apple Developer Documentation: [LiveCommunicationKit framework](https://developer.apple.com/documentation/livecommunicationkit)
- Apple Developer Documentation: [LiveCommunicationKit `TelephonyConversationManager`](https://developer.apple.com/documentation/livecommunicationkit/telephonyconversationmanager)
- Apple Developer Documentation: [App Intents framework](https://developer.apple.com/documentation/appintents)
