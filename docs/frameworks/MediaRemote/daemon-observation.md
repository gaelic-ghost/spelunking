# MediaRemote Daemon Observation

## Scope

This note tracks runtime evidence from `mediaremoted`, `mediaremoteagent`, AMFI, taskgated, and related unified-log events observed while running local MediaRemote probes.

Raw logs are local-only and ignored under `research/MediaRemote/experiments/daemon-observation/`. Promote only reviewed highlights here.

## Repeatable Capture

Default command:

```sh
tools/mediaremote-daemon-observe.zsh
```

Custom probe command:

```sh
tools/mediaremote-daemon-observe.zsh -- swift run mr-now-playing-probe --origins
```

The runner records:

- environment and Spotify playback state
- probe stdout/stderr
- focused unified-log output for the probe window
- extracted daemon highlights

## Current Observation

### Internal Request Probe

Capture `research/MediaRemote/experiments/daemon-observation/20260716T084110Z` ran the default built `mr-internal-probe` command with Spotify playing.

Observed probe result:

- Active origin resolved successfully.
- One Spotify player path was visible.
- `playerProperties` request returned `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"`.
- `playbackQueue` request returned `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"`.

Observed daemon result:

- `mediaremoted` added a client for the probe process.
- The daemon logged the client with `entitlements=0`.
- The daemon logged `Request: handlePlaybackQueueRequest<spelunking.internal-probe.default ...>`.
- The daemon logged `Response: handlePlaybackQueueRequest<...> returned with error <Error Domain=kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted" ...>`.
- The daemon invalidated and removed the client shortly after the probe completed.

Interpretation: the unsigned/local probe reaches `mediaremoted` and is represented as a daemon-side `MRDMediaRemoteClient`, but `mediaremoted` sees no MediaRemote entitlement bits for it. The playback queue Code 3 is now verified in both probe output and daemon log output. That matches the static entitlement strings documented in `permissions-policy.md`.

### Origin/Application Probe

Capture `research/MediaRemote/experiments/daemon-observation/20260716T084206Z` ran the built `mr-now-playing-probe --origins --application` command with Spotify playing.

Observed probe result:

- Global app-level now-playing state remained empty: `isPlaying=false`, PID `0`, client `nil`, and now-playing dictionary `nil`.
- Active origin resolved as local Mac.
- One Spotify player path was visible through the origin path.
- Path-derived Spotify client identity included bundle identifier `com.spotify.client`, display name `Spotify`, and PID `37433`.

Observed daemon/log result:

- `mediaremoted` added a client for `mr-now-playing-probe` with `entitlements=0`.
- The probe process logged Code 3 responses for `playbackState` and `clientProperties` requests against the Spotify player path.
- The daemon logged multiple `handlePlaybackQueueRequest` responses returning Code 3 for the probe process.
- The daemon invalidated and removed the probe client after the process exited.

Interpretation: origin/player-path identity is readable by the local probe, but richer per-player state hydration still crosses policy-gated request paths. The daemon again sees the probe as `entitlements=0`.

Noise note: the same log window also captured an unrelated `com.apple.perl` client with `entitlements=512` receiving a private playback queue response. That line is useful as a reminder that entitlement bitfields affect queue access, but it is not treated as evidence from the Spelunking probe.

## Boundaries

These observations do not prove which exact daemon-side branch rejects `playerProperties`. They prove the daemon sees the probes as clients with `entitlements=0` during the same run windows where richer request APIs return Code 3, and they directly log playback queue requests returning Code 3.

Next daemon-side work should target more specific log predicates, private log categories, or safe interposition around entitlement-copy helpers before attempting any mutating command or route path.

### XPC Message Trace Probe

Capture `research/MediaRemote/experiments/daemon-observation/20260716T090922Z` ran `tools/mediaremote-xpc-trace-observe.zsh`, which injected `libMRXPCTraceInterpose.dylib` into the built `mr-internal-probe` command while Spotify was playing `Bring Me The Horizon - Doomed`.

Observed probe-side message IDs:

| Message Type | Known Meaning | Probe Context | Result |
| --- | --- | --- | --- |
| `0x0200000000000018` | resolve player path | initial active-origin/player-path setup | success |
| `0x020000000000001B` | get active origin | initial active-origin/player-path setup | success |
| `0x0200000000000027` | get active player paths for local origin | initial active-origin/player-path setup | success |
| `0x0200000000000031` | get supported commands | `handleSupportedCommandsRequestWithCompletion:` | completion result `nil` |
| `0x020000000000000F` | get player properties | `handlePlayerPropertiesRequestWithCompletion:` | Code 3 |
| `0x0200000000000007` | request now-playing playback queue | `enqueuePlaybackQueueRequest:completion:` | Code 3 |

Observed daemon/log result:

- `mediaremoted` added the probe client with `entitlements=0`.
- The daemon logged `Request: handlePlaybackQueueRequest<spelunking.internal-probe.default ...>`.
- The daemon logged the matching response returning `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"` for the active Spotify player path.

Interpretation: the playback queue denial is now correlated across three evidence layers in one capture: local request wrapper, outbound XPC message ID `0x0200000000000007`, and daemon-side `handlePlaybackQueueRequest` Code 3 for an `entitlements=0` client. The player-properties denial is correlated across the local request wrapper and outbound XPC message ID `0x020000000000000F`; daemon logs did not expose a named player-properties handler in this focused window.

Boundary: `MRXPCTraceInterpose` only observes local probe sends. It does not trace daemon internals, change policy decisions, or prove that every request with the same ID will receive the same result for other clients.

### Route Probe

Capture `research/MediaRemote/experiments/daemon-observation/20260716T092126Z` ran the default `mr-route-probe` with `MRXPCTraceInterpose` injected.

Observed probe result:

- Local endpoint resolved as `MRAVLocalEndpoint`.
- Local endpoint UID was `LOCAL`.
- Output-device copying was skipped.
- Shared output-context queries were skipped.

Observed XPC trace:

| Message Type | Observed Context |
| --- | --- |
| `0x0200000000000018` | route probe setup side path, same ID as player-path resolution |
| `0x0100000000000004` | unified log reports `mediaPlaybackVolume` |
| `0x0300000000000004` | unified log reports `volumeControlCapabilities` |
| `0x0100000000000008` | unified log reports `getSystemIsMuted` |

Observed daemon result:

- `mediaremoted` added `mr-route-probe` as a client with `entitlements=0`.
- No Code 3 denial was observed.
- No route-selection, output-device mutation, or volume mutation was requested by the helper.

Interpretation: local endpoint identity is a safe read-oriented probe, but not a zero-daemon-contact probe. MediaRemote lazily initializes route/volume state around this surface.
