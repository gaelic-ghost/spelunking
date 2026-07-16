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
- `research/Phone/notifications/runtime-string-constants-telephonyutilities-macos-26.5.2.json`
- `research/Phone/notifications/runtime-string-constants-callhistory-darwin-macos-26.5.2.json`
- `research/Phone/notifications/runtime-string-constants-callhistory-nsstring-macos-26.5.2.json`
- `research/Phone/notifications/observer-app-open-macos-26.5.2.json`

Environment:

- active OS: macOS 26.5.2 build 25F84
- SDK comparison: macOS 27.0 SDK from `/Applications/Xcode-beta.app`

Important limitation: this macOS `notifyutil` does not support a list-all operation. Targeted `notifyutil -g` probes returned `0` for real-looking keys and for a random control key, so those probes are not proof that a notification exists or has an active publisher.

## Observer Baseline

Verified with the local `spelunk notification-observe` helper, which registers selected Darwin notify and distributed-notification names for a bounded duration and records notification names/timestamps only, not payload values.

During a six-second observation window while opening Phone in the background, these watches registered successfully and observed zero events:

- Darwin notify: `com.apple.CallHistoryPluginHelper.launchnotification`
- Darwin notify: `com.apple.callhistorysync.idslaunchnotification`
- Darwin notify: `com.apple.callhistory.notification.call-interactions-changed`
- Darwin notify: `com.apple.telephonyutilities.callservicesd.fakeincomingmessage`
- Darwin notify: `com.apple.telephonyutilities.callservicesd.fakeoutgoingmessage`
- distributed notification center: `com.apple.callhistory.save.distributed.notification`
- distributed notification center: `kCallHistoryDatabaseChangedNotification`

Interpretation: app activation alone did not post the watched names during this capture. This is narrow negative evidence only; it does not rule out posts during call-service state changes, call-history writes, FaceTime activity, fake-message test triggers, IDS sync activity, or controlled call/voicemail flows.

## Runtime String Values

Verified with the local `spelunk string-constants` helper, which loads a framework image read-only and resolves selected exported string constants with `dlsym`.

### TelephonyUtilities

| Symbol | Runtime value |
| --- | --- |
| `TUCallCenterCallConnectedNotification` | `TUCallCenterCallConnectedNotification` |
| `TUCallCenterCallStatusChangedNotification` | `TUCallCenterCallStatusChangedNotification` |
| `TUCallCenterCallStartedConnectingNotification` | `TUCallCenterCallStartedConnectingNotification` |
| `TUCallCenterCallerIDChangedNotification` | `TUCallCenterCallerIDChangedNotification` |
| `TUCallCenterConferenceParticipantsChangedNotification` | `TUCallCenterConferenceParticipantsChangedNotification` |
| `TUCallIsOnHoldChangedNotification` | `TUCallIsOnHoldChangedNotification` |
| `TUCallIsSendingAudioChangedNotification` | `TUCallIsSendingAudioChangedNotification` |
| `TUCallIsSendingVideoChangedNotification` | `TUCallIsSendingVideoChangedNotification` |
| `TUCallIsUplinkMutedChangedNotification` | `TUCallIsUplinkMutedChangedNotification` |
| `TUCallRecordingStateChangedNotification` | `TUCallRecordingStateChangedNotification` |
| `TUCallTranslationStateChangedNotification` | `TUCallTranslationStateChangedNotification` |
| `TUCallHistoryControllerRecentCallsDidChangeNotification` | `TUCallHistoryControllerRecentCallsDidChangeNotification` |
| `TUCallHistoryControllerUnreadCallCountDidChangeNotification` | `TUCallHistoryControllerUnreadCallCountDidChangeNotification` |
| `TUCallCapabilitiesFaceTimeAvailabilityChangedNotification` | `TUCallCapabilitiesFaceTimeAvailabilityChangedNotification` |
| `TUCallCapabilitiesSupportsTelephonyCallsChangedNotification` | `TUCallCapabilitiesSupportsTelephonyCallsChangedNotification` |
| `TUCallCapabilitiesWiFiCallingChangedNotification` | `TUCallCapabilitiesWiFiCallingChangedNotification` |
| `TUCallCapabilitiesRelayCallingChangedNotification` | `TUCallCapabilitiesRelayCallingChangedNotification` |
| `TUConversationManagerDidBecomeAvailableNotification` | `TUConversationManagerDidBecomeAvailableNotification` |
| `TUCallProviderManagerProvidersChangedNotification` | `TUCallProviderManagerProvidersChangedNotification` |
| `TUCallConversationChangedNotification` | `TUCallConversationChangedNotification` |
| `TUPrivacyRulesChangedNotification` | `com.apple.TelephonyUtilities.TUPrivacyManager.RulesChanged` |

### CallHistory

| Symbol | Runtime value | Representation |
| --- | --- | --- |
| `CHCallInteractionsDidChangeDarwinNotification` | `com.apple.callhistory.notification.call-interactions-changed` | C string pointer |
| `kCallHistoryCallRecordInsertedNotification` | `kCallHistoryCallRecordInsertedNotification` | NSString global |
| `kCallHistoryDatabaseChangedNotification` | `kCallHistoryDatabaseChangedNotification` | NSString global |
| `kCallHistoryDatabasePluginUpdateNotification` | `kCallHistoryDatabasePluginUpdateNotification` | NSString global |
| `kCallHistoryDatabaseRemoteUpdateReadNotification` | `kCallHistoryDatabaseRemoteUpdateReadNotification` | NSString global |
| `kCallHistorySyncHelperReadyNotification` | `kCallHistorySyncHelperReadyNotification` | NSString global |
| `kCallHistoryTimersChangedNotification` | `kCallHistoryTimersChangedNotification` | NSString global |

Inference: `CHCallInteractionsDidChangeDarwinNotification` is stronger Darwin-notify evidence than naming alone because its live string value is a reverse-DNS Darwin-style key. The `kCallHistory*` names resolve as NSString globals whose runtime values match their exported symbol names; delivery still requires observer evidence.

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

Verified by exported symbol naming and runtime string resolution, not by observed post:

- `CHCallInteractionsDidChangeDarwinNotification`

Inference: the symbol name explicitly indicates a Darwin notification constant, and the live string value is `com.apple.callhistory.notification.call-interactions-changed`. The app-open observer baseline did not observe a post, so delivery timing and publisher remain open.

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

- What exact string values do lower-level `callservicesd` and PhoneAppIntents private notification or XPC constants hold beyond this first focused pass?
- Which plain `TU*Notification` constants are posted through `NotificationCenter`, `DistributedNotificationCenter`, Darwin notify, XPC callbacks, or private observer abstractions?
- Which names are posted by `callservicesd` versus `callhistoryd` versus Phone.app or FaceTime components?
- Which call-history constants correspond to database changes versus UI-facing recents updates?
- What payload keys are present for call status, call history, voicemail, and conversation notifications in controlled call or database-change flows?
