# Phone Hooks

## Scope

This page documents hook-like Phone, TelephonyUtilities, CallHistory, CallsXPC, CallsPersistence, and CallKit surfaces observed in local runtime metadata on macOS 26.5.2. It focuses on XPC server/client protocols, host/vendor protocols, manager/controller classes, call-history hooks, conversation hooks, voicemail hooks, and notification/provider bridge types.

This is private, local-only reverse-engineering research. Treat every `TU*`, `CH*`, `CallDB*`, `Calls*`, private `CX*`, and `Phone*` hook described here as an observed private runtime surface, not a supported app, extension, App Store, or redistributed integration contract.

## Evidence

Raw capture:

- `research/Phone/runtime/hook-surface-inventory-macos-26.5.2.json`

Source captures:

- `research/Phone/runtime/objc-runtime-callservices-macos-26.5.2.json`
- `research/Phone/runtime/objc-runtime-callsxpc-phoneintents-macos-26.5.2.json`

Inventory filter:

- class/protocol names or method names matching XPC, host, client, server, delegate, data source, provider, manager, controller, call history, conversation, voicemail, or call-service control surfaces

Observed inventory size:

| Kind | Count |
| --- | ---: |
| Classes | 231 |
| Protocols | 153 |

Boundary: this evidence proves names, selectors, properties, and protocol groupings are present in the active local runtime. It does not prove entitlement availability, call ordering, payload shape, behavioral side effects, or safe third-party use.

## Hook Families

### TelephonyUtilities XPC Protocols

| Family | Observed examples | Meaning |
| --- | --- | --- |
| Call center control | `TUCallCenterXPCServer`, `TUCallCenterXPCClient` | Server selectors cover dialing requests, initial state, current call updates, recording, translation, smart holding, call pulling, screening, greetings, receptionist replies, and transmission control. |
| Call services broker | `TUCallServicesXPCServer`, `TUCallServicesXPCClient` | Protocol names indicate a broad service broker, but the sampled server protocol has no required methods in this runtime capture. |
| Route control | `TURouteControllerXPCServer`, `TURouteControllerXPCClient` | Protocol names align with audio/call route ownership rather than call-history persistence. |
| Provider management | `TUCallProviderManagerXPCServer`, `TUCallProviderManagerXPCClient`, `TUConversationProviderManagerXPCServer`, `TUConversationProviderManagerXPCClient` | Provider manager hooks imply registration and state flow between private call providers, conversation providers, and `callservicesd`. |
| User notifications | `TUUserNotificationsProviderXPCServer`, `TUUIXPCHost`, `TUUIXPCClient` | Naming suggests notification/UI mediation across service and app boundaries. |

Observed `TUCallCenterXPCServer` selectors include:

- `dialWithRequest:reply:`
- `dialWithRequest:displayContext:`
- `fetchCurrentCallUpdates:`
- `requestInitialState:`
- `performRecordingRequest:completion:`
- `performTranslationRequest:completion:`
- `performSmartHoldingRequest:completion:`
- `screenWithRequest:`
- `pullCallFromClientUsingHandoffActivityUserInfo:reply:`
- `startReceptionistReply`

Inference: `TUCallCenterXPCServer` is the clearest private live-call control hook in this inventory. It is likely brokered by `callservicesd` and guarded by the broad TelephonyUtilities entitlements documented in `README.md`.

### Call-History Hooks

| Family | Observed examples | Meaning |
| --- | --- | --- |
| CallHistory manager | `CHManager`, `CHDelegateManager`, `CHDelegateController`, `CHCallInteractionManager` | Properties and protocol names point to recent-call fetching, cache state, delegate distribution, and call interaction data sources. |
| Database handles | `CallDBManager`, `CallDBManagerClient`, `CallDBManagerServer`, `CallHistoryDBHandle`, `CallHistoryDBClientHandle` | These names indicate the private database manager/handle layer under the Core Data store documented in `storage.md`. |
| Controller XPC | `TUCallHistoryControllerXPCServer`, `TUCallHistoryControllerXPCClient` | Server selectors cover client registration plus `recentCallsDeleted:` and `allCallHistoryDeleted`. |
| Manager XPC | `TUCallHistoryManagerXPCServer`, `TUCallHistoryManagerXPCClient` | Server selectors cover client registration, outgoing participant UUID updates, and reporting a recent call for a conversation. |
| Swift CallHistory layer | `CallHistory.CallHistoryManager`, `CallHistory.CallHistoryDataSource`, `CallHistory.CallHistoryStoreClient` | Swift names suggest a higher-level store/client layer over persisted recents. |

Observed call-history XPC selectors include:

- `registerClient:`
- `unregisterClient:`
- `recentCallsDeleted:`
- `allCallHistoryDeleted`
- `reportRecentCallForConversation:withStartDate:avMode:`
- `updateOutgoingLocalParticipantUUID:forCallsWithOutgoingLocalParticipantUUID:`

Inference: Phone call history is split between a persisted `CH*`/`CallDB*` store layer and `TU*` XPC controller/manager hooks. The current evidence supports read/write platform ownership; it does not support direct third-party mutation of the local Core Data store.

### Conversation And Call-Service Hooks

High-signal protocol:

- `TUConversationManagerXPCServer`

Observed selector families include:

- conversation link activation, generation, renewal, invalidation, and validity checks
- active/inactive link fetches and sync-state checks
- conversation join, leave, member invite, pending member approval/rejection, and kicked-member operations
- SharePlay, activity sessions, application launch for activity sessions, and external authorization state
- screen sharing requests, control request/relinquish, presenter controls, AirPlay state, and screen-sharing attributes
- collaboration tracking, collaboration identifiers, disclosed initiators, and Messages group UUID registration
- local participant AV mode, cluster, grid display mode, downlink mute, and external participants updates
- Messages group name/photo update hooks for conversations

Inference: the conversation manager hooks are FaceTime/SharePlay/collaboration-heavy rather than simple telephone hooks. They explain why `Phone.app` on macOS is entangled with FaceTime, Messages group state, activity sessions, and collaboration metadata.

### CallKit Host And Vendor Hooks

| Family | Observed examples | Meaning |
| --- | --- | --- |
| Provider host | `CXProviderHostProtocol`, `CXProviderHost`, `CXProviderExtensionHostContext`, `CXProviderExtensionVendorContext` | Host protocol selectors allow provider registration and provider reports for incoming/outgoing calls, audio, DTMF, data usage, and call updates. |
| Call controller host | `CXCallControllerHostProtocol`, `CXCallControllerHost` | Host classes include connection maps, public/private call UUID maps, listener state, and delegates. |
| Voicemail host | `CXVoicemailControllerHostProtocol`, `CXVoicemailControllerHost` | Selectors include transaction requests and voicemail requests. |
| Channel/push host | `CXChannelProviderHostProtocol`, `CXChannelPushClientProtocol`, `CXChannelPushServerProtocol` | Names line up with CallKit channel provider and push mediation surfaces. |
| Notification service XPC | `CXNotificationServiceExtensionVoIPXPC`, `CXNotificationServiceExtensionVoIPXPCClient`, `CXNotificationServiceExtensionVoIPXPCHost` | Names indicate a VoIP notification service extension bridge. |

Observed `CXProviderHostProtocol` selectors include:

- `registerWithConfiguration:`
- `reportNewIncomingCallWithUUID:update:reply:`
- `reportNewOutgoingCallWithUUID:update:`
- `reportOutgoingCallWithUUID:startedConnectingAtDate:`
- `reportOutgoingCallWithUUID:connectedAtDate:`
- `reportCallWithUUID:updated:`
- `reportCallWithUUID:endedAtDate:privateReason:failureContext:`

Boundary: CallKit is a public framework, but these host/vendor protocols are runtime host internals. Public CallKit apps should use documented `CXProvider`, `CXCallController`, extension, and call-directory APIs rather than private host protocols.

### Voicemail, Notification, And Provider Hooks

Observed classes and protocols:

- `CXVoicemailControllerHostProtocol`
- `CXVoicemailControllerHost`
- `TUUserNotificationsProviderXPCServer`
- `TUUserNotificationProviderXPCClient`
- `CXNotificationServiceExtensionVoIPXPC`
- `CXNetworkExtensionMessageControllerHost`
- `TUCallProviderManagerXPCServer`
- `TUConversationProviderManagerXPCServer`

Inference: voicemail and notification hooks are mediated through host/controller/provider boundaries rather than exposed as simple local files or URL schemes. The current pass has not yet decoded voicemail storage, provider entitlements, or notification payloads.

## Working Model

Phone appears to use private hooks in layers:

1. Public user-visible APIs such as `tel:`, CallKit, LiveCommunicationKit, and App Intents.
2. Private `TU*` XPC server/client protocols for live calls, route control, call providers, conversation providers, UI, notifications, moments, and simulated conversations.
3. Private `CH*` and `CallDB*` manager/handle classes for recent calls and call-history database mediation.
4. Private `CX*` host/vendor protocols that back CallKit provider, call-controller, voicemail, channel, and VoIP notification runtime behavior.
5. FaceTime/SharePlay/collaboration conversation hooks that connect Phone to Messages group identifiers, collaboration IDs, activity sessions, and screen sharing.

The strongest private hook evidence is around `callservicesd` XPC protocols and CallKit host internals. For future behavioral work, `TU*XPCServer` protocol selectors are better starting points than direct edits to `CallHistory.storedata`.

## Open Questions

- Which mach services expose each `TU*XPCServer` protocol to Apple clients?
- Which protocol selectors are reachable from `Phone.app`, `FaceTime.app`, CallKit extensions, Siri/Intent handlers, or diagnostics clients?
- Which selectors require `com.apple.telephonyutilities.callservicesd` entitlement values, CallHistory read/write entitlement, CommCenter privileges, or FaceTime privileges?
- How do `TUCallHistoryControllerXPCServer`, `TUCallHistoryManagerXPCServer`, `CHManager`, and `CallDBManager` divide responsibility for persisted recents?
- Which `CX*HostProtocol` selectors are public-framework internals versus private Phone-specific host behavior?
- Where voicemail payloads are stored locally, and which voicemail host selectors touch that storage?
- Which simulated-conversation hooks are production diagnostics versus internal test surfaces?
