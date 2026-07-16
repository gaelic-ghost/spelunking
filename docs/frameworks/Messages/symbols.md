# Messages Symbols

## App Binary Dependencies

Verified with:

```sh
otool -L /System/Applications/Messages.app/Contents/MacOS/Messages
```

High-signal linked libraries:

- `/System/iOSSupport/System/Library/PrivateFrameworks/ChatKit.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/IMCore.framework`
- `/System/iOSSupport/System/Library/PrivateFrameworks/IMSharedUtilities.framework`
- `/System/Library/PrivateFrameworks/IDSFoundation.framework`
- `/System/Library/PrivateFrameworks/FTServices.framework`
- `/System/Library/PrivateFrameworks/FTClientServices.framework`
- `/System/Library/Frameworks/Contacts.framework`
- `/System/iOSSupport/System/Library/Frameworks/ContactsUI.framework`
- `/System/Library/Frameworks/UserNotifications.framework`

Inference: the macOS app is a UIKit/iOSSupport-style app shell using ChatKit and IMCore for much of the Messages-specific UI and model behavior, while macOS FT/IDS services provide transport/account support.

## Framework Availability Notes

Framework directories exist for `IMCore`, `IMDPersistence`, `IMDaemonCore`, `CallsXPC`, and related private frameworks, but direct binary paths such as `/System/Library/PrivateFrameworks/IMCore.framework/IMCore` were not present on this machine.

Use one of these next:

- dyld shared cache extraction for full live macOS symbols and Objective-C metadata
- SDK `.tbd` files for exported symbol names
- generated Swift interfaces when available
- runtime class listing from a small read-only helper

## Dyld Shared Cache Export Probe

Verified with:

```sh
dyld_info -exports -objc -all_dyld_cache
```

`dyld_info` can print exports from cache images, but not live Objective-C class/category metadata from cache dylibs on this machine.

Observed high-signal exports and classes:

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
- `OBJC_CLASS_$_IMCoreAutomationNotifications`
- `OBJC_CLASS_$_IMCoreRecentsMetadataBuilder`
- `OBJC_CLASS_$_IMCoreSpotlightUtilities`

## SDK `.tbd` Highlights

Verified from `MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMCore.framework/IMCore.tbd`.

`IMCore` metadata:

- install name: `/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore`
- targets: `x86_64-macos`, `arm64e-macos`
- current version: `800`
- Swift ABI version: `7`
- reexports: `InstantMessage.framework` and `IMFoundation.framework`

Observed exported Swift families:

- `Foundation.URL.IMCore` extensions for content type, MIME type, and relative file paths
- `Foundation.Date.IMCore` extensions for ISO-8601 parsing and nanosecond time intervals
- `IMCore.ImportExport`
- `ImportExportRecordIterating`
- `AttachmentRecordIterator`
- `ParticipantRecordIterator`
- `ConversationRecordIterator`
- batch/progress/export statistics types

Demangled type families:

- `ImportExportRecordExportIterating`: protocol with `recordType`, `exportOptions`, `exportStatistics`, `fetchStartingCountsForExport`, `hasCompletedCloudSync`, and `progress`.
- `AttachmentExportIterator`, `ParticipantExportIterator`, and `ConversationExportIterator`: async sequences with nested iterators and batches.
- iterator batches: include count, empty-state, progress, description, and record arrays.
- `ArchiveImportIterator`: async iterator over archive import batches, encodable/decodable.
- `MessageExportExclusionFilter`: filters for promotional, transactional, balloon plugin, junk, system, chat bot, default, deleted, expired, all cases, and business messages.

## Scripting Bridge Classes

Verified from `sdef /System/Applications/Messages.app`.

- `SMSApplication`
- `CKScriptCommand`
- `IMHandle`
- `IMAccount`
- `IMChat`
- `IMFileTransfer`

These names are scripting dictionary class bindings. They identify the Cocoa bridge types named by the dictionary, not a complete implementation class inventory.

## Constants And Notifications

Captured from SDK `.tbd` exports. These names prove exported constants/symbols exist; they do not yet prove delivery mechanism or posting behavior.

High-signal `IMCore` notification families:

- account lifecycle: `IMAccountActivatedNotification`, `IMAccountLoggedInNotification`, `IMAccountLoggedOutNotification`, `IMAccountLoginStatusChangedNotification`, `IMAccountRegistrationStatusChangedNotification`
- chat lifecycle: `IMChatMessageReceivedNotification`, `IMChatMessageSendFailedNotification`, `IMChatRegistryMessageSendingNotification`, `IMChatRegistryMessageSentNotification`, `IMChatRegistryDidRegisterChatNotification`, `IMChatRegistryDidUnregisterChatNotification`
- chat state: `IMChatUnreadCountChangedNotification`, `IMChatParticipantsDidChangeNotification`, `IMChatPropertiesChangedNotification`, `IMChatKeyTransparencyStatusChangedNotification`, `IMChatAutomaticTranslationChangedNotification`
- file transfer: `IMFileTransferCreatedNotification`, `IMFileTransferUpdatedNotification`, `IMFileTransferFinishedNotification`, `IMFileTransferRejectedNotification`, `IMFileTransferRemovedNotification`
- daemon/service: `IMDaemonWillConnectNotification`, `IMDaemonDidConnectNotification`, `IMDaemonDidDisconnectNotification`, `IMDaemonConnectionLostNotification`, `IMServiceDidConnectNotification`, `IMServiceDidDisconnectNotification`
- CloudKit/sync: `IMCloudKitFetchedSyncStatsNotification`, `IMCloudKitFetchedSyncDebuggingInfoNotification`, `IMRunAllCloudKitEventNotification`
- collaboration/nicknames/pinning: `IMCollaborationNoticesDidChangeNotification`, `IMNicknameDidChangeNotification`, `IMPinnedConversationsDidChangeNotification`

High-signal `IMDPersistence` and `IMDaemonCore` symbols:

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

High-signal `IMSharedUtilities` symbols:

- `IMMessageSentDistributedNotification`
- `IMSharedMessageSendingTextMessageAvailabilityDidChangeNotification`
- `IMOneTimeCodesUpdatedNotification`
- `IMIncomingMessageAlertFiltrationChangedNotification`
- `IMUnreadCountControllerDidUpdateNotification`
- `IMSettingsKeepMessagesChangedNotification`
- `IMSettingsFilterUnknownSendersChangedNotification`
- `IMTranslationLanguageStatusChangedNotification`
- `IMStewieConversationContextChangedNotification`
- `SatelliteStatusActiveNotification`

Next sources:

- `notifyutil -l` filtered for live Darwin notification names
- log stream predicates for Messages subsystem names
- controlled runtime observer helper to classify notification center vs Darwin notify behavior

## Version Differences

Known first-pass difference:

- The active macOS 26.5.2 private framework directories often lack direct root binaries.
- The macOS 27.0 SDK exposes `.tbd` symbol metadata for private frameworks including `IMCore`.

No semantic symbol diff has been performed yet.
