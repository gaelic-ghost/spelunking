# Messages XPC Ownership

## Scope

This page correlates Messages launchd mach services, XPC service allowlists, app entitlements, and observed private protocol families on macOS 26.5.2.

This is not a traffic trace. The mappings below are evidence-backed ownership hypotheses unless a row says the relationship is directly observed in a plist or entitlement.

## Evidence

Raw capture:

- `research/Messages/runtime/xpc-ownership-macos-26.5.2.txt`

Related evidence:

- `research/Messages/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Messages/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Messages/runtime/hook-surface-inventory-macos-26.5.2.json`
- [Messages agents](agents.md)
- [Messages hooks](hooks.md)

Boundary: launchd plists prove registered mach services and launch events. XPC service plists prove bundle identifiers, service type, and declared allowed clients where present. Entitlements prove the app can request named mach services or private privileges. Runtime protocol names prove selectors exist. None of these alone proves a selector was invoked during the captured session.

## Service Ownership Map

| Owner | Observed service or allowlist evidence | Correlated hook families | Confidence |
| --- | --- | --- | --- |
| `imagent` | LaunchAgent `com.apple.imagent`; mach services for APS, CoreSpotlight Messages, desktop auth, incoming-call filter, Madrid IDS wake, user-notification delegates for MobileSMS/iChat | `IMDaemon*` chat/listener/background protocol families, `IMDaemonCore.*` routing classes | Medium. Service ownership is observed; exact protocol binding still needs traffic or interface evidence. |
| `IMDPersistenceAgent` | XPC service `com.apple.imdpersistence.IMDPersistenceAgent`, service type `User`, visible name `Messages Database Agent`, explicit Apple-signed `_AllowedClients` list | `IMDMessageQueries`, `IMDChatQueries`, `IMDNotificationQueries`, `IMDMessageStore`, `IMDChatStore`, `IMDPersistenceServiceListener` | High for persistence/database brokering; medium for specific selector ownership. |
| `IMDMessageServicesAgent` | XPC service `com.apple.imdmessageservices.IMDMessageServicesAgent`, service type `Application`, listed as an allowed client of `IMDPersistenceAgent` | Message routing/state service families and daemon-to-persistence mediation | Medium. The service exists and can reach persistence; exact protocol surface is not yet decoded. |
| `IMTransferAgent` | LaunchAgent `com.apple.imcore.imtransferagent`; mach service `com.apple.imtransferservices.IMTransferAgent`; IDS transfer launch notification | `IMDaemonFileTransferProtocol`, `IMDaemonChatFileTransferProtocol`, attachment transfer families | Medium. Service and transfer role are observed; protocol-to-mach binding is inferred from names and role. |
| `IMTranscoderAgent` | XPC service `com.apple.imtranscoding.IMTranscoderAgent`; `Messages.app` has mach lookup entitlement for `com.apple.imtranscoding.IMTranscoderAgent` | Media transcoding and attachment conversion paths | Medium. App-to-service entitlement is observed; specific request selectors are not decoded. |
| Messages BlastDoor support | `Messages.app` has mach lookup entitlement for `com.apple.MessagesBlastDoorService` | Attachment/message payload safety processing | Low to medium. Entitlement proves lookup permission; this pass did not capture the service plist or selector surface. |
| IM remote URL connection | `Messages.app` has mach lookup entitlement for `com.apple.imfoundation.IMRemoteURLConnectionAgent` and private `imremoteurlconnection` entitlement | Remote URL/content fetch paths | Low to medium. Entitlement proves intended access; request protocol details are not yet mapped. |
| TelephonyUtilities call services | `Messages.app` has `com.apple.telephonyutilities.callservicesd` values and mach lookup for call state/conversation manager services | FaceTime conversation, SharePlay, collaboration, call-state edges | Medium for cross-service dependency; low for Messages-specific selector ownership. |

## IMDPersistenceAgent Allowed Client Boundary

The raw capture shows `IMDPersistenceAgent` declares an Apple-signed `_AllowedClients` list. High-signal clients include:

- `com.apple.MobileSMS.spotlight`
- `com.apple.imagent`
- `com.apple.imdmessageservices.IMDMessageServicesAgent`
- `com.apple.iChat`
- `com.apple.AddressBook.FaceTimeService`
- `com.apple.imtool`
- `com.apple.assistantd`
- `com.apple.messages.AssistantExtension`
- `com.apple.IMAutomaticHistoryDeletionAgent`
- `com.apple.messages.StorageManagementExtension`
- `com.apple.FaceTime`
- `com.apple.sociallayerd`
- `com.apple.coreduetd`
- `com.apple.suggestd`
- `com.apple.DiagnosticExtensions.IMDiagnosticExtension`

Inference: database and query access is deliberately constrained to Apple-signed local clients. This supports the existing storage boundary: `chat.db` is a research artifact and local data store, not the integration API.

## Protocol-To-Service Correlation

| Protocol or class family | Most likely owner | Basis | Remaining proof needed |
| --- | --- | --- | --- |
| `IMDMessageQueries`, `IMDChatQueries`, `IMDNotificationQueries` | `IMDPersistenceAgent` | `IMD` prefix, persistence-agent role, database access entitlement, allowed-client boundary | Generated interface, XPC endpoint metadata, or traffic trace. |
| `IMDaemonChatSendMessageProtocol`, `IMDaemonChatModifyReadStateProtocol`, `IMDaemonListener*` | `imagent` or daemon bridge layer | `IMDaemon*` prefix, `imagent` mach services, app-open logs involving `imagent` and `IMDPersistenceAgent` | Determine which process hosts the exported object and which mach service accepts the connection. |
| `IMDaemonAutomationProtocol` | Apple diagnostics/test lane through daemon bridge | Explicit automation selectors and production runtime presence | Entitlement/allowlist proof and controlled non-personal invocation evidence. |
| `IMDaemonFileTransferProtocol`, `IMDaemonChatFileTransferProtocol` | `IMTransferAgent` and daemon bridge | Transfer-agent mach service and IDS transfer launch notification | Confirm which process owns chat-file-transfer selectors. |
| `IMDDistributedNotificationXPCEventStreamHandler`, `IMDXPCEventStreamHandler` | Persistence or daemon notification bridge | Class names and notification docs | Runtime event-stream ownership and posted-name mapping. |

## Entitlement Notes

High-signal `Messages.app` privileges in the ownership capture include:

- `com.apple.private.imcore.imdpersistence.database-access`
- `com.apple.private.security.storage.Messages`
- `com.apple.private.security.storage.MessagesMetaData`
- `com.apple.private.ids.messaging` values for Madrid/iMessage lanes
- `com.apple.telephonyutilities.callservicesd` values for call/conversation/collaboration edges
- mach lookup for `IMDPersistenceAgent`, `IMTranscoderAgent`, `MessagesBlastDoorService`, `IMRemoteURLConnectionAgent`, call state/conversation manager services, CommCenter CoreTelephony, and suggestions/message-filter services

Inference: `Messages.app` is privileged as a local platform coordinator. The app’s entitlement set is broader than the supported public extension, Shared with You, App Intents, MessageUI, and AppleScript surfaces.

## Open Questions

- Which mach service accepts `IMDaemonChatSendMessageProtocol` traffic?
- Which process owns `IMDaemonAutomationProtocol` in production, and which entitlement gates it?
- Does `IMDMessageServicesAgent` expose a stable XPC interface or act mostly as an internal application-service helper?
- Which allowed `IMDPersistenceAgent` clients can mutate state versus query/index/read state?
- Which XPC service or daemon owns `IMDDistributedNotificationXPCEventStreamHandler` and `IMDXPCEventStreamHandler`?
