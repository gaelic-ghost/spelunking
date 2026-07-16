# MediaRemote Runtime Interfaces

## Scope

This note records Objective-C runtime metadata recovered from the loaded macOS 26.5.2 `MediaRemote.framework` image. It is runtime evidence, not a complete generated header set.

Raw captures are local-only under `research/MediaRemote/experiments/interfaces/<timestamp>/` and are intentionally ignored by Git.

## Capture Command

```sh
tools/mediaremote-interface-capture.zsh
```

The capture script builds `mr-interface-probe` and writes grouped runtime interface dumps:

- `all.txt`: default high-signal class set.
- `now-playing-requests.txt`: player-client, request, response, state, and queue classes.
- `origin-client.txt`: origin, client, player path, player, and client request classes.
- `controller-xpc.txt`: controller configuration and XPC connection classes.

Targeted ad hoc inspection is also available:

```sh
swift run mr-interface-probe MRNowPlayingPlayerClientRequests MRPlaybackQueueRequest
```

## Tool Boundary

`mr-interface-probe` only loads the framework and asks the Objective-C runtime for class metadata:

- protocols
- properties
- ivars
- class methods
- instance methods
- Objective-C type encodings

It does not instantiate classes, send playback commands, mutate now-playing state, query `mediaremoted`, or touch routes.

## High-Signal Interfaces

### `MRNowPlayingPlayerClientRequests`

Locally recovered interface evidence shows this as the richest request/hydration wrapper around an `MRNowPlayingPlayerClient`.

Interesting properties:

- `playerProperties`
- `playbackState`
- `playbackQueue`
- `supportedCommands`

Interesting methods:

- `-initWithPlayerPath:`
- `-updatePlaybackQueueIfUninitialized:`
- `-updatePlaybackStateIfUninitialized:`
- `-updateSupportedCommandsIfUninitialized:`
- `-enqueuePlaybackQueueRequest:completion:`
- `-handlePlaybackStateRequestWithCompletion:`
- `-handlePlayerPropertiesRequestWithCompletion:`
- `-handleSupportedCommandsRequestWithCompletion:`

Runtime experiments prove these methods are callable from userland, but player properties and playback queue are currently daemon-policy blocked for the unsigned helper with `kMRMediaRemoteFrameworkErrorDomain Code=3`.

### `MRNowPlayingPlayerClient`

This wrapper is constructible from the active Spotify `MRPlayerPath` in the Objective-C helper and prints the local player path, supported commands, now-playing info, playback state, playback queue, capabilities, and `canBeNowPlaying` status in its debug description.

Interesting methods:

- `-initWithPlayerPath:`
- `-playerPath`
- `-nowPlayingInfo`
- `-supportedCommands`
- `-playbackState`
- `-playbackQueue`
- `-capabilities`
- `-canBeNowPlayingPlayer`
- `-resolveCommand:`
- `-resolveCommandOptions:options:`
- `-setSupportedCommands:queue:completion:`
- `-updatePlaybackState:date:`
- `-updatePlayer:`
- `-invalidatePlaybackQueue`

Inference: this class is the bridge from the origin/player-path identity model into richer now-playing state. Constructing it alone does not hydrate Spotify metadata or queue state.

### `MRPlaybackQueueRequest`

This class is the request object used by the internal helper's playback-queue path.

Interesting methods and functions confirmed across symbol and runtime evidence:

- `MRPlaybackQueueRequestCreateDefault`
- `-setPlayerPath:`
- `-setIncludeMetadata:`
- `-setIncludeInfo:`
- `-setIncludeLyrics:`
- `-setIncludeSections:`
- `-setRequestIdentifier:`
- `-setLabel:`

Runtime behavior confirms a default request with the active Spotify `MRPlayerPath` reaches the MediaRemote request path, then returns Code 3 under the current entitlement state.

### Origin, Client, Player, and Path Classes

The origin/player-path layer remains the most reliable read-only discovery surface for Spotify on this machine.

High-value identity methods:

- `MRNowPlayingPlayerPathGetClient`
- `MRNowPlayingPlayerPathGetPlayer`
- `MRNowPlayingPlayerPathGetOrigin`
- `MRNowPlayingPlayerPathCopyStringRepresentation`
- `MROriginGetDisplayName`
- `MROriginGetUniqueIdentifier`
- `MROriginGetOriginType`
- `MROriginIsLocalOrigin`

Recovered class surfaces to keep inspecting:

- `MRNowPlayingOriginClientManager`
- `MRNowPlayingOriginClient`
- `MRNowPlayingClient`
- `MRNowPlayingClientRequests`
- `MRPlayerPath`
- `MRPlayer`
- `MROrigin`
- `MRClient`

Verified behavior: the active local origin and player path identify Spotify as `com.spotify.client` with the default player even when global now-playing APIs return nil.

### `MRXPCConnection`

`MRXPCConnection` is a high-priority interface for the daemon boundary. The runtime interface dump gives selectors and type encodings, while `xpc-and-messages.md` tracks message keys and XPC service names from string and symbol evidence.

Recovered selectors:

- `-initWithConnection:queue:defaultReplyQueue:`
- `-sendMessage:queue:reply:`
- `-sendMessageWithType:queue:reply:`
- `-sendSyncMessage:error:`
- `-sendSyncMessageWithType:error:`
- `-addCustomXPCHandler:forKey:`
- `-removeCustomXPCHandler:`
- `-setMessageHandler:`
- `-setInvalidationHandler:`

Inference: this class likely owns part of the client-side transport to `mediaremoted`; do not treat its selectors as safe to call until request/response lifetime, audit-token handling, and daemon entitlement checks are mapped.

## Current Interpretation

MediaRemote has at least three relevant layers for now-playing state:

- global C APIs that currently return nil/empty for Spotify on this machine
- origin/player-path identity APIs that successfully discover Spotify
- Objective-C wrapper/request classes that can be constructed and invoked, but are selectively blocked by daemon policy

The promising route is not the old global now-playing callback alone. It is the path from active origin to player path, then through internal wrapper/request classes, while mapping the entitlement bitfield and daemon request policy.

## Open Questions

- Which `MRNowPlayingClientRequests` methods hydrate metadata versus queue state?
- Which selectors on `MRXPCConnection` correspond to daemon message names in `xpc-and-messages.md`?
- Which entitlement bit unlocks player properties and playback queue reads?
- Are the global C APIs intentionally empty for Spotify, or are they missing a registration/notification priming step?
- Does an Apple-signed host or app-bundle fixture alter the wrapper hydration behavior?
