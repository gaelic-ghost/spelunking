# Messages Type Inventory

## Scope

This page summarizes read-only Objective-C runtime metadata captured from Messages private frameworks on macOS 26.5.2. It is a type and selector map, not a supported interface contract.

Raw evidence:

- `research/Messages/runtime/objc-runtime-im-macos-26.5.2.json`
- `research/Messages/runtime/objc-runtime-imcore-macos-26.5.2.json`
- `research/Messages/runtime/objc-runtime-imd-messageskit-macos-26.5.2.json`

The latest deeper pass loaded:

- `/System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence`
- `/System/Library/PrivateFrameworks/IMDaemonCore.framework/IMDaemonCore`
- `/System/Library/PrivateFrameworks/MessagesKit.framework/MessagesKit`

All three images loaded successfully through the local `spelunk objc-runtime` helper.

## Capture Summary

| Capture | Prefixes | Classes | Protocols | Notes |
| --- | --- | ---: | ---: | --- |
| `objc-runtime-im-macos-26.5.2.json` | broad IM private surface | 888 | 150 | IMCore, IMSharedUtilities, and IMFoundation runtime metadata. |
| `objc-runtime-imcore-macos-26.5.2.json` | IMCore-focused | See raw JSON | See raw JSON | Narrower IMCore capture retained for comparison. |
| `objc-runtime-imd-messageskit-macos-26.5.2.json` | `IMD*`, `IMDaemon*`, selected `CK*` MessagesKit families | 456 | 105 | Persistence, daemon XPC protocols, CloudKit sync, relay, notification, attachment, chat, and message storage classes. |

## High-Signal Families

### Persistence Records And Stores

Observed classes include:

- `IMDChatRecord`
- `IMDMessageRecord`
- `IMDAttachmentRecord`
- `IMDChatStore`
- `IMDMessageStore`
- `IMDAttachmentStore`
- `IMDRecoverableMessageStore`
- `IMDPersistentTask`
- `IMDPersistentTaskQueryProvider`

These classes line up with `chat.db` tables and lifecycle tables documented in `storage.md`. Selector names show record fetching, record-zone mapping, unread-count generation, indexing state changes, attachment cleanup, recoverable-message sync, and persistent task scheduling.

Inference: `IMD*Record` classes are the runtime object layer over the local database records, while `IMD*Store` and query-provider classes own database access, batching, lifecycle cleanup, sync bookkeeping, and queued work.

### Chat And Message Mutation Flow

Observed classes include:

- `IMDChat`
- `IMDChatRegistry`
- `IMDChatRepairController`
- `IMDMessageServicesCenter`
- `IMDMessageSortOrderAssigner`
- `IMDMessageStorageContext`
- `IMDMessageTranslator`

High-signal selectors include chat convergence, group participant updates, display-name changes, message routing requests, scheduled-message requests, watchdog requests, sort-ID assignment, and storage context flags for unread counts, cloud import, replacement, reindexing, and cache update.

Inference: the private runtime separates a conversation registry and repair layer from message storage and routing helpers. This supports the model that local Messages behavior is mediated through daemon/persistence services rather than direct table mutation by the app alone.

### CloudKit And Sync

Observed classes include:

- `IMDCKSyncController`
- `IMDCKMessageSyncController`
- `IMDCKAttachmentSyncController`
- `IMDCKChatSyncController`
- `IMDCKRecoverableMessageSyncController`
- `IMDCKUpdateSyncController`
- `IMDCKDatabaseManager`
- `IMDCKRecordSaltManager`
- `IMDCKSyncState`
- `IMDCKSyncTokenStore`

Selector names show record-zone operations, sync-token storage, chat/message/attachment upload and delete batches, tombstone clearing, eligibility checks, CloudKit container selection, device-condition gates, and local sync-state resets.

Inference: Messages in iCloud is not just a transport flag; it has distinct local controllers for chats, messages, attachments, recoverable message parts, update sync, sync state, salts, zones, and CloudKit operation factories.

### Relay, SMS, RCS, And Reachability

Observed classes include:

- `IMDRelayServiceController`
- `IMDRelayPushHandler`
- `IMDRelayEnrollmentController`
- `IMDRelayDeletionController`
- `IMDRelayAttachmentController`
- `IMDRelayServiceReachabilityController`
- `IMDServiceReachabilityController`
- `IMDServiceReachabilityBaseDelegate`
- `IMDSMSPart`
- `IMDSMSAttachmentPart`
- `IMDSMSTextPart`

Selectors mention SMS relay enrollment, challenged/allowed/ignored devices, relay push listeners, incoming and outgoing relay commands, local file transfer retrieval, MMS/SMS enablement checks, downgrade checks, and service selection for sending.

Inference: the SMS/RCS/iMessage routing layer is encoded as service reachability and relay state around IDS/device relationships. It is not equivalent to a single public "send iMessage" function.

### Notifications And User Response

Observed classes include:

- `IMDNotificationsController`
- `IMDNotificationResponseUtilities`
- `IMDNotificationContextProtocol`
- `IMDNotificationQueries`

Selectors mention notification categories, notification requests, urgent-message handling, notification content user-info population, marking a message read from a notification response, and sending notification replies.

Inference: notification response behavior has private helpers that bridge user notification actions back into chat/message state. The evidence does not prove a supported third-party path to invoke those helpers.

### Daemon Protocols

Observed protocols include:

- `IMDaemonChatProtocol`
- `IMDaemonChatSendMessageProtocol`
- `IMDaemonChatMessageHistoryProtocol`
- `IMDaemonChatModifyReadStateProtocol`
- `IMDaemonCloudSyncProtocol`
- `IMDaemonFileTransferProtocol`
- `IMDaemonBackgroundMessagingProtocol`
- `IMDaemonAutomationProtocol`
- `IMDaemonListenerChatProtocol`
- `IMDaemonListenerChatDatabaseProtocol`
- `IMDaemonPersistentTasksProtocol`

High-signal selectors include:

- send/routing operations: `processMessageForSending:toChat:style:allowWatchdog:account:`, `invitePersonInfo:withMessage:toChatID:identifier:style:account:`, scheduled-message cancellation, group-photo retries, and transcript-background retries
- history/read-state operations: history loads, attachment loads, frequent replies, message deletion, clear history, mark read, mark saved, expressive-send state, and recipient notifications
- automation operations: receive/send dictionaries, replay database recording, relay-message completion, installation/deletion simulation, and downgrade simulation
- CloudKit operations: broadcast state, cancel sync, clear data from CloudKit, create/delete zones, and current storage-on-device queries

Inference: daemon protocols are the strongest evidence for the internal hooks between clients and `imagent`/persistence services. They are still private XPC/daemon contracts and likely require Apple entitlements.

## Boundary Notes

- The runtime helper captures names exposed to the Objective-C runtime after `dlopen`; it does not decode Swift-only private APIs that are not bridged to Objective-C.
- Selector names often reveal responsibility, but not argument semantics, required entitlements, side effects, or expected calling process.
- The capture did not read message rows, addresses, attachment names, or personal content.
- Full generated interfaces still require dyld-cache extraction or another metadata path.

