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
- [x] App entitlement snapshot
- [x] Confirm no AppleScript dictionary via `sdef`
- [x] Active and SDK framework constellation inventory
- [x] App binary linked-library inventory
- [x] SDK `.tbd` symbol skim for `CallsXPC`, `CallsPersistence`, and `PhoneAppIntents`
- [x] Filtered dyld shared cache export probe
- [x] LaunchAgent and XPC service inventory
- [x] Call-history storage schema inventory without row data
- [ ] Generated Swift/Objective-C interfaces from dyld cache or SDK metadata
- [ ] Read-only runtime experiments against app/framework state
- [ ] OS comparison against another macOS build

## Boundary Map

### Supported Public Surfaces

- `tel:` and FaceTime-related URL schemes for user-visible call initiation.
- CallKit for public call directory, VoIP call UI, and call-related extension surfaces.
- LiveCommunicationKit for public communication experiences where applicable.
- App Intents for app-owned actions, not general private call control.

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

## References

- `research/Phone/README.md`
- `docs/frameworks/Phone/symbols.md`
- `docs/frameworks/Phone/experiments.md`
- Apple Developer Documentation: [CallKit framework](https://developer.apple.com/documentation/callkit)
- Apple Developer Documentation: [CoreTelephony framework](https://developer.apple.com/documentation/coretelephony)
- Apple Developer Documentation: [LiveCommunicationKit framework](https://developer.apple.com/documentation/livecommunicationkit)
- Apple Developer Documentation: [LiveCommunicationKit `TelephonyConversationManager`](https://developer.apple.com/documentation/livecommunicationkit/telephonyconversationmanager)
- Apple Developer Documentation: [App Intents framework](https://developer.apple.com/documentation/appintents)
