# Messages Notifications

## Scope

This page classifies Messages and IM notification-like names by the delivery mechanism that is currently supported by local evidence.

Evidence classes:

- Verified: launchd declares the notification as a launch trigger, or the symbol name explicitly carries a delivery mechanism such as `Distributed` or `Darwin`.
- Inferred: naming and surrounding framework context strongly suggest a mechanism, but no observer or log proof has confirmed delivery.
- Unclassified: exported notification constants exist, but the first pass has not proven how they are delivered.

## Evidence

Raw captures:

- `research/Messages/notifications/sdk-notification-symbols-macos-27.0.txt`
- `research/Messages/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Messages/notifications/notifyutil-probes-macos-26.5.2.txt`
- `research/Messages/notifications/runtime-string-constants-imcore-macos-26.5.2.json`
- `research/Messages/notifications/runtime-string-constants-imdpersistence-macos-26.5.2.json`

Environment:

- active OS: macOS 26.5.2 build 25F84
- SDK comparison: macOS 27.0 SDK from `/Applications/Xcode-beta.app`

Important limitation: this macOS `notifyutil` does not support a list-all operation. Targeted `notifyutil -g` probes returned `0` for real-looking keys and for a random control key, so those probes are not proof that a notification exists or has an active publisher.

## Runtime String Values

Verified with the local `spelunk string-constants` helper, which loads a framework image read-only and resolves selected exported `NSString` constant globals with `dlsym`.

### IMCore

| Symbol | Runtime value |
| --- | --- |
| `IMMessageSentDistributedNotification` | `IMMessageSentDistributedNotification` |
| `IMAccountActivatedNotification` | `__kIMAccountActivatedNotification` |
| `IMAccountLoggedInNotification` | `__kIMAccountLoggedInNotification` |
| `IMAccountLoggedOutNotification` | `__kIMAccountLoggedOutNotification` |
| `IMAccountLoginStatusChangedNotification` | `__kIMAccountLoginStatusChangedNotification` |
| `IMAccountRegistrationStatusChangedNotification` | `__kIMAccountRegistrationStatusChangedNotification` |
| `IMChatMessageReceivedNotification` | `__kIMChatMessageReceivedNotification` |
| `IMChatMessageSendFailedNotification` | `__kIMChatMessageSendFailedNotification` |
| `IMChatRegistryMessageSendingNotification` | `__kIMChatRegistryMessageSendingNotification` |
| `IMChatRegistryMessageSentNotification` | `__kIMChatRegistryMessageSentNotification` |
| `IMChatUnreadCountChangedNotification` | `__kIMChatUnreadCountChangedNotification` |
| `IMFileTransferCreatedNotification` | `__kIMFileTransferCreatedNotification` |
| `IMFileTransferUpdatedNotification` | `__kIMFileTransferUpdatedNotification` |
| `IMFileTransferFinishedNotification` | `__kIMFileTransferFinishedNotification` |
| `IMDaemonWillConnectNotification` | `__kIMDaemonWillConnectNotification` |
| `IMDaemonDidConnectNotification` | `__kIMDaemonDidConnectNotification` |
| `IMDaemonDidDisconnectNotification` | `__kIMDaemonDidDisconnectNotification` |
| `IMDaemonConnectionLostNotification` | `__kIMDaemonConnectionLostNotification` |
| `IMServiceDidConnectNotification` | `ServiceDidConnect` |
| `IMServiceDidDisconnectNotification` | `ServiceDidDisconnect` |
| `IMCloudKitFetchedSyncStatsNotification` | `IMCloudKitFetchedSyncStatsNotification` |
| `IMCollaborationNoticesDidChangeNotification` | `__kIMCollaborationNoticesDidChangeNotification` |
| `IMNicknameDidChangeNotification` | `__kIMNicknameDidChangeNotification` |
| `IMPinnedConversationsDidChangeNotification` | `__kIMPinnedConversationsDidChangeNotification` |

### IMDPersistence

Resolved from `/System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence`:

| Symbol | Runtime value |
| --- | --- |
| `IMDPersistenceServiceResettingNotification` | `IMDPersistenceServiceResettingNotification` |
| `IMDSMSFailedToSendNotification` | `__kIMDSMSFailedToSendNotification` |
| `IMDSMSMarkAsReadCompletedNotification` | `__kIMDSMSMarkAsReadCompletedNotification` |

The same runtime pass did not resolve these SDK-observed names as exported `NSString` globals from the loaded IMDPersistence image: `IMDMessageRecordRetractNotification`, `IMDNotificationsPostNotification`, `IMDNotificationsPostUrgentNotification`, `IMDNotificationsRetractNotification`, `IMDNotificationsUpdatePostedNotification`, `IMDChatRegistryAddedChatNotification`, `IMDFileTransferCreatedNotification`, `IMDFileTransferUpdatedNotification`, and `IMDSMSMessageSentNotification`.

Inference: SDK symbol scanning can surface names that are not directly resolvable as live exported NSString globals by `dlsym` on this OS image. Treat those unresolved names as weaker evidence until a dyld-cache metadata pass or runtime caller evidence explains their representation.

## Verified Launch Triggers

These names are verified from launchd plists as notify-triggered or launch-event-triggered surfaces:

| Name | Owner | Evidence | Meaning |
| --- | --- | --- | --- |
| `com.apple.private.IMCore.LoggedIntoHSA2` | `com.apple.imagent` | `LaunchEvents` entry | Auth/account state can wake `imagent`. The plist names the event but does not expose payload shape. |
| `com.apple.imautomatichistorydeletionagent.prefchange` | `com.apple.imautomatichistorydeletionagent` | `com.apple.notifyd.matching` trigger | Preference changes can wake the automatic history deletion agent. |
| `com.apple.idstransfers.idslaunchnotification` | `com.apple.imcore.imtransferagent` | `com.apple.notifyd.matching` trigger | IDS transfer activity can wake the IM transfer agent. |

Related verified mach services:

- `com.apple.aps.imagent`
- `com.apple.corespotlight.daemon.messages`
- `com.apple.imagent.cache-delete`
- `com.apple.imagent.desktop.auth`
- `com.apple.madrid-idswake`
- `com.apple.madrid.lite-idswake`
- `com.apple.usernotifications.delegate.com.apple.iChat`
- `com.apple.usernotifications.delegate.com.apple.MobileSMS`
- `com.apple.imtransferservices.IMTransferAgent`

## Mechanism Classification

### Launchd / notifyd

Verified launchd notify triggers:

- `com.apple.imautomatichistorydeletionagent.prefchange`
- `com.apple.idstransfers.idslaunchnotification`

`com.apple.private.IMCore.LoggedIntoHSA2` is verified as a launch event in `com.apple.imagent.plist`, but the plist key is not under `com.apple.notifyd.matching`; treat it as a launch-event surface rather than a confirmed notifyd matching key until lower-level launchd evidence classifies it.

### Distributed Notification

Verified by exported symbol naming, not by an observed post:

- `IMMessageSentDistributedNotification`

Inference: the `Distributed` suffix likely means an `NSDistributedNotificationCenter`-style cross-process notification. A future observer pass should confirm the exact notification name string and payload behavior.

### Local / In-Process Notification Constants

Unclassified exported constants include large account, chat, transfer, daemon, and CloudKit families:

- account lifecycle: `IMAccountActivatedNotification`, `IMAccountLoggedInNotification`, `IMAccountLoggedOutNotification`, `IMAccountLoginStatusChangedNotification`, `IMAccountRegistrationStatusChangedNotification`
- chat lifecycle: `IMChatMessageReceivedNotification`, `IMChatMessageSendFailedNotification`, `IMChatRegistryMessageSendingNotification`, `IMChatRegistryMessageSentNotification`, `IMChatRegistryDidRegisterChatNotification`, `IMChatRegistryDidUnregisterChatNotification`
- chat state: `IMChatUnreadCountChangedNotification`, `IMChatParticipantsDidChangeNotification`, `IMChatPropertiesChangedNotification`, `IMChatKeyTransparencyStatusChangedNotification`, `IMChatAutomaticTranslationChangedNotification`
- file transfer: `IMFileTransferCreatedNotification`, `IMFileTransferUpdatedNotification`, `IMFileTransferFinishedNotification`, `IMFileTransferRejectedNotification`, `IMFileTransferRemovedNotification`
- daemon/service: `IMDaemonWillConnectNotification`, `IMDaemonDidConnectNotification`, `IMDaemonDidDisconnectNotification`, `IMDaemonConnectionLostNotification`, `IMServiceDidConnectNotification`, `IMServiceDidDisconnectNotification`
- CloudKit/sync: `IMCloudKitFetchedSyncStatsNotification`, `IMCloudKitFetchedSyncDebuggingInfoNotification`, `IMRunAllCloudKitEventNotification`
- collaboration/nicknames/pinning: `IMCollaborationNoticesDidChangeNotification`, `IMNicknameDidChangeNotification`, `IMPinnedConversationsDidChangeNotification`

Inference: most plain `*Notification` exported constants are probably Foundation notification names used by in-process controllers, daemon clients, or private framework objects. Do not treat them as Darwin notify keys without observer evidence.

### IMD Persistence / Daemon Notification Symbols

Unclassified exported symbols:

- `IMDMessageRecordRetractNotification`
- `IMDNotificationsPostNotification`
- `IMDNotificationsPostUrgentNotification`
- `IMDNotificationsRetractNotification`
- `IMDNotificationsUpdatePostedNotification`
- `IMDPersistenceServiceResettingNotification`
- `IMDSMSFailedToSendNotification`
- `IMDSMSMarkAsReadCompletedNotification`
- `IMDChatRegistryAddedChatNotification`
- `IMDFileTransferCreatedNotification`
- `IMDFileTransferUpdatedNotification`
- `IMDSMSMessageSentNotification`

Inference: the `IMDNotifications*` names likely relate to notification posting or retraction work performed by daemon or persistence components, but the first pass does not prove whether they are Foundation notification names, XPC message names, user-notification identifiers, or internal constants.

## Open Questions

- What exact string value do the remaining unresolved IMD exported names hold, if they exist as constants rather than selectors, Swift metadata, or non-exported data?
- Which plain `IM*Notification` constants are posted through `NotificationCenter`, `DistributedNotificationCenter`, Darwin notify, XPC callbacks, or private observer abstractions?
- Which notification names are visible outside Apple-signed clients, if any?
- Which names are posted by `imagent` versus `IMDPersistenceAgent` versus Messages.app?
- What payload keys are present when chat, message, and file-transfer notifications fire?
