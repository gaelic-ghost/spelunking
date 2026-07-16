# Phone XPC Ownership

## Scope

This page correlates Phone, TelephonyUtilities, CallHistory, FaceTime, voicemail, and CallKit launchd mach services, XPC/extension plists, app entitlements, and observed private protocol families on macOS 26.5.2.

This is not a traffic trace. The mappings below are evidence-backed ownership hypotheses unless a row says the relationship is directly observed in a plist or entitlement.

## Evidence

Raw capture:

- `research/Phone/runtime/xpc-ownership-macos-26.5.2.txt`

Related evidence:

- `research/Phone/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Phone/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Phone/runtime/hook-surface-inventory-macos-26.5.2.json`
- [Phone agents](agents.md)
- [Phone hooks](hooks.md)

Boundary: launchd plists prove registered mach services and launch events. Entitlements prove the app or intent handler can request named mach services or private privileges. Runtime protocol names prove selectors exist. None of these alone proves a selector was invoked during the captured session.

## Service Ownership Map

| Owner | Observed service evidence | Correlated hook families | Confidence |
| --- | --- | --- | --- |
| `callservicesd` | LaunchAgent `com.apple.telephonyutilities.callservicesd`; broad mach services under `com.apple.telephonyutilities.callservicesdaemon.*`, CallKit host services, FaceTime/phone IDS wake services, conversation manager hosts, user-notification delegates | `TU*XPCServer`, `TU*XPCClient`, private `CX*HostProtocol`, user notification provider, conversation/provider manager protocols | High for call-services broker ownership; medium for specific selector-to-service binding. |
| `callhistoryd` | LaunchAgent `com.apple.callhistoryd`; mach services `com.apple.callhistoryd.service` and `com.apple.conversation.history` | `CHManager`, `CallHistory.*` store/client/data-source classes, `CallDB*` families | High for persisted recents/conversation-history brokering; medium for exact class ownership. |
| `CallHistoryPluginHelper` | LaunchAgent and mach service `com.apple.CallHistoryPluginHelper`; notify launch trigger | CallHistory plugin/helper paths | Medium. Service exists and `Phone.app` can look it up; hook class mapping is not decoded. |
| `CallHistorySyncHelper` | LaunchAgent and mach services `com.apple.CallHistorySyncHelper` and `.aps`; IDS launch notification | Call-history sync and APS/IDS sync paths | Medium. Service role is observed; protocol surface is not decoded. |
| `callintelligenced` | LaunchAgent and mach service `com.apple.callintelligenced.service`; first-unlock launch trigger | Call screening/intelligence-adjacent features | Low to medium. Service exists; selectors were not mapped in this pass. |
| `facetimemessagestored` | LaunchAgent and mach services for APS, service, video messaging, and FaceTime messaging IDS wake | FaceTime message store, voicemail/video messaging adjacency | Medium. Service ownership is observed; interaction with Phone hooks needs more evidence. |
| `PhoneIntentHandler` | Intents extension `com.apple.TelephonyUtilities.PhoneIntentHandler`; supports start/join/add participant/search call history/play voicemail intents | Phone App Intents, Siri/Intent call history and voicemail flows | High for intent-surface ownership; medium for private back-end selector use. |
| `TelephonyBlastDoorService` | XPC service `com.apple.TelephonyBlastDoorService`, service type `Application` | Telephony safety/sanitization paths | Medium for service presence; low for selector ownership. |

## callservicesd Mach Service Map

| Mach service | Correlated protocol or hook family | Basis |
| --- | --- | --- |
| `com.apple.telephonyutilities.callservicesdaemon.callhistorycontroller` | `TUCallHistoryControllerXPCServer` / client | Name match plus protocol selector family for register/delete notifications. |
| `com.apple.telephonyutilities.callservicesdaemon.callhistorymanager` | `TUCallHistoryManagerXPCServer` / client | Name match plus recent-call reporting/update selectors. |
| `com.apple.telephonyutilities.callservicesdaemon.callprovidermanager` | `TUCallProviderManagerXPCServer` / client | Name match plus provider-manager protocol family. |
| `com.apple.telephonyutilities.callservicesdaemon.conversationmanager` | `TUConversationManagerXPCServer` / client | Name match plus large conversation/link/SharePlay/screen-sharing selector family. |
| `com.apple.telephonyutilities.callservicesdaemon.conversationprovidermanager` | `TUConversationProviderManagerXPCServer` / client | Name match plus provider-manager protocol family. |
| `com.apple.telephonyutilities.callservicesdaemon.simulatedconversationcontroller` | `TUSimulatedConversationControllerXPCServer` / client | Name match; likely diagnostics/test/simulation lane. |
| `com.apple.telephonyutilities.callservicesdaemon.usernotificationprovider` | `TUUserNotificationsProviderXPCServer`, `TUUserNotificationProviderXPCClient` | Name match plus notification-provider protocol/class names. |
| `com.apple.telephonyutilities.callservicesdaemon.callcapabilities` | `TUCallCapabilitiesXPCClient` and capability selectors | Name match; server protocol needs fuller metadata. |
| `com.apple.telephonyutilities.callservicesdaemon.callstatecontroller` | live call state/control surfaces such as `TUCallCenterXPCServer` | Entitlement and service naming align, but exact protocol binding remains unproven. |
| `com.apple.callkit.callcontrollerhost` | `CXCallControllerHostProtocol`, `CXCallControllerHost` | Name match plus CallKit host class/protocol names. |
| `com.apple.callkit.callsourcehost`, `com.apple.callkit.service` | `CXProviderHostProtocol`, provider host/vendor contexts | CallKit service naming plus provider host protocol evidence. |
| `com.apple.callkit.notificationserviceextension.voip` | `CXNotificationServiceExtensionVoIPXPC*` | Name match plus VoIP notification XPC classes. |
| `com.apple.callkit.networkextension.messagecontrollerhost` | `CXNetworkExtensionMessageControllerHost` | Name match plus host class name. |

Inference: Phone’s best-supported private ownership map is much clearer than Messages for `TU*` protocols because many `callservicesd` mach service names directly match protocol family names.

## Entitlement Notes

High-signal `Phone.app` privileges in the ownership capture include:

- `com.apple.private.CallHistory.read-write`
- `com.apple.CallHistory.sync.allow`
- `com.apple.private.security.storage.CallHistory`
- `com.apple.visualvoicemail.client`
- `com.apple.telephonyutilities.callservicesd` values for call access/modification, background calls, screening, translation, recording, smart holding, call providers, call capabilities, media priorities, participant reactions, and screen-sharing remote control
- CommCenter fine-grained values for cellular plan, SPI, phone, identity, SMS, and data usage
- mach lookup for CallHistory helpers, CommCenter, FaceTime message store, group activities, `IMDPersistenceAgent`, `callservicesd` subservices, and voicemail daemon

The `PhoneIntentHandler` extension separately has:

- CallHistory read and read-write entitlements
- Voicemail storage and visual voicemail client entitlements
- TelephonyUtilities callservicesd privileges for access/modify calls, screen calls, capabilities, provider access, and GFT service registration
- mach lookup for call provider, call state, conversation, conversation provider, voicemail, CommCenter, FaceTime message store, CallHistory sync, and `IMDPersistenceAgent`

Inference: Siri/Intent handling is not merely a thin public wrapper. The intent extension has private storage, voicemail, CallHistory, and callservicesd privileges of its own.

## Protocol-To-Service Correlation

| Protocol or class family | Most likely owner | Basis | Remaining proof needed |
| --- | --- | --- | --- |
| `TUCallHistoryControllerXPCServer`, `TUCallHistoryManagerXPCServer` | `callservicesd` | Direct mach-service name match | Confirm method dispatch through interface metadata or traffic. |
| `TUConversationManagerXPCServer`, `TUConversationProviderManagerXPCServer` | `callservicesd` | Direct mach-service name match; Phone and Messages both have conversation-manager mach lookups | Confirm client/process split for Phone, FaceTime, Messages, GroupActivities. |
| `TUCallProviderManagerXPCServer` | `callservicesd` | Direct mach-service name match and Phone/Intent entitlements | Decode provider registration payloads and clients. |
| `TUUserNotificationsProviderXPCServer` | `callservicesd` | Direct mach-service name match and user-notification delegate services | Confirm notification payload classes. |
| `TUSimulatedConversationControllerXPCServer` | `callservicesd` | Direct mach-service name match | Determine diagnostics/test gating. |
| `CXCallControllerHostProtocol`, `CXProviderHostProtocol`, `CXVoicemailControllerHostProtocol` | CallKit host services under `callservicesd` | CallKit host mach services and host protocol names | Separate public CallKit internals from Phone-private host behavior. |
| `CHManager`, `CallDBManager`, `CallHistory.CallHistoryManager` | `callhistoryd` and CallHistory helpers | CallHistory mach services, Phone/Intent entitlements, storage docs | Map class ownership to process and database handles. |

## Open Questions

- Which `callservicesd` mach service owns `TUCallCenterXPCServer` selectors such as `dialWithRequest:reply:` and recording/translation requests?
- Do `CXProviderHostProtocol` and `CXVoicemailControllerHostProtocol` bind to separate mach services or share a CallKit host broker?
- Which Phone App Intents invoke `callhistoryd` directly versus going through `callservicesd`?
- Which callservicesd entitlement values are checked for recording, translation, smart holding, screen calls, and screen-sharing remote control?
- Which services own voicemail payload storage versus voicemail transaction/controller host behavior?
