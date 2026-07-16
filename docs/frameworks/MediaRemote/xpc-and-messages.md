# MediaRemote XPC and Messages

## Main Service

Static strings identify the main client/daemon service name:

- `com.apple.mediaremoted.xpc`

The same string appears alongside XPC message keys and the daemon mach-lookup entitlement, so this is a verified local service surface.

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

- `MRXPC_MESSAGE_ID_KEY`
- `MRXPC_COMMAND_KEY`
- `MRXPC_COMMAND_SEND_ERROR_KEY`
- `MRXPC_COMMAND_STATUSES_DATA_KEY`
- `MRXPC_NOWPLAYING_APP_ENABLED_KEY`
- `MRXPC_NOWPLAYING_APP_OVERRIDE_ENABLED_KEY`
- `MRXPC_NOWPLAYING_DISPLAYID_KEY`
- `MRXPC_APP_IS_PLAYING_KEY`
- `MRXPC_PLAYBACK_STATE_KEY`
- `MRXPC_NOWPLAYING_PLAYER_PATH_ARRAY_DATA_KEY`
- `MRXPC_PLAYBACK_QUEUE_REQUESTS_DATA`
- `MRXPC_ENDPOINT_UID_KEY`
- `MRXPC_SOURCE_ENDPOINT_UID_KEY`
- `MRXPC_DESTINATION_ENDPOINT_UID_KEY`
- `MRXPC_ROUTE_UID_KEY`
- `MRXPC_ROUTES_DATA_KEY`
- `MRXPC_ROUTE_OPTIONS_KEY`
- `MRXPC_ROUTE_DISCOVERY_MODE_KEY`
- `MRXPC_ROUTE_CATEGORY_KEY`
- `MRXPC_ROUTE_PASSWORD_KEY`
- `MRXPC_ROUTE_DESCRIPTION_DATA_KEY`
- `MRXPC_ROUTE_VOLUME_CONTROL_CAPABILITIES_KEY`
- `MRXPC_MEDIA_CONTROLS_XPC_ENDPOINT_KEY`
- `MRXPC_MEDIA_CONTROLS_CONFIGURATION_KEY`
- `MRXPC_MEDIA_CONTROLS_STYLE_KEY`
- `MRXPC_VOICE_RECORDING_ENDPOINT_AVAILABLE_KEY`
- `MRXPC_TELEVISION_ENDPOINT_AVAILABLE_KEY`
- `MRXPC_AGENT_ENDPOINT_AVAILABLE_KEY`
- `MRXPC_GROUP_SESSION_TOKEN_KEY`
- `MRXPC_GROUP_SESSION_IDENTIFIER_KEY`
- `MRXPC_GROUP_SESSION_INVITATION_DATA_KEY`
- `MRXPC_GROUP_SESSION_EVENT_KEY`
- `MRXPC_MUSIC_HANDOFF_SESSION_KEY`
- `MRXPC_MUSIC_HANDOFF_EVENT_KEY`
- `MRXPC_ARTWORK_DATA_KEY`
- `MRXPC_ARTWORK_DIMENSION_WIDTH_KEY`
- `MRXPC_ARTWORK_DIMENSION_HEIGHT_KEY`
- `MRXPC_AUDIO_AMPLITUDE_SAMPLES_COUNT_KEY`
- `MRXPC_AUDIO_AMPLITUDE_ARRAY_DATA_KEY`
- `MRXPC_PICTURE_IN_PICTURE_ENABLED_KEY`
- `MRXPC_HARDWARE_REMOTE_BEHAVIOR_KEY`

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
