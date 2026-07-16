# MediaRemote Experiments

## Read-Only Experiments

- [x] Print current now-playing metadata.
- [ ] Observe now-playing notifications.
- [ ] List origins or clients if available.
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
