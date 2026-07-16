# MediaRemote Entitlement Model

## Scope

This note maps the current evidence for MediaRemote entitlement names, daemon bitfields, and entitlement-check helper surfaces.

Separate hard evidence from inference. The bit names and bit positions are not fully recovered yet.

## Framework Helpers

`symbols-policy-targets.txt` identifies two exported entitlement helper functions in the live framework:

- `MRMediaRemoteCopyApplicationEntitlements`
- `MRMediaRemoteCopyEntitlements`

The same lookup also finds:

- `DYLD-STUB$$SecTaskCopyValuesForEntitlements`
- `objc_msgSend$hasBoolEntitlement:shouldLogForMissingEntitlement:`
- `MRMediaRemoteServiceCopyDeviceInfo.entitlements`
- `MRMediaRemoteServiceCopyDeviceInfo.entitlementOnceToken`

Interpretation: client entitlement state is not only daemon-local. The framework image contains helper paths for copying application entitlements, using Security.framework task entitlement APIs, and checking boolean entitlements by name.

## Daemon Client Bitfield

`mediaremoted` strings include the property and debug output for a daemon-side client entitlement bitfield:

- `TQ,R,N,V_entitlements`
- `_entitlements`
- `entitlements`
- `<%@ %p, bundleIdentifier = %@, pid = %ld, entitlements=%lu>`
- `    entitlements=%ld`

Runtime observation confirms the field is populated in daemon logs:

- Spelunking probes: `entitlements=0`
- Unrelated `com.apple.perl` queue client observed in the same log window: `entitlements=512`

Interpretation: `mediaremoted` projects named entitlement checks into a numeric bitfield on `MRDMediaRemoteClient`. The current probes have no bits set. The observed `512` client is not a Spelunking probe, but it shows that nonzero entitlement bitfields appear in ordinary daemon logging and can correlate with successful private queue responses.

## Named Entitlements

Names observed in daemon/framework strings:

| Entitlement | Evidence | Current status |
| --- | --- | --- |
| `com.apple.mediaremote.now-playing-read-access` | daemon string, AMFI unsatisfied entitlement log | Restricted entitlement; local ad-hoc, Apple Development, and Developer ID signing cannot satisfy it. |
| `com.apple.mediaremote.full-now-playing-read-access` | daemon string, AMFI unsatisfied entitlement log | Restricted entitlement; local signing cannot satisfy it. |
| `com.apple.mediaremote.device-info` | framework string, daemon string, AMFI unsatisfied entitlement log | Restricted entitlement; local signing cannot satisfy it. |
| `com.apple.nowplaying.entitlement` | daemon string, AMFI unsatisfied entitlement log | Restricted entitlement; local signing cannot satisfy it. |
| `com.apple.mediaremote.waking-now-playing-notifications` | daemon string and missing-entitlement log format | Not runtime-tested yet. |
| `com.apple.mediaremote.send-commands` | daemon entitlement and command-policy string | Mutating; not runtime-tested from local probes. |
| `com.apple.mediaremote.set-now-playing-app` | daemon entitlement and missing-entitlement string | Mutating; not runtime-tested from local probes. |
| `com.apple.mediaremote.set-playback-state` | daemon entitlement | Mutating; not runtime-tested from local probes. |
| `com.apple.mediaremote.remote-control-discovery` | daemon entitlement | Route/control discovery authority; not runtime-tested from local probes. |

## Current Policy Picture

Verified:

- Local probes can resolve origins and player paths.
- Local probes are logged by `mediaremoted` with `entitlements=0`.
- Local probes receive Code 3 `Operation not permitted` for playback queue hydration, with daemon-side `handlePlaybackQueueRequest` logging.
- Local signing identities can embed the first four candidate private entitlements, but AMFI/taskgated rejects those binaries before they run.

Inferred:

- `now-playing-read-access` and/or `full-now-playing-read-access` likely gate playback state, client properties, player properties, and playback queue hydration.
- `mediaremoted` likely derives `MRDMediaRemoteClient.entitlements` from named entitlement checks at XPC client registration time.
- The exact bit positions are not recovered. `512` is only observed as a nonzero entitlement bitfield for an unrelated process and should not be assigned to a named entitlement without more evidence.

## Next Mapping Work

- Capture a narrower daemon log window around known Apple-signed or system clients that successfully request playback queues.
- Find an Apple-signed host process or tool that carries one of the named MediaRemote entitlements and compare its daemon `entitlements=%lu` value.
- Safely inspect or interpose around `MRMediaRemoteCopyEntitlements` only in local private experiments, keeping mutating command paths out of scope until the read policy is mapped.
