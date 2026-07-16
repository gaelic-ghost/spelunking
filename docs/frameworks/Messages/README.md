# Messages

## Scope

Research `Messages.app`, `com.apple.MobileSMS`, iMessage, SMS/RCS surfaces, `chat.db`, and related private frameworks, agents, daemons, XPC services, scripting hooks, URL schemes, storage, and supported extension APIs on macOS.

This is private, local-only reverse-engineering research. Do not treat private APIs, database access, dyld-cache symbols, app entitlements, AppleScript commands, or SIP-disabled behavior as public-release, App Store, customer-facing, or redistributed surfaces unless that separate analysis is explicitly opened.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5.2 |
| Active OS build | 25F84 |
| Xcode path | `/Applications/Xcode-beta.app/Contents/Developer` |
| SDK comparison | macOS 27.0 SDK |
| SDK path | `$(xcrun --show-sdk-path --sdk macosx)` |
| Primary app path | `/System/Applications/Messages.app` |
| Bundle identifier | `com.apple.MobileSMS` |
| App version | `26.0` |
| App build | `1450.600.61.1.5` |

## Evidence Inventory

- [x] Active app path
- [x] App bundle identifier, URL schemes, and scripting flags
- [x] App entitlement snapshot
- [x] AppleScript scripting dictionary
- [x] `chat.db` table and column inventory without row data
- [x] `chat.db` schema/index/trigger capture without row data
- [x] Active and SDK framework constellation inventory
- [x] App binary linked-library inventory
- [x] SDK `.tbd` symbol skim for `IMCore`
- [x] Filtered dyld shared cache export probe
- [x] LaunchAgent and XPC service inventory
- [x] Public iPhoneOS 27.0 SDK header inventory for Messages, MessageUI, and Shared With You
- [x] Private `.tbd` notification and type-family inventory
- [x] Read-only Objective-C runtime metadata capture for IM private frameworks
- [x] First-pass notification delivery classification from launchd and SDK symbol evidence
- [ ] Generated Swift/Objective-C interfaces from dyld cache or SDK metadata
- [ ] OS comparison against another macOS build

## Boundary Map

### Supported Public Surfaces

- Messages app extensions: `MSMessagesAppViewController`, `MSConversation`, `MSMessage`, and `MSSession`.
- Shared with You / collaboration metadata for app-owned shared state.
- App Intents and App Shortcuts for app-owned actions, not personal Messages access.
- `MFMessageComposeViewController` for user-visible compose/send flows.
- macOS Apple Events through `Messages.app` for limited local, user-controlled automation.

These are not equivalent surfaces. A Messages extension lives inside visible user interaction. Shared with You carries app-owned collaboration metadata. App Intents expose app actions. Message UI presents a composer. Apple Events automate a local Mac app with permission and a small scripting dictionary.

## Supported API Notes

Verified from the iPhoneOS 27.0 SDK local headers.

### Messages Framework

`MSConversation` exposes:

- participant identifiers scoped to this device: `localParticipantIdentifier` and `remoteParticipantIdentifiers`
- `selectedMessage` when the extension is invoked from a message in the transcript
- staging APIs: `insertMessage`, `insertSticker`, `insertText`, and `insertAttachment`
- send APIs: `sendMessage`, `sendSticker`, `sendText`, and `sendAttachment`

Important boundary: the send APIs require the extension app to be visible and to have had a recent touch interaction since launch or the last send. This makes them user-present extension operations, not background send primitives.

`MSMessagesAppViewController` exposes:

- `activeConversation`
- presentation style and context
- lifecycle callbacks for becoming active and resigning active
- compact/expanded callbacks for message selection, message receipt, send start, send cancellation, and presentation transitions
- transcript presentation hooks such as `contentSizeThatFits`, message tint color, and message corner radius

`MSMessage` exposes:

- `session` for grouping message updates
- `isPending`
- sender participant identifier
- layout, URL payload, expiration, accessibility label, summary text, and send error

Inference: Apple’s supported iMessage extension surface is a constrained UI-extension model for app-specific payloads and transcript UI, with app-owned state encoded through message URLs/layouts and updated through visible user interaction.

### MessageUI

`MFMessageComposeViewController` exposes:

- capability checks: `canSendText`, `canSendSubject`, `canSendAttachments`, and `isSupportedAttachmentUTI`
- initial `recipients`, `body`, `subject`, attachments, and optional interactive `MSMessage`
- attachment APIs for file URLs and data
- `insertCollaborationItemProvider` for collaboration item providers
- delegate completion with `MessageComposeResultCancelled`, `MessageComposeResultSent`, or `MessageComposeResultFailed`

Important boundary: `MessageComposeResultSent` means the user sent or queued the message; the actual delivery can still occur later when the device is able to send.

The UPI category adds `setUPIVerificationCodeSendCompletion` behind the managed `com.apple.developer.upi-device-validation` entitlement. That completion reports actual SMS transmission only for that narrow managed-entitlement validation flow.

### Shared With You Core

`SWCollaborationMetadata` exposes:

- globally unique `collaborationIdentifier`
- local `localIdentifier`
- app-owned `title`
- default and user-selected share options
- initiator handle/name fields used for local confirmation, not transmitted to recipients

`SWStartCollaborationAction` carries collaboration metadata and can be fulfilled with a URL plus collaboration identifier.

`SWUpdateCollaborationParticipantsAction` carries collaboration metadata plus added and removed `SWPersonIdentity` arrays.

Inference: Shared With You collaboration APIs model app-owned shared objects and participant changes. They do not expose personal Messages history.

### Private Local Surfaces

- `~/Library/Messages/chat.db` and attachments.
- `IMCore`, `IMDPersistence`, `IMDaemonCore`, `IMFoundation`, `IMSharedUtilities`, and related IM private frameworks.
- `imagent`, `IMDPersistenceAgent`, transfer/transcoding agents, BlastDoor support, and Messages CloudKit sync components.
- Private entitlements such as `com.apple.private.imcore.imdpersistence.database-access`, `com.apple.private.security.storage.Messages`, and `com.apple.MessagesBlastDoorService` mach lookup.

These are research surfaces only. They may explain how the system works locally, but they are not supported integration contracts.

## App Manifest Notes

Verified from `Messages.app/Contents/Info.plist`:

- `AppleEventSupported` is `true`.
- `NSAppleScriptEnabled` is `true`.
- `OSAScriptingDefinition` is `Messages`.
- `NSPrincipalClass` is `SMSApplication`.
- URL schemes include `sms`, `sms-private`, `itms-messages`, `itms-messagess`, `imessage`, `iChat`, `Messages`, and `im`.
- The app advertises `NSUserActivityTypes` for `com.apple.Messages` and `com.apple.Messages.StateRestoration`.
- The app has a shortcut item with type `com.apple.mobilesms.newmessage`.
- The app declares privacy copy for contacts, location, microphone, camera, media library, SMS data, phone number, photos, call records, and focus status.

## AppleScript Surface

Verified with:

```sh
sdef /System/Applications/Messages.app
```

The scripting dictionary exposes:

- service types: `SMS`, `iMessage`, `RCS`
- transfer directions: `incoming`, `outgoing`
- transfer states: `preparing`, `waiting`, `transferring`, `finalizing`, `finished`, `failed`
- account connection states: `disconnecting`, `connected`, `connecting`, `disconnected`
- application elements: read-only `participants`, `accounts`, `fileTransfers`, and `chats`
- commands: `send`, `login`, and `logout`
- classes: `participant`, `account`, `chat`, and `file transfer`

Important boundary: `send` can target a participant or chat, but the dictionary does not expose general historical search, direct `chat.db` rows, hidden account control, arbitrary message mutation, or remote/server-side iMessage operation.

## Storage

Verified table inventory from `~/Library/Messages/chat.db` without reading row data:

- `_SqliteDatabaseProperties`
- `attachment`
- `chat`
- `chat_handle_join`
- `chat_lookup`
- `chat_message_join`
- `chat_recoverable_message_join`
- `chat_service`
- `deleted_messages`
- `handle`
- `index_state_metrics`
- `kvtable`
- `message`
- `message_attachment_join`
- `message_processing_task`
- `persistent_tasks`
- `recoverable_message_part`
- `scheduled_messages_pending_cloudkit_delete`
- `sync_chat_slice`
- `sync_deleted_attachments`
- `sync_deleted_chats`
- `sync_deleted_messages`
- `unsynced_removed_recoverable_messages`

High-signal schema notes:

- `message` is the main message record table. It includes identifiers, text/attributed body fields, service/account fields, delivery/read/send state, attachment cache state, reactions/replies/threading, expressive send style, CloudKit sync fields, safety/off-grid/satellite flags, scheduled send state, and indexing state.
- `chat` is the conversation table. It includes GUIDs, style/state, account and service names, display and group identifiers, archive/filter/recovery/deletion state, CloudKit sync fields, and pending review/blackhole flags.
- `handle` stores address/person identifiers and service/country fields.
- Join tables map chats to handles, chats to messages, messages to attachments, and chats to recoverable message parts.
- Sync and deleted-item tables indicate CloudKit-backed lifecycle bookkeeping.
- `persistent_tasks` and `message_processing_task` indicate queued local work, but the first pass did not decode task flags or payload blobs.

No message text, addresses, attachment names, or row counts were captured in this documentation pass.

## Entitlement Notes

Verified from `codesign -d --entitlements :- /System/Applications/Messages.app`.

Notable areas:

- storage: `com.apple.private.security.storage.Messages`, `MessagesMetaData`, and home-relative read-write exceptions for `/Library/Messages/`, `/Library/SMS/`, Messages caches, Biome, and media paths
- persistence: `com.apple.private.imcore.imdpersistence.database-access`
- IDS/Madrid: `com.apple.private.ids.messaging` values including `com.apple.madrid`, `com.apple.madrid.lite`, and relay values
- agents/services: mach lookup exceptions for `IMDPersistenceAgent`, `IMRemoteURLConnectionAgent`, `MessagesBlastDoorService`, `IMTranscoderAgent`, `identityservicesd`, `commcenter`, `telephonyutilities.callservicesdaemon`, `suggestd.messages`, and many collaboration/safety services
- CloudKit/social layer: CloudKit SPI, SocialLayer, file provider sharing, Shared With You/collaboration-related privileges
- TCC/privacy: address book, photos, media library, microphone, camera, location, focus status, communication notifications, time-sensitive and critical alerts
- safety/intelligence: communication safety, TextUnderstanding, summarization, translation, message-payload provider, and related private Biome streams

Inference: Messages is a heavily privileged platform app coordinating local database access, IDS transport, content processing, CloudKit sync, safety checks, and local automation. Third-party code should not expect to reproduce this entitlement profile.

## Framework And Agent Map

Verified active framework/app inventory includes:

- public: `Message.framework`, `InstantMessage.framework`, `TelephonyMessagingKit.framework`
- IM private: `IMCore`, `IMCorePipeline`, `IMDPersistence`, `IMDaemonCore`, `IMFoundation`, `IMSharedUtilities`, `IMSharedUI`, `IMTransferAgent`, `IMTransferAgentClient`, `IMTransferServices`, `IMTranscoding`, `IMTranscoderAgent`, `IMRCSTransfer`, `IMDMessageServices`, `IMAssistantCore`, `IMAVCore`
- Messages private: `MessagesKit`, `MessagesHelperKit`, `MessagesCloudSync`, `MessagesBlastDoorSupport`, `MessagesSettingsUI`, `MessageProtection`, `MessageSecurity`, `MessageUIMacHelper`
- Siri/agent adjacent: `SiriMessagesFlow`, `SiriMessagesFlowCommon`, `SiriMessagesUI`, `SiriMessageBus`, `SiriMessageTypes`

The active app binary links to iOSSupport frameworks including `ChatKit`, `IMCore`, and `IMSharedUtilities`, plus macOS private frameworks including `IDSFoundation`, `FTServices`, and `FTClientServices`.

Many private framework directories do not expose a direct on-disk Mach-O binary at the framework root on this macOS build. Their live implementations appear to be dyld shared cache residents or otherwise represented through framework metadata/stubs. Use dyld shared cache extraction for live symbol work.

## Runtime Metadata Notes

Verified by the local `spelunk objc-runtime` helper loading:

- `/System/Library/PrivateFrameworks/IMCore.framework/IMCore`
- `/System/Library/PrivateFrameworks/IMSharedUtilities.framework/IMSharedUtilities`
- `/System/Library/PrivateFrameworks/IMFoundation.framework/IMFoundation`

The narrow `IM*` capture produced 888 Objective-C classes and 150 Objective-C protocols on macOS 26.5.2. This is runtime metadata, not a generated public interface; method and property names are observed selectors/properties and still need behavior confirmation before being treated as stable contracts.

High-signal observed class families:

- account and identity: `IMAccount`, `IMAccountController`, `IMAccountUtilities`, `IMHandle`, `IMAddressBook`, `IMContactStore`, `IMBusinessNameManager`
- chat/message model: `IMChat`, `IMMessage`, `IMHandle`, `IMChatHistoryController`, `IMChatRegistry`, `IMChatItem`, `IMMessagePartChatItem`, `IMAssociatedMessageItem`
- attachments and transfer: `IMAttachment`, `IMAttachmentBlastdoor`, `IMFileTransfer`, preview generators, and attachment metadata classes
- persistence/indexing: `IMDDatabase`, `IMDDatabaseClient`, `IMDChatRecord`, `IMDMessageRecord`, `IMDAttachmentRecord`, `IMDCoreSpotlight*` indexers
- automation/hooks: `IMAutomation`, `IMAutomationMessageSend`, `IMAutomationBatchMessageOperations`, `IMCoreAutomationHook`, `IMCoreAutomationNotifications`
- collaboration and shared state: `IMCollaboration*`, `IMCloudKit*`, nickname, pinning, and sync-related classes

Observed selector/property examples:

- `IMAccount` exposes account state, aliases, relay capability, registration, login, service, block-list, buddy-list, profile, and `canSendMessages` properties/selectors.
- `IMChat` and adjacent chat classes expose local conversation state and history/controller relationships, but this capture does not prove a supported send or mutation contract outside the platform app.
- `IMD*` classes line up with the `chat.db` schema and Spotlight/CloudKit lifecycle tables, supporting the persistence-agent model described above.

Inference: Messages' local architecture has a visible split between user/app model classes (`IMAccount`, `IMChat`, `IMMessage`, attachments), daemon/persistence classes (`IMD*`), and explicit automation/testing hooks (`IMAutomation*`, `IMCoreAutomation*`). The runtime metadata confirms these names exist in the active OS runtime; it does not establish that third-party processes can call them safely or with sufficient entitlements.

## SDK Symbol Notes

Verified from the macOS 27.0 SDK `IMCore.tbd`:

- `IMCore` reexports `InstantMessage` and `IMFoundation`.
- The SDK includes many Swift symbols under the `IMCore.ImportExport` namespace.
- High-signal demangled symbol families include attachment, participant, and conversation import/export iterators, async batches, export statistics, progress reporting, and CloudKit sync completion state.

Inference: the SDK-visible `IMCore` export surface includes modern Swift import/export plumbing for records, attachments, participants, and conversations, not only legacy Objective-C IM types.

Demangled `IMCore` families from the macOS 27.0 SDK include:

- `ImportExportRecordExportIterating`
- `ImportExportProgressReporting`
- `ImportExport.AttachmentExportIterator`
- `ImportExport.ParticipantExportIterator`
- `ImportExport.ConversationExportIterator`
- `ImportExport.ArchiveImportIterator`
- `ImportExport.Attachment`, `Participant`, and `Conversation` batch types
- `ImportExport.ExportOptions`
- `ImportExport.ExportStatistics`
- `ImportExport.RecordCounts`
- `ImportExport.AttachmentDownloader`
- `ImportExport.MessageExportExclusionFilter`

Observed `MessageExportExclusionFilter` cases include promotional, transactional, balloon plugins, junk, system, chat bot, default, deleted, expired, all cases, and business.

## Dyld Shared Cache Notes

Verified with:

```sh
dyld_info -exports -objc -all_dyld_cache
```

The active arm64e shared cache is split under `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/`.

Observed export/symbol hints:

- `IMCoreAttachmentBlastdoorErrorDomain`
- `IMCoreDuetLogHandle`
- `IMCoreSpotlightIndexReasonIsCritical`
- `IMCoreSpotlightIndexReasonIsIncomingMessage`
- `IMCouldBeChatBotKey`
- `IMIsRunningInIMDPersistenceAgent`
- `IMIsRunningInImagent`
- `IMiMessagePrivacyPolicyNotification`
- `MessageServiceLogHandle`
- `NSStringFromIMCoreSpotlightIndexReason`
- `NSStringFromIMPersistentTaskExecutorStatus`
- `NSStringFromIMPersistentTaskLane`
- `IMCoreAutomationNotifications`
- `IMCoreRecentsMetadataBuilder`
- `IMCoreSpotlightUtilities`

Boundary: `dyld_info` reported that it cannot print live Objective-C metadata from dylibs in the dyld shared cache. A later class/protocol/selector pass needs a different extraction path or a controlled runtime helper.

## Launchd And XPC

Verified LaunchAgents:

| Label | Program | High-signal services or triggers |
| --- | --- | --- |
| `com.apple.imagent` | `IMCore.framework/imagent.app` | Mach services for APS/imagent, Messages notifications delegates, Spotlight messages, incoming-call-filter, Madrid IDS wake; launch events for AuthKit user info and `com.apple.private.IMCore.LoggedIntoHSA2` |
| `com.apple.imautomatichistorydeletionagent` | `IMDPersistence.framework/IMAutomaticHistoryDeletionAgent.app` | daily xpc activity plus `com.apple.imautomatichistorydeletionagent.prefchange` |
| `com.apple.imcore.imtransferagent` | `IMTransferServices.framework/IMTransferAgent.app` | Mach service `com.apple.imtransferservices.IMTransferAgent`; IDS transfer launch notification |

Verified XPC services:

| Bundle identifier | Visible name | Notes |
| --- | --- | --- |
| `com.apple.imdmessageservices.IMDMessageServicesAgent` | Message Services Agent | application XPC service |
| `com.apple.imdpersistence.IMDPersistenceAgent` | Messages Database Agent | user XPC service with explicit Apple-signed allowed-client list |
| `com.apple.imtranscoding.IMTranscoderAgent` | Messages Transcoding Agent | application XPC service with GPU access |

`IMDPersistenceAgent.xpc` allowed clients include Apple-signed `MobileSMS.spotlight`, `imagent`, `IMDMessageServicesAgent`, Safari variants, `iChat`, `AddressBook.FaceTimeService`, `imtool`, `assistantd`, `ContactsAgent`, `messages.AssistantExtension`, `IMAutomaticHistoryDeletionAgent`, `messages.StorageManagementExtension`, Control Center, Photos, Game Center, FaceTime, Finder, SocialLayer, CoreDuet, People, Ask To, Suggestd, OmniSearch, diagnostics, and internal incubation tools.

Inference: database access is brokered through a privileged XPC service with a tight Apple-signed client allowlist, not a generic local IPC endpoint for third-party callers.

## Open Questions

- Which live dyld-cache classes and methods back `IMChat`, `IMHandle`, `IMAccount`, and scripting bridge keys on macOS 26.5.2?
- Which XPC messages are exchanged between `Messages.app`, `imagent`, `IMDPersistenceAgent`, `MessagesBlastDoorService`, and transfer/transcoding agents?
- Which `chat.db` task flags and message state integer values map to named IMCore constants?
- Which fields are stable across macOS 26.5.2 and macOS 27.0 SDK assumptions?
- Which remaining unclassified notification constants are posted in-process, through distributed notification center, through Darwin notify, or only used as local symbols?
- Which Apple Events operations require app launch, explicit Automation consent, or foreground user context?

## References

- `research/Messages/README.md`
- `docs/frameworks/Messages/storage.md`
- `docs/frameworks/Messages/symbols.md`
- `docs/frameworks/Messages/notifications.md`
- `docs/frameworks/Messages/experiments.md`
- Apple Developer Documentation: [Messages framework](https://developer.apple.com/documentation/messages)
- Apple Developer Documentation: [Shared with You framework](https://developer.apple.com/documentation/sharedwithyou)
- Apple Developer Documentation: [Shared with You Core `SWCollaborationMetadata`](https://developer.apple.com/documentation/sharedwithyoucore/swcollaborationmetadata)
- Apple Developer Documentation: [MessageUI `MFMessageComposeViewController`](https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller)
- Apple Developer Documentation: [App Intents framework](https://developer.apple.com/documentation/appintents)
