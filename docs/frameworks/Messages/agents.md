# Messages Agents And Services

## Scope

This page maps the local agents, XPC services, app extensions, and brokered service edges observed for `Messages.app` on macOS 26.5.2.

Raw evidence:

- `research/Messages/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Messages/surfaces/bundle-surfaces-macos-26.5.2.txt`
- `research/Messages/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Messages/runtime/open-logstream-macos-26.5.2.txt`

## LaunchAgents

| Label | Program | Observed role |
| --- | --- | --- |
| `com.apple.imagent` | `IMCore.framework/imagent.app` | IM account, IDS, chat, notification, Spotlight, incoming-call-filter, and Madrid wake broker. |
| `com.apple.imautomatichistorydeletionagent` | `IMDPersistence.framework/IMAutomaticHistoryDeletionAgent.app` | Scheduled Messages retention/history cleanup agent. |
| `com.apple.imcore.imtransferagent` | `IMTransferServices.framework/IMTransferAgent.app` | File-transfer broker with IDS transfer launch notification. |

## XPC Services

| Bundle identifier | Visible name | Observed role |
| --- | --- | --- |
| `com.apple.imdmessageservices.IMDMessageServicesAgent` | Message Services Agent | Message routing/state service. |
| `com.apple.imdpersistence.IMDPersistenceAgent` | Messages Database Agent | Database and persistence broker with explicit Apple-signed allowed-client list. |
| `com.apple.imtranscoding.IMTranscoderAgent` | Messages Transcoding Agent | Media transcoding service with GPU access. |

`IMDPersistenceAgent.xpc` allowed clients include Apple-signed `MobileSMS.spotlight`, `imagent`, `IMDMessageServicesAgent`, Safari variants, `iChat`, `AddressBook.FaceTimeService`, `imtool`, `assistantd`, `ContactsAgent`, Messages Assistant and Storage Management extensions, Control Center, Photos, Game Center, FaceTime, Finder, SocialLayer, CoreDuet, People, Suggestd, OmniSearch, diagnostics, and internal tools.

Inference: local database access is intentionally brokered through a privileged Apple service and an allowlist, not exposed as a general third-party IPC contract.

## App Extensions And Plugins

| Bundle ID | Bundle | Role |
| --- | --- | --- |
| `com.apple.MobileSMS.MessagesActionExtension` | `MessagesActionExtension.appex` | Messages action extension bundle. |
| `com.apple.messages.AssistantExtension` | `Messages Assistant Extension.appex` | Siri/Intents handler. |
| `com.apple.messages.ReplyExtension` | `Messages Reply Extension.appex` | Share-services reply bridge. |
| `com.apple.messages.ShareExtension` | `Messages Share Extension.appex` | Share-services compose bridge. |
| `com.apple.messages.StorageManagementExtension` | `Messages Storage Management Extension.appex` | Storage management and database/storage reader. |
| `com.apple.MobileSMS.MessagesPluginNotificationExtension` | `MessagesPluginNotificationExtension.appex` | User-notification content extension for custom plugin notifications. |
| `com.apple.MessagesAppKitBridge` | `MessagesAppKitBridge.bundle` | AppKit bridge bundle. |
| `com.apple.iChatDockTilePlugIn` | `iChatDockTile.docktileplugin` | Dock tile plugin. |

## Runtime Activation Edges

The bounded app-open log captured:

- `Messages.app` foreground scene activation for `com.apple.MobileSMS`
- `imagent` mark-read work
- `IMDPersistenceAgent` command-dispatcher and database calls
- App Intents focus-filter initialization
- CoreSpotlight indexing batches
- communication-filter cache checks

Inference: visible activation alone is enough to involve the app process, `imagent`, the persistence agent, indexing, App Intents, and communication filtering. This supports a multi-agent architecture rather than a single-process local app model.

## Open Questions

- Which XPC messages are exchanged between `Messages.app`, `imagent`, `IMDPersistenceAgent`, `IMDMessageServicesAgent`, BlastDoor support, and transfer/transcoding agents?
- Which agent calls are triggered only by app activation versus message selection, send, receive, notification response, attachment download, or AppleScript?
- Which allowed clients exercise read-only database access versus mutation?

