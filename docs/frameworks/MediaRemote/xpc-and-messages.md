# MediaRemote XPC and Messages

## Main Service

Static strings identify the main client/daemon service name:

- `com.apple.mediaremoted.xpc`

The same string appears alongside XPC message keys and the daemon mach-lookup entitlement, so this is a verified local service surface.

## Repeatable Extraction

Static message-surface extraction:

```sh
tools/mediaremote-message-surfaces.zsh
tools/mediaremote-message-surfaces.zsh research/MediaRemote/captures/20260716T084528Z
```

The extractor reads an inventory capture and writes reviewed working files under `research/MediaRemote/experiments/messages/<timestamp>/`:

- `xpc-keys.txt`
- `xpc-serialization-symbols.txt`
- `xpc-transport-symbols.txt`
- `message-oslogstrings.txt`
- `request-response-oslogstrings.txt`
- `cache-update-oslogstrings.txt`
- `daemon-request-handlers.txt`
- `message-protobuf-symbols.txt`

Baseline extraction `research/MediaRemote/experiments/messages/20260716T085551Z` used source capture `research/MediaRemote/captures/20260716T084528Z`.

## Client-Side Routing

OS log strings show a routed client-message architecture:

- `No client-side XPC message destination routed for message with ID %lu.`
- `Client XPC message with ID %lu not handled.`
- `No client module registered to receive message: %@`
- `Could not parse notification from xpc message`
- `Could not find connection: %@ to handle message: %@`
- `Could not find connection: %@ to handle invalidation`

Separate endpoint classes are implied by logs:

- agent endpoint: `Agent client message %lu not handled`, `No agent endpoint registered to receive message: %@`
- voice recording endpoint: `Voice recording client message %lu not handled`
- television endpoint: `Television client message %lu not handled`
- UI service endpoint: `Re-establishing UI service endpoint.`
- browsable content endpoint: `No browsableContent endpoint registered to handle API: %@`

Inference: MediaRemote multiplexes several app/client-facing modules over a shared XPC connection and routes messages by ID/API name to registered endpoint handlers.

Live symbols, runtime interface capture, and imports identify the core client-side transport pieces:

- `MRXPCConnection`
- `MRAVXPCPipeTransport`
- `_xpc_connection_send_message`
- `_xpc_connection_send_message_with_reply`
- `_xpc_connection_send_message_with_reply_sync`
- `-[MRXPCConnection initWithConnection:queue:defaultReplyQueue:]`
- `-[MRXPCConnection addCustomXPCHandler:forKey:]`
- `-[MRXPCConnection removeCustomXPCHandler:]`
- `-[MRXPCConnection sendMessageWithType:queue:reply:]`
- `-[MRXPCConnection sendMessage:queue:reply:]`
- `-[MRXPCConnection sendSyncMessageWithType:error:]`
- `-[MRXPCConnection sendSyncMessage:error:]`
- `-[MRXPCConnection pid]`
- `-[MRXPCConnection uid]`
- `-[MRXPCConnection messageHandler]`
- `-[MRXPCConnection invalidationHandler]`

Inference: most client-visible C calls likely reduce to dictionary/protobuf payloads sent through this wrapper, with `MRXPC_MESSAGE_ID_KEY` selecting the daemon-side operation and callback blocks bridged back through the default reply queue.

Current gap: numeric message IDs are not mapped yet. The string evidence proves ID-key routing exists; it does not prove which integer maps to which request.

## Command XPC Paths

Command logs identify daemon and app directions:

- `SendCommandXPCToDaemon`
- `SendCommandXPCResultFromDaemon`
- `SendCommandXPCToApp`
- `SendCommandXPCResultFromApp`

Exported command functions include:

- `MRMediaRemoteSendCommand`
- `MRMediaRemoteSendCommandWithReply`
- `MRMediaRemoteSendCommandForOrigin`
- `MRMediaRemoteSendCommandForOriginWithReply`
- `MRMediaRemoteSendCommandToApp`
- `MRMediaRemoteSendCommandToClient`
- `MRMediaRemoteSendCommandToPlayer`
- `MRMediaRemoteSendCommandToPlayerWithResult`

Boundary: these are mutating control surfaces. Keep them out of default probes until the read-only identity and now-playing surfaces are understood.

## XPC Keys

High-signal keys from `__TEXT,__cstring`:

- routing and replies:
  - `MRXPC_MESSAGE_ID_KEY`
  - `MRXPC_MESSAGE_CUSTOM_ID_KEY`
  - `MRXPC_TRANSACTION_NAME`
  - `MRXPC_TRANSACTION_DATA_REQUESTED_SIZE`
  - `MRXPC_TRANSACTION_DATA`
  - `MRXPC_TRANSACTION_ENDED`
  - `MRXPC_TIMESTAMP`
  - `MRXPC_ERROR_CODE_KEY`
  - `MRXPC_BOOL_RESULT_KEY`
  - `MRXPC_REQUEST_DETAILS`
- now-playing identity and state:
  - `MRXPC_ORIGIN_DATA_KEY`
  - `MRXPC_AVAILABLE_ORIGINS_DATA_KEY`
  - `MRXPC_NOWPLAYING_CLIENT_DATA_KEY`
  - `MRXPC_NOWPLAYING_CLIENT_ARRAY_DATA_KEY`
  - `MRXPC_NOWPLAYING_PLAYER_DATA_KEY`
  - `MRXPC_NOWPLAYING_PLAYER_ARRAY_DATA_KEY`
  - `MRXPC_NOWPLAYING_PLAYER_PATH_DATA_KEY`
  - `MRXPC_NOWPLAYING_PLAYER_PATH_ARRAY_DATA_KEY`
  - `MRXPC_NOWPLAYING_STATE_DATA_KEY`
  - `MRXPC_NOWPLAYING_APP_ENABLED_KEY`
  - `MRXPC_NOWPLAYING_APP_OVERRIDE_ENABLED_KEY`
  - `MRXPC_NOWPLAYING_DISPLAYID_KEY`
  - `MRXPC_APP_IS_PLAYING_KEY`
  - `MRXPC_PLAYBACK_STATE_KEY`
- playback queue and commands:
  - `MRXPC_PLAYBACK_QUEUE_REQUESTS_DATA`
  - `MRXPC_NOWPLAYING_PLAYBACK_QUEUE_KEY`
  - `MRXPC_NOWPLAYING_PLAYBACK_QUEUE_REQUEST_KEY`
  - `MRXPC_NOWPLAYING_PLAYBACK_QUEUE_CAPABILITIES_KEY`
  - `MRXPC_PLAYBACKQUEUE_PARTICIPANTS`
  - `MRXPC_COMMAND_KEY`
  - `MRXPC_COMMAND_OPTIONS_KEY`
  - `MRXPC_COMMAND_SEND_ERROR_KEY`
  - `MRXPC_COMMAND_STATUSES_DATA_KEY`
  - `MRXPC_COMMAND_INFO_ARRAY_DATA_KEY`
  - `MRXPC_COMMAND_RESULT_DATA_KEY`
- routes, endpoints, output devices, and volume:
  - `MRXPC_ENDPOINT_UID_KEY`
  - `MRXPC_SOURCE_ENDPOINT_UID_KEY`
  - `MRXPC_DESTINATION_ENDPOINT_UID_KEY`
  - `MRXPC_SOURCE_ID_KEY`
  - `MRXPC_ROUTE_UID_KEY`
  - `MRXPC_ROUTES_DATA_KEY`
  - `MRXPC_ROUTE_OPTIONS_KEY`
  - `MRXPC_ROUTE_DISCOVERY_MODE_KEY`
  - `MRXPC_ROUTE_CATEGORY_KEY`
  - `MRXPC_ROUTE_PASSWORD_KEY`
  - `MRXPC_ROUTE_DESCRIPTION_DATA_KEY`
  - `MRXPC_ROUTE_VOLUME_CONTROL_CAPABILITIES_KEY`
  - `MRXPC_OUTPUT_DEVICE_UID_ARRAY_DATA_KEY`
  - `MRXPC_VOLUME_VALUE_KEY`
  - `MRXPC_VOLUME_OPTIONS_KEY`
  - `MRXPC_ROUTING_CONTEXT_UID_KEY`
  - `MRXPC_CONTEXT_MODIFICATION_DATA_KEY`
- media controls and auxiliary endpoint availability:
  - `MRXPC_MEDIA_CONTROLS_XPC_ENDPOINT_KEY`
  - `MRXPC_MEDIA_CONTROLS_CONFIGURATION_KEY`
  - `MRXPC_MEDIA_CONTROLS_STYLE_KEY`
  - `MRXPC_VOICE_RECORDING_ENDPOINT_AVAILABLE_KEY`
  - `MRXPC_TELEVISION_ENDPOINT_AVAILABLE_KEY`
  - `MRXPC_AGENT_ENDPOINT_AVAILABLE_KEY`
- group session, handoff, and account/user identity:
  - `MRXPC_GROUP_SESSION_TOKEN_KEY`
  - `MRXPC_GROUP_SESSION_IDENTIFIER_KEY`
  - `MRXPC_GROUP_SESSION_INVITATION_DATA_KEY`
  - `MRXPC_GROUP_SESSION_EVENT_KEY`
  - `MRXPC_MUSIC_HANDOFF_SESSION_KEY`
  - `MRXPC_MUSIC_HANDOFF_EVENT_KEY`
  - `MRXPC_DSID_KEY`
  - `MRXPC_USER_IDENTITY_KEY`
- artwork, audio, notification, and content:
  - `MRXPC_ARTWORK_DATA_KEY`
  - `MRXPC_ARTWORK_DIMENSION_WIDTH_KEY`
  - `MRXPC_ARTWORK_DIMENSION_HEIGHT_KEY`
  - `MRXPC_AUDIO_AMPLITUDE_SAMPLES_COUNT_KEY`
  - `MRXPC_AUDIO_AMPLITUDE_ARRAY_DATA_KEY`
  - `MRXPC_AUDIO_FORMAT_CONTENT_INFO`
  - `MRXPC_NOTIFICATION_NAME_KEY`
  - `MRXPC_NOTIFICATION_USERINFO_DATA_KEY`
  - `MRXPC_NOTIFICATION_DELAY`
  - `MRXPC_CONTENT_NOW_PLAYING_IDENTIFIERS_KEY`
  - `MRXPC_CONTENT_IDENTIFIERS`
  - `MRXPC_CONTENT_CHILD_ITEMS_DATA_KEY`

## Serialization Helpers

Live exported symbols show typed helpers for XPC payload construction and decoding:

- identity/state:
  - `MRAddClientToXPCMessage`
  - `MRAddOriginToXPCMessage`
  - `MRAddOriginsToXPCMessage`
  - `MRAddPlayerToXPCMessage`
  - `MRAddPlayerPathToXPCMessage`
  - `MRAddNowPlayingStateToXPCMessage`
  - `MRCreateClientFromXPCMessage`
  - `MRCreateClientArrayFromXPCMessage`
  - `MRCreateOriginFromXPCMessage`
  - `MRCreateOriginArrayFromXPCMessage`
  - `MRCreatePlayerFromXPCMessage`
  - `MRCreatePlayerArrayFromXPCMessage`
  - `MRCreatePlayerPathFromXPCMessage`
  - `MRCreatePlayerPathArrayFromXPCMessage`
  - `MRCreateNowPlayingStateFromXPCMessage`
- playback queue and commands:
  - `MRAddPlaybackQueueRequestToXPCMessage`
  - `MRAddPlaybackQueueToXPCMessage`
  - `MRAddPlaybackQueueCapabilitiesToXPCMessage`
  - `MRAddSendCommandToXPCMessage`
  - `MRAddSupportedCommandsToXPCMessage`
  - `MRAddSupportedCommandsDataToXPCMessage`
  - `MRCreatePlaybackQueueRequestFromXPCMessage`
  - `MRCreatePlaybackQueueFromXPCMessage`
  - `MRCreatePlaybackQueueCapabilitiesFromXPCMessage`
  - `MRCreateCommandResultFromXPCMessage`
  - `MRCreateSupportedCommandsFromXPCMessage`
  - `MRCreateSupportedCommandsDataFromXPCMessage`
- generic and error payloads:
  - `MRCreateXPCMessage`
  - `MRAddArrayToXPCMessage`
  - `MRAddDataToXPCMessage`
  - `MRAddErrorToXPCMessage`
  - `MRAddProtobufToXPCMessage`
  - `MRAddPropertyListToXPCMessage`
  - `MRAddRequestDetailsToXPCMessage`
  - `MRCreateArrayFomXPCMessage`
  - `MRCreateDataFromXPCMessage`
  - `MRCreateProtobufFromXPCMessage`
  - `MRCreatePropertyListFromXPCMessage`
  - `MRCreateRequestDetailsFromXPCMessage`
  - `MRErrorFromXPCMessage`

Inference: the daemon boundary is object-oriented at the framework layer but marshals through typed XPC helpers, not one undifferentiated dictionary path.

## Request/Response and Cache Logs

The framework has generic request/response timing templates:

- `Request: %{public}@`
- `Response: %{public}@<%{public}@> returned <%@> ...`
- `Response: %{public}@<%{public}@> returned with error <%{public}@> ...`
- `Cache Miss: Request: %{public}@<%{public}@> ...`

Now-playing cache-update log strings map directly onto the runtime request classes:

- `MRNowPlayingOriginClientRequests`:
  - `UpdatingCache: volumeCapabilities`
  - `UpdatingCache: volume`
  - `UpdatingCache: lastPlayingDate`
  - `UpdatingCache: clientProperties`
- `MRNowPlayingPlayerClientRequests`:
  - `UpdatingCache: playbackState`
  - `UpdatingCache: supportedCommands`
  - `UpdatingCache: playbackQueue`
  - `UpdatingCache: playerProperties`
  - `UpdatingCache: contentItem`
  - clearing content-item/artwork caches

Runtime implication: `MRNowPlayingPlayerClientRequests` is not only a local data wrapper. It is part of an asynchronous request/cache pathway with request completions and cache update logging.

## Daemon Playback Queue Path

`mediaremoted` strings identify a relay-style queue request path:

- `handlePlaybackQueueRequest:fromClient:`
- `_handlePlaybackQueueRequest:forPlayerPath:completion:`
- `handlePlaybackQueueRequestTransaction:packets:group:`
- `relayPlaybackQueueRequest:withMessage:toNowPlayingClient:backToXpcClient:completion:`
- `relayArtworkRequest:forContentItems:withMessage:fromNowPlayingClient:andNotifyXPCClient:`
- `sendPlaybackQueueResponse:forRequest:withMessage:fromNowPlayingClient:toXpcClient:`
- `subscribeToPlaybackQueue:forRequest:`
- `updatePlaybackQueue:fromRequest:`
- `updatePlaybackQueueWithContentItems:fromRequest:`
- `createPlaybackQueueForRequest:cachingPolicy:playerPath:partiallyCachedItems:capabilities:`
- `playbackQueueForRequest:cachingPolicy:playerPath:partiallyCachedItems:`

Verified runtime connection: the local `mr-internal-probe` queue request triggers daemon log lines named `handlePlaybackQueueRequest` and returns Code 3 with the probe logged as `entitlements=0`.

Inference: playback queue reads may relay from the external XPC client to the now-playing client application, then back through `mediaremoted`. The current unsigned helper fails before receiving queue data, likely at a daemon policy check or relay authorization point.

## XPC Interface Strings

Route/output-device XPC interface names appear in logs:

- `AddOutputDevices.xpcInterface`
- `SetOutputDevices.xpcInterface`
- `RemoveOutputDevices.xpcInterface`
- `ModifyOutputContext.xpcInterface`
- `pauseOutputDeviceUIDs.xpcInterface`

These are route/output mutation surfaces and should stay behind explicit experiment flags if tooling ever wraps them.

## Serialization

Static evidence points to protobuf and XPC serialization helpers:

- `MRCreateArrayFromXPCMessage`
- Xcode 26 also names the likely misspelled `MRCreateArrayFomXPCMessage`.
- `MRAddContentItemsToXPCMessage`
- `MRAddPlaybackQueueRequestToXPCMessage`
- `Error encoding to XPC message: %@ object: %@`
- `Error decoding XPC message: %@`
- `Encountered unknown protobuf key (%@) while converting to a dictionary; skipping.`

Inference: many higher-level C APIs marshal Objective-C model objects or protobuf-backed payloads into XPC messages rather than exposing simple property dictionaries end to end.

Live symbols also expose protobuf-backed message aggregates:

- `_MRMediaRemoteMessageProtobuf`
- `_MRSetStateMessageProtobuf`
- `_MRCommandOptionsProtobuf`
- `_MRPlaybackSessionMigrateRequestProtobuf`

Selected `_MRMediaRemoteMessageProtobuf` ivars show message families for application connection, hosted endpoints, output context modification, origin/client/player properties, playback queue requests, playback-session migration, command send/results, notification messages, voice input, HID, route authorization, and remove-client/player/endpoints flows.

Boundary: these symbols identify message families, not safe call contracts. Use them for disassembly and log correlation before wrapping any mutating path.

## Policy and Audit Boundaries

Daemon strings show that XPC request handling includes audit-token, PID, and entitlement checks:

- `_validateAuditTokens:pids:auditTokens:`
- `PID Mismatch: Client %{public}@ is trying to make a nowPlayingClient with a different pid %d`
- `Client is not entitled for NowPlaying Acesss: %@`

See `permissions-policy.md` for the current runtime Code 3 denials and entitlement inventory.
