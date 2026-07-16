# Messages Hooks

## Scope

This page documents hook-like Messages surfaces observed in local runtime metadata on macOS 26.5.2. It focuses on daemon protocols, XPC/listener classes, automation selectors, query interfaces, notification bridge types, and storage-facing manager classes.

This is private, local-only reverse-engineering research. Treat every `IMD*`, `IMDaemon*`, `IMDaemonCore*`, and `CK*` hook described here as an observed private runtime surface, not a supported app, extension, App Store, or redistributed integration contract.

## Evidence

Raw capture:

- `research/Messages/runtime/hook-surface-inventory-macos-26.5.2.json`

Source captures:

- `research/Messages/runtime/objc-runtime-im-macos-26.5.2.json`
- `research/Messages/runtime/objc-runtime-imd-messageskit-macos-26.5.2.json`

Inventory filter:

- class/protocol names or method names matching XPC, daemon, listener, automation, delegate, data source, notification, query, chat, or message protocol surfaces

Observed inventory size:

| Kind | Count |
| --- | ---: |
| Classes | 105 |
| Protocols | 94 |

Boundary: this evidence proves names, selectors, properties, and protocol groupings are present in the active local runtime. It does not prove entitlement availability, call ordering, payload shape, behavioral side effects, or safe third-party use.

## Hook Families

### Daemon XPC Protocols

| Family | Observed examples | Meaning |
| --- | --- | --- |
| Root daemon surface | `IMDaemonProtocol`, `IMDaemonChatProtocol`, `IMDaemonBackgroundMessagingProtocol`, `IMDaemonPersistentTasksProtocol`, `IMDaemonRemoteIntentProtocol` | Private protocol families line up with a brokered daemon model rather than direct database or transport ownership in the app. |
| Send and chat mutation | `IMDaemonChatSendMessageProtocol` | Selectors include message send, edited message send, scheduled-message cancel/edit, group photo updates, transcript background updates, junk reporting, invite/remove person, attachment resend, and translation append/download operations. |
| Read-state and acknowledgement | `IMDaemonChatModifyReadStateProtocol`, `IMDaemonModifyReadStateProtocol` | Selectors include mark-read, mark-saved, expressive-send played state, successful query markers, and notify-recipient commands. |
| Listener callbacks | `IMDaemonListenerNotificationsProtocol`, `IMDaemonListenerChatProtocol`, `IMDaemonListenerChatDatabaseProtocol`, `IMDaemonListenerFileTransfersProtocol` | Listener protocols suggest callback paths from daemon/persistence state back to clients. The first-pass method sample includes `receivedUrgentRequestForMessages:`. |
| File transfer | `IMDaemonFileTransferProtocol`, `IMDaemonChatFileTransferProtocol` | The protocol names align with the transfer-agent and attachment lifecycle surfaces documented in `agents.md` and `storage.md`. |

Observed send selectors include:

- `sendMessage:toChatID:identifier:style:account:`
- `sendEditedMessage:previousMessage:partIndex:editType:toChatIdentifier:style:account:backwardCompatabilityText:`
- `sendEditedScheduledMessage:previousMessage:partIndex:editType:toChatIdentifier:style:account:`
- `cancelScheduledMessageWithGUID:`
- `sendReportJunkMessageGUID:account:shouldRelay:`
- `sendHQAttachmentsForMessage:toChatID:style:account:`

Inference: the send protocol looks like a private client-to-daemon control surface for Apple clients that already have the right process identity, entitlements, and daemon connection. It is not evidence of a standalone userland send API.

### Automation And Test Hooks

High-signal protocol:

- `IMDaemonAutomationProtocol`

Observed selectors include:

- `_automation_sendDictionary:options:toHandles:`
- `_automation_receiveDictionary:options:fromID:`
- `_automation_markMessagesAsRead:messageGUID:forChatGUID:fromMe:queryID:`
- `beginRecordingMessagesToReplayDatabase:`
- `replayMessagesFromDatabasePath:`
- `stopRecordingMessagesReplayDatabase`
- `simulateMessageReceive:serviceName:groupID:handles:sender:`
- `simulateEntries:configuration:completion:`
- `simulateAppDeletion`
- `simulateAppInstallation`
- `test_firstUnlockCompleted`

Inference: the automation protocol is explicitly named and carries simulation, replay, and test-first-unlock hooks. It is likely intended for Apple internal test, diagnostics, or controlled automation lanes, not for ordinary third-party automation.

### Query And Storage Hooks

| Family | Observed examples | Meaning |
| --- | --- | --- |
| Message query protocol | `IMDMessageQueries`, `IMDLegacyMessageQueries` | Query and maintenance selectors cover message GUID/row-id lookup, unread count reports, index-state maintenance, reparenting, and expired time-sensitive message cleanup. |
| Chat query protocol | `IMDChatQueries`, `IMDLegacyChatQueries` | Query names connect chat-oriented clients to persistence rather than direct SQLite access. |
| Notification query protocol | `IMDNotificationQueries` | The sampled selector posts SharePlay notification state for a chat GUID, FaceTime conversation UUID, handle identifier, and localized app name. |
| Stores | `IMDMessageStore`, `IMDChatStore` | Properties include database references, modification stamps, record zone identifiers, deferred unread/index state, and state-capture support. |
| Legacy bridge | `IMDDatabaseLegacyXPCBridge` | The class name indicates compatibility glue around older XPC database paths. Behavior is not yet confirmed. |

Observed `IMDMessageQueries` selectors include:

- `fetchMessageGUIDsForChatWithGUID:chatMessageLimit:completionHandler:`
- `fetchMessageRowIDsForGUIDs:completionHandler:`
- `generateUnreadCountReportsWithCompletionHandler:`
- `markMessagesAsIndexedWithGUIDs:completionHandler:`
- `reassignIdentifierForMessageWithGUID:newGUID:completionHandler:`
- `rebuildIndexStateMetricsWithCompletionHandler:`
- `reparentableMessagesStartingAtRowID:limit:completionHandler:`

Inference: `IMD*Queries` protocols line up with the `chat.db` schema and `IMDPersistenceAgent` allowlist. They suggest database work is brokered through private protocol endpoints and store objects, not exposed as a general SQLite access contract.

### Notification And Response Hooks

Observed classes and protocols:

- `IMDNotificationContextProtocol`
- `IMDNotificationQueries`
- `IMDNotificationsController`
- `IMDAskToBuyNotificationContext`
- `IMDCustomPluginNotificationContext`
- `IMDFamilyInviteNotificationContext`
- `IMDSafetyMonitorNotificationContext`
- `IMDScreenTimeAskNotificationContext`
- `IMDDistributedNotificationXPCEventStreamHandler`
- `IMDXPCEventStreamHandler`
- `IMDXPCEventStreamHandlerDelegate`
- `IMMessageNotificationController`

Inference: notification hooks are split between local notification context objects, query methods that post specific notification state, and XPC/distributed notification event-stream handlers. The current evidence does not yet classify each selector as in-process notification-center, distributed notification, Darwin notify, push, or daemon callback behavior.

### Listener And Routing Classes

Observed classes:

- `IMDIncomingClientConnectionListener`
- `IMDPersistenceServiceListener`
- `IMDBackgroundMessagingAPIListener`
- `IMDaemonCore.ClientConnection`
- `IMDaemonCore.IntentClientConnectionRouteProvider`
- `IMDaemonCore.XPCClientConnectionRouteProvider`
- `IMDaemonCore.IMDaemonCoreBridgeDelegate`
- `IMDaemonCoreBridgeImpl`
- `IMDaemonCore.FileEventStream`

Inference: these names support a multi-route daemon model: XPC clients, intent clients, background messaging listeners, persistence listeners, and bridge delegates. The names are strong architecture evidence but still need controlled runtime tracing before assigning exact ownership to `Messages.app`, `imagent`, `IMDPersistenceAgent`, or extension clients.

## Working Model

Messages appears to use private hooks in layers:

1. Visible or app-facing model surfaces such as `IMChat`, `IMMessage`, and `MessagesKit` UI classes.
2. Daemon protocols under `IMDaemon*` for send, mutate, listener, background messaging, file transfer, and automation paths.
3. Persistence/query protocols under `IMD*Queries` and store classes that map to `chat.db`, CloudKit, indexing, unread counts, and notification state.
4. Event/listener classes that route XPC, distributed notification, background messaging, and intent-client traffic.

The strongest private hook evidence is protocol-based, not database-based. For future behavioral work, protocol names and selectors are better starting points than ad hoc `chat.db` writes.

## Open Questions

- Which mach services expose each `IMDaemon*` protocol to Apple clients?
- Which selectors are reachable from `Messages.app`, `imagent`, `IMDPersistenceAgent`, app extensions, Siri/Assistant, or diagnostics clients?
- Which automation selectors are compiled into production for Apple-only diagnostics versus internal test use?
- What payload shapes are expected by `_automation_sendDictionary:options:toHandles:` and `_automation_receiveDictionary:options:fromID:`?
- Which notification context classes correspond to notification-center posts, Darwin notify names, push notifications, or local user notifications?
- Which selectors require `com.apple.private.imcore.imdpersistence.database-access`, Messages storage privileges, IDS privileges, or the `IMDPersistenceAgent` allowed-client list?
