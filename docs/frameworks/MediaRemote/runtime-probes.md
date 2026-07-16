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

Rejected guessed signatures:

- `MRMediaRemoteGetNowPlayingApplicationDisplayID`
- `MRMediaRemoteGetNowPlayingApplicationDisplayName`

Those display ID/name callbacks crashed when guessed as `block(CFStringRef)`. Do not call them again until header, disassembly, or a proven adapter confirms their real signatures.

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

## Next Runtime Steps

- Try origin/player-path resolution paths rather than only global now-playing calls.
- Inspect daemon-facing XPC traffic/service surfaces before any mutating command path.
- Build an app-bundle fixture if CLI `MPNowPlayingInfoCenter` remains invisible.
- Keep command dispatch and route mutation out of runtime probes until read-only state and identity surfaces are understood.
