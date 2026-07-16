# Phone Agents And Services

## Scope

This page maps the local agents, XPC services, app extensions, and brokered service edges observed for `Phone.app` on macOS 26.5.2.

Raw evidence:

- `research/Phone/notifications/launchd-notification-triggers-macos-26.5.2.txt`
- `research/Phone/surfaces/bundle-surfaces-macos-26.5.2.txt`
- `research/Phone/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Phone/runtime/open-logstream-macos-26.5.2.txt`

## LaunchAgents

| Label | Program | Observed role |
| --- | --- | --- |
| `com.apple.callhistoryd` | `CallHistory.framework/Support/callhistoryd` | Call-history and conversation-history broker. |
| `com.apple.CallHistoryPluginHelper` | `CallHistory.framework/Support/CallHistoryPluginHelper` | Call-history plugin helper with launch notification. |
| `com.apple.CallHistorySyncHelper` | `CallHistory.framework/Support/CallHistorySyncHelper` | Call-history sync helper with APS and IDS launch notification. |
| `com.apple.callintelligenced` | `CallIntelligence.framework/callintelligenced` | Call-intelligence service, first-unlock triggered. |
| `com.apple.facetimemessagestored` | `FaceTimeMessageStore.framework/facetimemessagestored` | FaceTime message-store service with APS and FaceTime mach services. |
| `com.apple.telephonyutilities.callservicesd` | `TelephonyUtilities.framework/callservicesd` | Main call-services broker for CallKit, FaceTime, call state, providers, conversations, notifications, VoIP, simulated conversations, and call history edges. |

## XPC And Extension Services

| Bundle identifier | Bundle type | Observed role |
| --- | --- | --- |
| `com.apple.TelephonyUtilities.PhoneIntentHandler` | Intents extension | Handles call, join, participant, call-history search, and voicemail intents. |
| `com.apple.TelephonyBlastDoorService` | XPC service | Telephony blast-door service with ProbGuard and shared-cache reslide. |
| `com.apple.FaceTime.FTConversationService` | XPC service | FaceTime conversation service. |
| `com.apple.FTLivePhotoService` | XPC service | FaceTime live photo service. |
| `com.apple.MacHelper` | App bundle helper | FaceTime/AppKit helper embedded in Phone. |
| `com.apple.Phone-docktileplugin` | Dock tile plugin | Phone dock tile plugin. |
| `com.apple.FaceTime.RemotePeoplePicker` | GroupActivities extension | Remote people picker surface. |

## Entitlement-Backed Service Edges

`Phone.app` has high-signal private privileges for:

- `com.apple.private.CallHistory.read-write`
- CallHistory sync/helper access
- TelephonyUtilities `callservicesd` access, call modification, background calls, call capabilities, call providers, call recording, call screening, call translation, media priorities, and participant reactions
- CommCenter phone, SMS, identity, and cellular-plan access
- FaceTime, IDS, FaceTime message store, visual voicemail, and sensitive telephony URL handling

Inference: the app is privileged as a platform call coordinator. Public APIs such as `tel:` URLs, CallKit, and LiveCommunicationKit should be documented separately from private callservicesd and CallHistory privileges.

## Runtime Activation Edges

The bounded app-open log captured:

- `Phone.app` foreground scene activation for `com.apple.mobilephone`
- `com.apple.calls.facetime:AppController` requesting the recents scene
- `CallsAppUI.RecentsViewController` as the key-window responder
- `FaceTimeMac.MacFaceTimeWindow` as a visible window class
- CoreSpotlight indexing batches
- Continuity Capture nearby-device capability observations, with device identifiers and names redacted in raw evidence

Inference: default activation is a FaceTime/Calls recents surface. The short app-open pass did not show direct call-history row reads or call-control XPC traffic at default log level.

## Open Questions

- Which `callservicesd` XPC interfaces correspond to each broad TelephonyUtilities entitlement value?
- Which services wake for default activation versus Recents selection, dialing, voicemail, call receiving, or call-history mutation?
- Which Phone App Intents are user-invocable versus private/system-only?

