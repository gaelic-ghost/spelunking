# Phone Notifications

## Scope

This page classifies Phone, TelephonyUtilities, CallHistory, and call-service notification-like names by the delivery mechanism currently supported by local evidence.

Evidence classes:

- Verified: launchd declares the notification as a launch trigger, or the symbol name explicitly carries a delivery mechanism such as `Distributed` or `Darwin`.
- Inferred: naming and surrounding framework context strongly suggest a mechanism, but no observer or log proof has confirmed delivery.
- Unclassified: exported notification constants exist, but the first pass has not proven how they are delivered.

## Evidence

Raw captures:

- `research/Phone/notifications/sdk-notification-symbols-macos-27.0.txt`
- `research/Phone/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Phone/notifications/notifyutil-probes-macos-26.5.2.txt`

Environment:

- active OS: macOS 26.5.2 build 25F84
- SDK comparison: macOS 27.0 SDK from `/Applications/Xcode-beta.app`

Important limitation: this macOS `notifyutil` does not support a list-all operation. Targeted `notifyutil -g` probes returned `0` for real-looking keys and for a random control key, so those probes are not proof that a notification exists or has an active publisher.

## Verified Launch Triggers

These names are verified from launchd plists as notify-triggered or launch-event-triggered surfaces:

| Name | Owner | Evidence | Meaning |
| --- | --- | --- | --- |
| `com.apple.CallHistoryPluginHelper.launchnotification` | `com.apple.CallHistoryPluginHelper` | `com.apple.notifyd.matching` trigger | CallHistory plugin helper can be woken by a notifyd key. |
| `com.apple.callhistorysync.idslaunchnotification` | `com.apple.CallHistorySyncHelper` | `com.apple.notifyd.matching` trigger | IDS call-history sync activity can wake the sync helper. |
| `com.apple.mobile.keybagd.first_unlock` | `com.apple.callintelligenced` | `com.apple.notifyd.matching` trigger | first-unlock state can wake call intelligence. |
| `com.apple.telephonyutilities.callservicesd.fakeincomingmessage` | `com.apple.telephonyutilities.callservicesd` | `com.apple.notifyd.matching` trigger | callservicesd has a fake incoming-message test/debug wake trigger. |
| `com.apple.telephonyutilities.callservicesd.fakeoutgoingmessage` | `com.apple.telephonyutilities.callservicesd` | `com.apple.notifyd.matching` trigger | callservicesd has a fake outgoing-message test/debug wake trigger. |
| `kFaceTimeChangedNotification` | `com.apple.telephonyutilities.callservicesd` | `com.apple.notifyd.matching` trigger | FaceTime settings/state changes can wake callservicesd. |
| `kFZACAppBundleIdentifierLaunchNotification` | `com.apple.telephonyutilities.callservicesd` | `com.apple.notifyd.matching` trigger | FaceTime audio calling launch notification can wake callservicesd. |
| `kFZVCAppBundleIdentifierLaunchNotification` | `com.apple.telephonyutilities.callservicesd` | `com.apple.notifyd.matching` trigger | FaceTime video calling launch notification can wake callservicesd. |
| `kCTSettingCallCapabilitiesChangedNotification` | `com.apple.telephonyutilities.callservicesd` | `com.apple.CTTelephonyCenter` launch event | CoreTelephony call-capability changes can wake callservicesd. |
| `com.apple.callhistory.save.distributed.notification` | `com.apple.telephonyutilities.callservicesd` | `com.apple.CTTelephonyCenter` launch event | Call-history save events can wake callservicesd through a distributed-notification-style launch event. |

Related verified mach services:

- `com.apple.callhistoryd.service`
- `com.apple.conversation.history`
- `com.apple.CallHistoryPluginHelper`
- `com.apple.CallHistorySyncHelper`
- `com.apple.CallHistorySyncHelper.aps`
- `com.apple.callintelligenced.service`
- `com.apple.telephonyutilities.callservicesdaemon.callhistorycontroller`
- `com.apple.telephonyutilities.callservicesdaemon.callhistorymanager`
- `com.apple.telephonyutilities.callservicesdaemon.callstatecontroller`
- `com.apple.telephonyutilities.callservicesdaemon.conversationmanager`
- `com.apple.telephonyutilities.callservicesdaemon.callprovidermanager`
- `com.apple.telephonyutilities.callservicesdaemon.usernotificationprovider`
- `com.apple.usernotifications.delegate.com.apple.facetime`
- `com.apple.usernotifications.delegate.com.apple.mobilephone`

## Mechanism Classification

### Launchd / notifyd

Verified notifyd matching triggers:

- `com.apple.CallHistoryPluginHelper.launchnotification`
- `com.apple.callhistorysync.idslaunchnotification`
- `com.apple.mobile.keybagd.first_unlock`
- `com.apple.telephonyutilities.callservicesd.fakeincomingmessage`
- `com.apple.telephonyutilities.callservicesd.fakeoutgoingmessage`
- `kFaceTimeChangedNotification`
- `kFZACAppBundleIdentifierLaunchNotification`
- `kFZVCAppBundleIdentifierLaunchNotification`

### CTTelephonyCenter / Distributed Launch Events

Verified as launchd `LaunchEvents` entries under `com.apple.CTTelephonyCenter`:

- `kCTSettingCallCapabilitiesChangedNotification`
- `com.apple.callhistory.save.distributed.notification`

Inference: these are not ordinary app-level NotificationCenter constants. They are system telephony or distributed-event wake surfaces consumed by launchd for `callservicesd`.

### Darwin Notification Naming

Verified by exported symbol naming, not by observed post:

- `CHCallInteractionsDidChangeDarwinNotification`

Inference: the symbol name explicitly indicates a Darwin notification constant, but this pass did not recover the constant's string value or observe a post.

### Local / In-Process Notification Constants

Unclassified exported constants include large call center, call state, provider, history, audio/video, and privacy families:

- call center: `TUCallCenterCallConnectedNotification`, `TUCallCenterCallStatusChangedNotification`, `TUCallCenterCallStartedConnectingNotification`, `TUCallCenterCallerIDChangedNotification`, `TUCallCenterConferenceParticipantsChangedNotification`
- call state: `TUCallIsOnHoldChangedNotification`, `TUCallIsSendingAudioChangedNotification`, `TUCallIsSendingVideoChangedNotification`, `TUCallIsUplinkMutedChangedNotification`, `TUCallRecordingStateChangedNotification`, `TUCallTranslationStateChangedNotification`
- call history: `TUCallHistoryControllerRecentCallsDidChangeNotification`, `TUCallHistoryControllerUnreadCallCountDidChangeNotification`
- capabilities: `TUCallCapabilitiesFaceTimeAvailabilityChangedNotification`, `TUCallCapabilitiesSupportsTelephonyCallsChangedNotification`, `TUCallCapabilitiesWiFiCallingChangedNotification`, `TUCallCapabilitiesRelayCallingChangedNotification`
- conversation/provider: `TUConversationManagerDidBecomeAvailableNotification`, `TUCallProviderManagerProvidersChangedNotification`, `TUCallConversationChangedNotification`
- audio/video devices: `TUAudioSystemUplinkMuteStatusChangedNotification`, `TUVideoDeviceControllerDeviceBecameAvailableNotification`, `TUVideoDeviceControllerDidStartPreviewNotification`, `TUVideoDeviceControllerUserPreferredCameraChangedNotification`
- privacy/safety: `TUPrivacyRulesChangedNotification`, `TUCallScreeningDidFinishAnnouncementNotification`

Inference: most plain `TU*Notification` exported constants are likely Foundation notification names used inside TelephonyUtilities clients/controllers. Do not treat them as Darwin notify keys without observer evidence.

### CallHistory Constants

Unclassified or naming-classified exported constants:

- Darwin by symbol naming: `CHCallInteractionsDidChangeDarwinNotification`
- unclassified: `kCallHistoryCallRecordInsertedNotification`
- unclassified: `kCallHistoryDatabaseChangedNotification`
- unclassified: `kCallHistoryDatabasePluginUpdateNotification`
- unclassified: `kCallHistoryDatabaseRemoteUpdateReadNotification`
- unclassified: `kCallHistorySyncHelperReadyNotification`
- unclassified: `kCallHistoryTimersChangedNotification`

## Open Questions

- What exact string value does each exported constant hold?
- Which plain `TU*Notification` constants are posted through `NotificationCenter`, `DistributedNotificationCenter`, Darwin notify, XPC callbacks, or private observer abstractions?
- Which names are posted by `callservicesd` versus `callhistoryd` versus Phone.app or FaceTime components?
- Which call-history constants correspond to database changes versus UI-facing recents updates?
- What payload keys are present for call status, call history, voicemail, and conversation notifications?
