# MediaRemote Experiments

## Read-Only Experiments

- [x] Print current now-playing metadata.
- [x] Observe now-playing notifications.
- [x] List origins or clients if available.
- [ ] List routes or destinations if available.

### Read-Only Now-Playing Probe

Status: baseline complete, needs active-playback follow-up

Command:

```sh
swift run mr-now-playing-probe
```

Observed behavior:

```text
MediaRemote read-only now-playing probe
Symbol: MRMediaRemoteGetNowPlayingInfo
Result: callback returned nil dictionary
```

Meaning:

The helper successfully loads `MediaRemote.framework`, resolves `MRMediaRemoteGetNowPlayingInfo`, and receives a callback. On the baseline run, no dictionary was returned.

Follow-up results:

- Active Spotify playback still returned nil MediaRemote now-playing state through the direct read path.
- A metadata-only `MPNowPlayingInfoCenter` fixture still returned nil MediaRemote now-playing state through the direct read path.
- App-level callbacks with locally evidenced signatures returned `isPlaying=false`, PID `0`, and nil client in both cases.

Next: keep a run loop alive after registering for notifications, then query players/clients and player-specific info.

### Entitlement A/B Runner

Status: baseline run complete, private-entitlement variants blocked at launch

Command:

```sh
tools/mediaremote-entitlement-experiment.zsh
tools/mediaremote-entitlement-experiment.zsh --identity auto
```

Expected behavior:

The runner builds `mr-internal-probe`, copies the product into an ignored experiment capture directory, signs copied variants with one candidate entitlement each, records signature details and embedded entitlements, and runs the same internal wrapper request path for every successfully signed variant.

Candidate entitlements:

- `com.apple.mediaremote.now-playing-read-access`
- `com.apple.mediaremote.full-now-playing-read-access`
- `com.apple.mediaremote.device-info`
- `com.apple.nowplaying.entitlement`

Observed behavior:

Capture `research/MediaRemote/experiments/entitlements/20260716T083329Z`:

- Baseline copied helper ran with active Spotify playback and one active Spotify player path.
- Baseline `playerProperties` and `playbackQueue` requests both returned `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"`.
- Each candidate entitlement embedded successfully according to `codesign -d --entitlements -`.
- Each private-entitlement variant exited with status 137 before probe output.
- Unified log evidence reports AMFI/amfid `AppleMobileFileIntegrityError Code=-424 "The file is adhoc signed but contains restricted entitlements"` for the private-entitled variants.

Capture `research/MediaRemote/experiments/entitlements/20260716T083557Z`:

- `--identity auto` resolved to a local Apple Development certificate hash.
- `codesign` succeeded for the same four private-entitlement variants.
- Signature details show `Authority=Apple Development: Gale Williams (AMRC3N39SQ)` and `TeamIdentifier=BC73766F69`.
- Each candidate entitlement embedded successfully.
- Each private-entitlement variant still exited with status 137 before probe output.
- Unified log evidence reports taskgated `Unsatisfied entitlements: com.apple.mediaremote.now-playing-read-access`, restricted entitlement validation failure, and kernel `load code signature error 4`.

Capture `research/MediaRemote/experiments/entitlements/20260716T083725Z`:

- Explicit Developer ID signing with certificate hash `7C250E5B3750CAC924FD0960D224A7BA5E3E4399` succeeded for the same four private-entitlement variants.
- Signature details show `Authority=Developer ID Application: Gale Williams (BC73766F69)` and `TeamIdentifier=BC73766F69`.
- Each candidate entitlement embedded successfully.
- Each private-entitlement variant still exited with status 137 before probe output.
- Unified log evidence names all four unsatisfied entitlement keys and reports restricted entitlement validation failure plus kernel `load code signature error 4`.

Permissions, entitlements, or SIP notes:

Private entitlements can embed successfully in ad-hoc, Apple Development, or Developer ID signatures but still fail code-signature validation at launch. On this macOS 26.5.2 system, these first four candidates do not reach `mediaremoted`; AMFI kills the helper before MediaRemote can evaluate the request.

Follow-up:

Next useful path is daemon-side observation, an Apple-signed host process, or a non-entitlement metadata route. Normal local signing identities are not enough to satisfy these restricted entitlement checks.

### Daemon Observation Runner

Status: baseline run complete

Command:

```sh
tools/mediaremote-daemon-observe.zsh
```

Observed behavior:

Capture `research/MediaRemote/experiments/daemon-observation/20260716T084110Z` ran the built `mr-internal-probe` while Spotify was playing. The probe resolved one Spotify player path and returned Code 3 for both `playerProperties` and `playbackQueue`. The focused unified-log capture shows `mediaremoted` adding a client for the probe with `entitlements=0`, logging `handlePlaybackQueueRequest`, returning Code 3 for that request, then invalidating and removing the client after the probe exits.

Capture `research/MediaRemote/experiments/daemon-observation/20260716T084206Z` ran the built `mr-now-playing-probe --origins --application` while Spotify was playing. The probe resolved the local Mac origin and Spotify player path while the global now-playing app/client/info surface remained empty. The focused unified-log capture shows the probe client with `entitlements=0`, Code 3 responses for playback state/client properties, and daemon-side Code 3 responses for playback queue requests.

Permissions, entitlements, or SIP notes:

This proves the probes reach the daemon as real clients, but not as entitled MediaRemote clients. It also proves the playback queue Code 3 is emitted on the daemon side, while playback state and client properties also fail under the same zero-entitlement client condition.

Follow-up:

Add narrower daemon predicates or safe helper interposition around entitlement-copy functions before exploring mutating commands.

### Runtime Interface Capture

Status: baseline run complete

Command:

```sh
tools/mediaremote-interface-capture.zsh
```

Observed behavior:

Capture `research/MediaRemote/experiments/interfaces/20260716T085016Z` built `mr-interface-probe` and produced grouped Objective-C runtime metadata for now-playing request wrappers, origin/client identity classes, controller classes, and `MRXPCConnection`.

The recovered interface evidence confirms `MRNowPlayingPlayerClientRequests` owns cached playback queue, playback state, supported commands, and player properties state; exposes `initWithPlayerPath:`; and provides the request handlers already exercised by `mr-internal-probe`.

Permissions, entitlements, or SIP notes:

This capture is read-only runtime metadata. It does not instantiate classes, send XPC messages, query `mediaremoted`, or mutate playback/routes.

Follow-up:

Use the recovered selectors to map `MRXPCConnection` message lifetimes and `MRNowPlayingClientRequests` hydration paths before attempting any new mutating command surface.

## Mutating Experiments

Run only after the read-only baseline is documented.

- [ ] Send a playback command.
- [ ] Change playback position.
- [ ] Inspect queue or route mutation behavior.

## Experiment Template

### Name

Status: planned

Command:

```sh

```

Expected behavior:

Observed behavior:

Permissions, entitlements, or SIP notes:

Follow-up:
