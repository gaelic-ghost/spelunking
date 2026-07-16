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

Framework directories exist for `IMCore`, `IMDPersistence`, `IMDaemonCore`, `MessagesKit`, and related private frameworks. Many root Mach-O paths are dyld-cache install names rather than ordinary on-disk files; `dlopen` can still resolve some of them through the active dyld shared cache.

Use these sources together:

- dyld shared cache extraction for full live macOS symbols and Objective-C metadata
- SDK `.tbd` files for exported symbol names
- generated Swift interfaces when available
- runtime class listing from a small read-only helper

## Generated Interface Status

No generated private framework interfaces have been produced yet.

Raw capture:

- `research/Messages/runtime/dyld-cache-interface-boundary-macos-26.5.2.txt`

Local tool availability checked on 2026-07-16:

- `dyld_shared_cache_util`: not found on PATH or through `xcrun --find`
- `class-dump`: not found
- `class-dump-swift`: not found
- `swift-reflection-dump`: not found
- `jtool2`: not found
- available: `dyld_info`, `nm`, `otool`, `swift-api-digester`, and `swift-symbolgraph-extract`

Live dyld shared cache map entries confirmed these target images in the active arm64e shared cache:

- `/System/Library/PrivateFrameworks/IMDPersistence.framework/Versions/A/IMDPersistence`
- `/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore`
- `/System/Library/PrivateFrameworks/IMDaemonCore.framework/Versions/A/IMDaemonCore`
- `/System/Library/PrivateFrameworks/MessagesKit.framework/Versions/A/MessagesKit`
- `/System/iOSSupport/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore`
- `/System/iOSSupport/System/Library/PrivateFrameworks/IMDPersistence.framework/Versions/A/IMDPersistence`

SDK representation checked in the macOS 27.0 SDK:

- `IMDPersistence.framework` exposes `IMDPersistence.tbd`
- `IMDaemonCore.framework` exposes `IMDaemonCore.tbd`
- `MessagesKit.framework` exposes `MessagesKit.tbd`

No `.swiftinterface`, `.private.swiftinterface`, or `.swiftmodule` files were found for the selected Messages private frameworks in the checked macOS 27.0 SDK private framework directories or the active `/System/Library/PrivateFrameworks` directories.

Boundary: the current repository has live dyld-cache residency evidence, exported symbols, `.tbd` metadata, and Objective-C runtime metadata, but not full generated headers/interfaces for these private frameworks. The next interface-generation lane needs a dyld shared cache extractor, class-dump-capable Objective-C metadata path, or another equivalent metadata tool before the remaining checklist item can be closed.

## Objective-C Runtime Capture

Raw captures:

- `research/Messages/runtime/objc-runtime-im-macos-26.5.2.json`
- `research/Messages/runtime/objc-runtime-imcore-macos-26.5.2.json`
- `research/Messages/runtime/objc-runtime-imd-messageskit-macos-26.5.2.json`

The narrow `IM*` runtime capture loaded `IMCore`, `IMSharedUtilities`, and `IMFoundation` and found:

- 888 matching classes
- 150 matching protocols

Notable observed classes include:

- `IMAccount`, `IMAccountController`, `IMHandle`
- `IMChat`, `IMChatHistoryController`, `IMChatRegistry`, `IMMessage`
- `IMAttachment`, `IMAttachmentBlastdoor`
- `IMDDatabase`, `IMDDatabaseClient`, `IMDChatRecord`, `IMDMessageRecord`, `IMDAttachmentRecord`
- `IMDCoreSpotlightBaseIndexer`, `IMDCoreSpotlightMessageBodyIndexer`, `IMDCoreSpotlightSearchableItemGenerator`
- `IMAutomation`, `IMAutomationMessageSend`, `IMAutomationBatchMessageOperations`, `IMCoreAutomationHook`, `IMCoreAutomationNotifications`

Selector/property examples from the capture:

- `IMAccount`: aliases, registration state, relay capability, login state, service name, block-list, buddy-list, profile, and `canSendMessages`
- `IMHandle`: canonical/person-handle style identity surface
- `IMChat` and chat-item classes: conversation and transcript model surfaces
- `IMD*`: persistence records, batch fetchers, Spotlight indexers, CloudKit/indexing lifecycle helpers

The broader `IM*` plus `CK*` capture is retained because Messages links CloudKit-heavy surfaces, but most `CK*` entries are generic CloudKit runtime classes and should not be counted as Messages-specific without additional filtering.

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

- launchd notify trigger snapshots and targeted `notifyutil -g` probes
- log stream predicates for Messages subsystem names
- controlled runtime observer helper to classify notification center vs Darwin notify behavior

See `notifications.md` for the current delivery-mechanism classification.

## Version Differences

Known first-pass difference:

- The active macOS 26.5.2 private framework directories often lack direct root binaries.
- The macOS 27.0 SDK exposes `.tbd` symbol metadata for private frameworks including `IMCore`.

No semantic symbol diff has been performed yet.
