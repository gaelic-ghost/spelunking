# MediaRemote Runtime Probes

## Probe Targets

### `mr-now-playing-probe`

Read-only executable target that dynamically loads `MediaRemote.framework`, resolves private symbols with `dlsym`, and queries now-playing state.

Verified safe call:

- `MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t, block)`

Locally evidenced app-level signatures, based on private Canopy adapter source in Gale's workspace:

- `MRMediaRemoteGetNowPlayingApplicationPID(dispatch_queue_t, block(int))`
- `MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t, block(bool))`
- `MRMediaRemoteGetNowPlayingClient(dispatch_queue_t, block(id))`
- `MRMediaRemoteGetNowPlayingClients(dispatch_queue_t, block(NSArray?))`
- `MRMediaRemoteGetNowPlayingPlayer(dispatch_queue_t, block(id?))`
- `MRMediaRemoteGetNowPlayingInfoForClient(id, dispatch_queue_t, block(CFDictionary?))`
- `MRMediaRemoteGetNowPlayingInfoForPlayer(id, dispatch_queue_t, block(CFDictionary?))`
- `MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t)`

Locally evidenced origin/player-path signatures:

- `MRMediaRemoteGetActiveOrigin(dispatch_queue_t, block(bool, id?))`
- `MRMediaRemoteGetAvailableOrigins(dispatch_queue_t, block(NSArray?))`
- `MRMediaRemoteGetActivePlayerPathsForOrigin(id, dispatch_queue_t, block(NSArray?))`
- `MRNowPlayingPlayerPathGetClient(id) -> id?`
- `MRNowPlayingPlayerPathGetPlayer(id) -> id?`
- `MRNowPlayingPlayerPathGetOrigin(id) -> id?`
- `MRNowPlayingPlayerPathCopyStringRepresentation(id) -> CFString?`
- `MROriginGetDisplayName(id) -> CFString?`
- `MROriginGetUniqueIdentifier(id) -> int32`
- `MROriginGetOriginType(id) -> int32`
- `MROriginIsLocalOrigin(id) -> bool`

Rejected guessed signatures:

- `MRMediaRemoteGetNowPlayingApplicationDisplayID`
- `MRMediaRemoteGetNowPlayingApplicationDisplayName`
- `MRMediaRemoteGetActiveOrigin(dispatch_queue_t, block(id?))`

Those display ID/name callbacks crashed when guessed as `block(CFStringRef)`. Do not call them again until header, disassembly, or a proven adapter confirms their real signatures.

The first `MRMediaRemoteGetActiveOrigin` guess also crashed. The crash report showed MediaRemote calling a block with a leading scalar before the `MROrigin` object; using `block(bool, id?)` fixed the origin probe.

### `now-playing-fixture`

Metadata-only executable target that publishes `MPNowPlayingInfoCenter.default().nowPlayingInfo` for a fixed duration.

Observed result:

- The fixture can publish metadata and stay alive.
- `MRMediaRemoteGetNowPlayingApplicationIsPlaying` still returns `false`.
- `MRMediaRemoteGetNowPlayingApplicationPID` still returns `0`.
- `MRMediaRemoteGetNowPlayingClient` still returns `nil`.
- `MRMediaRemoteGetNowPlayingInfo` still returns `nil`.

Interpretation: a CLI process setting `MPNowPlayingInfoCenter` metadata is not enough to appear as a MediaRemote now-playing client on this system. A later fixture probably needs a real app bundle/player host, AVAudioSession-equivalent behavior, or explicit MediaRemote registration.

## Spotify Probe

Spotify was confirmed through AppleScript as actively playing:

```text
playing
DARK THINGS - STARSET
```

MediaRemote still reported:

```text
Application is playing: false
Application PID: 0
Now-playing client: <nil>
Result: callback returned nil dictionary
```

Interpretation: Spotify playback is not currently visible to this direct MediaRemote path on this machine, or this path requires a different origin/player/client-specific query before it exposes Spotify.

Expanded probe with Spotify actively playing `Bad Omens - THE DEATH OF PEACE OF MIND`:

```text
Primed: MRMediaRemoteRegisterForNowPlayingNotifications
Primed: MRMediaRemoteSetWantsNowPlayingNotifications(true)
MediaRemote read-only now-playing application probe
Application is playing: false
Application PID: 0
Now-playing client: <nil>
MediaRemote read-only now-playing clients probe
Now-playing clients: 0 item(s)
MediaRemote read-only now-playing player probe
Now-playing player: <nil>
MediaRemote read-only now-playing probe
Symbol: MRMediaRemoteGetNowPlayingInfo
Result: callback returned nil dictionary
```

Notification observation with a Spotify pause/play cycle:

```text
Primed: MRMediaRemoteRegisterForNowPlayingNotifications
Primed: MRMediaRemoteSetWantsNowPlayingNotifications(true)
Observing now-playing notifications for 8s
MediaRemote read-only now-playing application probe
Application is playing: false
Application PID: 0
Now-playing client: <nil>
MediaRemote read-only now-playing probe
Symbol: MRMediaRemoteGetNowPlayingInfo
Result: callback returned nil dictionary
```

No now-playing notifications were observed during the play/pause cycle.

Current interpretation: the simple global APIs are not enough for Spotify on this machine. The next useful paths are origin/player-path resolution, app-bundle identity experiments, or direct daemon/XPC inspection.

## Origin and Player-Path Probe

With Spotify still active, `mr-now-playing-probe --origins` resolved the active origin and player path even though global now-playing info stayed nil.

Observed result:

```text
Local origin: timed out waiting for MRMediaRemoteGetLocalOrigin
Active origin: success=true, displayName=Mac, originType=0, isLocal=true
Active origin now-playing client: <nil>
Active origin now-playing clients: 0 item(s)
Active origin active player paths: 1 item(s)
Active origin playerPath[0]: LOCL (Mac) -> com.spotify.client (37433) Spotify -> default
Active origin playerPath[0] client: bundleIdentifier=com.spotify.client, displayName=Spotify, processIdentifier=37433
Active origin playerPath[0] player: identifier=MediaRemote-DefaultPlayer, displayName=Default Player, audioSessionType=0
Available origins: 1 item(s)
```

Interpretation: Spotify is visible through MediaRemote's origin/player-path layer even when the older global now-playing client/info calls return nil. The active path is local Mac origin to Spotify client to default player.

Rejected follow-up: calling `MRMediaRemoteGetNowPlayingInfoForClient` with the path-derived `MRClient` object crashed in `MRMediaRemoteGetNowPlayingInfoForClient`. That object is not necessarily the same type expected by the proven Canopy `MRNowPlayingClient` info path.

Rejected queue follow-up: calling `MRMediaRemoteRequestNowPlayingPlaybackQueueForPlayerSync` with the path-derived `MRPlayer` object crashed in the non-sync queue request path. `mr-now-playing-probe --origins --queue` now reports this boundary instead of calling the unsafe function.

Function-start evidence around the player path shows internal framework methods such as `MRNowPlayingOriginClient nowPlayingClientForPlayerPath:`, `MRNowPlayingClient initWithPlayerPath:`, and `MRNowPlayingPlayerClient initWithPlayerPath:`. That suggests a wrapper object may be constructed from the full path before metadata/queue APIs are safe.

Swift bridge rejection: constructing `MRNowPlayingPlayerClient` or `MRNowPlayingPlayerClientRequests` from the active `MRPlayerPath` through Swift-side Objective-C runtime bridging crashed before a usable object could be printed. Crash reports:

- `~/Library/Logs/DiagnosticReports/mr-now-playing-probe-2026-07-16-041234.ips`
- `~/Library/Logs/DiagnosticReports/mr-now-playing-probe-2026-07-16-041335.ips`

The faulting frame landed in `swift_getObjectType` while handling the constructed wrapper. `mr-now-playing-probe --origins --internal-requests` now reports this boundary instead of attempting construction.

Objective-C helper follow-up: `mr-internal-probe` successfully constructs both internal wrappers from the active Spotify player path:

```text
MRNowPlayingPlayerClient.debugDescription:
    playerPath = LOCL (Mac) -> com.spotify.client (Spotify) -> default
    supportedCommands = (null)
    nowPlayingInfo = (null)
    playbackState = Unknown
    playbackQueue = (null)
    capabilities = 0
    canBeNowPlaying = NO

MRNowPlayingPlayerClientRequests.debugDescription:
    playerProperties = (null)
    playbackState = Unknown
    playbackQueue = (null)
    supportedCommands = (null)
```

Interpretation: the internal wrappers are constructible when bridged through Objective-C, but creating them locally from the active `MRPlayerPath` does not by itself hydrate metadata, supported commands, or queue state for Spotify's default player. The next path is to inspect the request enqueue/hydration methods or daemon messages that populate these fields.

Expanded Objective-C helper follow-up: runtime method encodings confirm the request wrapper methods:

```text
MRNowPlayingPlayerClientRequests.updatePlaybackQueueIfUninitialized: encoding: v24@0:8@16
MRNowPlayingPlayerClientRequests.updatePlaybackStateIfUninitialized: encoding: v20@0:8I16
MRNowPlayingPlayerClientRequests.updateSupportedCommandsIfUninitialized: encoding: v24@0:8@16
MRNowPlayingPlayerClientRequests.enqueuePlaybackQueueRequest:completion: encoding: v32@0:8@16@?24
MRNowPlayingPlayerClientRequests.handleSupportedCommandsRequestWithCompletion: encoding: v24@0:8@?16
MRNowPlayingPlayerClientRequests.handlePlaybackStateRequestWithCompletion: encoding: v24@0:8@?16
MRNowPlayingPlayerClientRequests.handlePlayerPropertiesRequestWithCompletion: encoding: v24@0:8@?16
```

Read-style hydration attempts:

```text
MRNowPlayingPlayerClientRequests.handleSupportedCommandsRequestWithCompletion: completion result: <nil>
MRNowPlayingPlayerClientRequests.supportedCommands: <nil>
MRNowPlayingPlayerClientRequests.handlePlayerPropertiesRequestWithCompletion: completion error: Error Domain=kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"
MRNowPlayingPlayerClientRequests.handlePlayerPropertiesRequestWithCompletion: completion result: <nil>
MRNowPlayingPlayerClientRequests.playerProperties: <nil>
```

Interpretation: the request object path is callable from userland, but Spotify's supported commands still return nil and player properties are blocked by MediaRemote policy with `kMRMediaRemoteFrameworkErrorDomain Code=3`. Treat player properties as a permission/entitlement-gated surface until a signed entitlement experiment or daemon-side evidence proves otherwise.

Playback queue request attempt:

```text
MRNowPlayingPlayerClientRequests.enqueuePlaybackQueueRequest request: spelunking.internal-probe.default Spelunking internal probe /M/I/L/AF/R[0:1]
MRNowPlayingPlayerClientRequests.enqueuePlaybackQueueRequest: invoking
MRNowPlayingPlayerClientRequests.enqueuePlaybackQueueRequest completion error: Error Domain=kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"
MRNowPlayingPlayerClientRequests.enqueuePlaybackQueueRequest completion queue: <nil>
MRNowPlayingPlayerClientRequests.playbackQueue: <nil>
```

The request was built with `MRPlaybackQueueRequestCreateDefault`, had the active Spotify `MRPlayerPath` set via `-[MRPlaybackQueueRequest setPlayerPath:]`, and requested metadata plus info while leaving lyrics and sections off. This confirms the richer request route is reachable but still blocked by daemon/framework policy for the unsigned userland helper.

## Next Runtime Steps

- Resolve metadata from the active `MRPlayerPath` without passing `MRClient` to `MRMediaRemoteGetNowPlayingInfoForClient`.
- Inspect the entitlement or XPC daemon policy behind `kMRMediaRemoteFrameworkErrorDomain Code=3` for playback queue and player properties.
- Treat `handlePlayerPropertiesRequestWithCompletion:` as permission-gated for the current unsigned userland helper.
- Preserve `MRPlaybackQueueRequest` construction in the helper, but keep it read-only and guarded until an entitlement/signed-helper experiment is explicit.
- Inspect daemon-facing XPC traffic/service surfaces before any mutating command path.
- Build an app-bundle fixture if CLI `MPNowPlayingInfoCenter` remains invisible.
- Keep command dispatch and route mutation out of runtime probes until read-only state and identity surfaces are understood.
