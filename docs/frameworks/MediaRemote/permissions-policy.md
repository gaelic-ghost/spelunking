# MediaRemote Permissions and Policy

## Scope

This note tracks permission, entitlement, audit-token, and runtime-denial evidence for `MediaRemote.framework`, `mediaremoted`, and related now-playing request surfaces.

Keep verified runtime failures separate from static string inference. The current local helper is an unsigned userland command-line tool linked through `dlopen`/`dlsym`, so any entitlement conclusion here is a candidate boundary until a signed-helper experiment validates it.

## Verified Runtime Boundaries

With Spotify active and resolved through the local origin/player path, the Objective-C helper can construct internal wrapper objects:

- `MRNowPlayingPlayerClient`
- `MRNowPlayingPlayerClientRequests`
- `MRPlaybackQueueRequest`

The same helper can call request methods without crashing, but richer data hydration is policy-limited:

| Operation | Result | Interpretation |
| --- | --- | --- |
| `handleSupportedCommandsRequestWithCompletion:` | completion result `nil`, no error | Callable, but no commands hydrated for the current helper/player path. |
| `handlePlayerPropertiesRequestWithCompletion:` | `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"` | Verified permission denial. |
| `enqueuePlaybackQueueRequest:completion:` with `MRPlaybackQueueRequestCreateDefault` and active Spotify `MRPlayerPath` | `kMRMediaRemoteFrameworkErrorDomain Code=3 "Operation not permitted"` | Verified permission denial for playback queue hydration. |

This makes the active origin/player-path route real, but not sufficient for full now-playing metadata, player properties, or queue access from the current helper.

Message-ID correlation from capture `research/MediaRemote/experiments/daemon-observation/20260716T090922Z`:

| Operation | Outbound Message ID | Daemon Evidence |
| --- | --- | --- |
| `handleSupportedCommandsRequestWithCompletion:` | `0x0200000000000031` | No daemon denial observed; local completion returned `nil`. |
| `handlePlayerPropertiesRequestWithCompletion:` | `0x020000000000000F` | Local completion returned Code 3. |
| `enqueuePlaybackQueueRequest:completion:` | `0x0200000000000007` | Daemon logged `handlePlaybackQueueRequest` Code 3 for the same probe client with `entitlements=0`. |

## Static Framework Evidence

The live framework string sections include explicit policy and error strings:

- `kMRMediaRemoteFrameworkErrorDomain`
- `Operation not permitted`
- `Does not have required entitlements`
- `com.apple.mediaremote.device-info`
- `Missing entitlement <com.apple.mediaremote.device-info> to fetch deviceInfo. Please file a radar for this process to obtain this entitlement`

Function-start evidence also names entitlement-copy helpers:

- `MRMediaRemoteCopyApplicationEntitlements`
- `MRMediaRemoteCopyEntitlements`

Inference: MediaRemote has a framework-level entitlement model that can inspect a calling application/process and return `kMRMediaRemoteFrameworkErrorDomain Code=3` for operations outside the caller's policy.

## Daemon Policy Evidence

`mediaremoted` strings show daemon-side client validation and entitlement checks:

- `_validateAuditTokens:pids:auditTokens:`
- `com.apple.nowplaying.entitlement`
- `Unable to register for waking now playing notifications without entitlement: %@`
- `com.apple.mediaremote.waking-now-playing-notifications`
- `Client <%@> missing entitlement needed to send command <%@> to arbitrary apps. Sending to NowPlayingApp instead of <%@>.`
- `Tried to restrict command clients without entitlement. Ignoring.`
- `Missing entitlement needed to modify output context. Operation will likley not work`
- `Client is not entitled for NowPlaying Acesss: %@`
- `PID Mismatch: Client %{public}@ is trying to make a nowPlayingClient with a different pid %d`

Inference: the daemon does not only trust object identity passed over XPC. It checks audit tokens, process identifiers, and entitlement state before allowing now-playing read access, command targeting, waking notifications, output-context modification, and client construction for a different PID.

## Entitlement Names

`mediaremoted` itself is broadly entitled. Its captured entitlements include these MediaRemote-specific keys:

- `com.apple.mediaremote.group-sessions`
- `com.apple.mediaremote.nearby-device`
- `com.apple.mediaremote.remote-control-discovery`
- `com.apple.mediaremote.send-commands`
- `com.apple.mediaremote.set-now-playing-app`
- `com.apple.mediaremote.set-playback-state`
- `com.apple.mediaremote.ui-control`
- `com.apple.mediaremote.ui-server-connection`

Additional entitlement names appear in daemon/framework strings:

- `com.apple.mediaremote.now-playing-read-access`
- `com.apple.mediaremote.full-now-playing-read-access`
- `com.apple.mediaremote.device-info`
- `com.apple.mediaremote.waking-now-playing-notifications`
- `com.apple.mediaremote.set-default-supported-commands`
- `com.apple.mediaremote.restrict-command-clients`
- `com.apple.mediaremote.request-bless`
- `com.apple.mediaremote.critical-section-creation`
- `com.apple.mediaremote.critical-section-management`
- `com.apple.mediaremote.critical-section-monitor`
- `com.apple.mediaremote.active-system-endpoint-assertion`
- `com.apple.nowplaying.entitlement`

Inference: the current Code 3 denials for `playerProperties` and `playbackQueue` are most likely part of the now-playing read-access/full-read-access family, but the exact key has not been proven by a signed-helper A/B test.

## Safe Boundary Matrix

| Surface | Current boundary |
| --- | --- |
| Active origin and available origins | Verified read-only and stable. |
| Active player paths for origin | Verified read-only and stable. |
| Path-derived client/player identity getters | Verified useful for identity strings, bundle ID, display name, PID, and default player. |
| Internal Objective-C wrapper construction | Verified constructible in Objective-C, not Swift bridging. |
| Supported commands request | Callable, currently returns `nil`. |
| Player properties request | Callable, denied with Code 3. |
| Playback queue request | Callable, denied with Code 3. |
| Global now-playing app/client/info calls | Verified safe but empty on this system for Spotify and CLI fixture. |
| `MRMediaRemoteGetNowPlayingInfoForClient` with path-derived `MRClient` | Unsafe; crashed. |
| `MRMediaRemoteRequestNowPlayingPlaybackQueueForPlayerSync` with path-derived `MRPlayer` | Unsafe; crashed. |
| Swift-side construction of internal wrapper classes | Unsafe; crashed in Swift runtime object bridging. |
| Commands, route mutation, output-context mutation, set-now-playing-app, set-playback-state | Mutating or authority-sensitive; keep behind explicit experiment flags and separate approval. |

## Signed-Helper Experiment Path

A tiny signed macOS command-line helper flow repeats the current Objective-C request calls with one entitlement change per run.

Command:

```sh
tools/mediaremote-entitlement-experiment.zsh
tools/mediaremote-entitlement-experiment.zsh --identity auto
```

The runner builds `mr-internal-probe`, copies the product into an ignored capture directory, signs copied variants with candidate entitlements, records signature details and embedded entitlements, captures each run, and records a short policy-focused system log.

Candidate entitlement families to test first:

1. `com.apple.mediaremote.now-playing-read-access`
2. `com.apple.mediaremote.full-now-playing-read-access`
3. `com.apple.mediaremote.device-info`
4. `com.apple.nowplaying.entitlement`

Only after read access is understood should command or route entitlements be tested:

- `com.apple.mediaremote.send-commands`
- `com.apple.mediaremote.set-now-playing-app`
- `com.apple.mediaremote.set-playback-state`
- `com.apple.mediaremote.remote-control-discovery`
- `com.apple.avfoundation.allows-set-output-device`

Current result from capture `20260716T083329Z`:

- Baseline copied helper ran with active Spotify playback, resolved one active player path, and still returned Code 3 for `playerProperties` and `playbackQueue`.
- `codesign` embedded each candidate entitlement successfully into copied helper variants.
- Every ad-hoc signed private-entitlement variant exited with status 137 before running probe code.
- Unified log evidence from AMFI/amfid reports `AppleMobileFileIntegrityError Code=-424 "The file is adhoc signed but contains restricted entitlements"` and kernel `load code signature error 4`.

Current Apple Development identity result from capture `20260716T083557Z`:

- `--identity auto` resolved to a local Apple Development certificate hash.
- `codesign` succeeded for all four private-entitlement variants.
- Signature details show an Apple Development chain and team identifier `BC73766F69`.
- Each requested private entitlement is embedded in the corresponding variant.
- Every private-entitlement variant still exited with status 137 before running probe code.
- Unified log evidence includes taskgated reporting `Unsatisfied entitlements: com.apple.mediaremote.now-playing-read-access`; AMFI still reports restricted-entitlement validation failure and kernel `load code signature error 4`.

Current Developer ID identity result from capture `20260716T083725Z`:

- Explicit Developer ID signing with certificate hash `7C250E5B3750CAC924FD0960D224A7BA5E3E4399` succeeded for all four private-entitlement variants.
- Signature details show a Developer ID Application chain and team identifier `BC73766F69`.
- Each requested private entitlement is embedded in the corresponding variant.
- Every private-entitlement variant still exited with status 137 before running probe code.
- Unified log evidence names all four unsatisfied entitlement keys: `com.apple.mediaremote.now-playing-read-access`, `com.apple.mediaremote.full-now-playing-read-access`, `com.apple.mediaremote.device-info`, and `com.apple.nowplaying.entitlement`.

Interpretation: on this system, the first four candidate entitlement keys are restricted at code-signature validation time for ad-hoc, local Apple Development, and Developer ID signing. They cannot currently be used as a simple SIP-disabled signing bypass for the Code 3 MediaRemote policy boundary.

Risk: private entitlements may be rejected, ignored, or treated differently for non-Apple-signed binaries even on a SIP-disabled local system. The experiment records the resulting code signature, embedded entitlements, runtime error, and system log evidence so each future signing lane can be compared against the baseline.

Current capture location pattern:

- `research/MediaRemote/experiments/entitlements/<timestamp>/`

## Repeatable Evidence

`tools/mediaremote-inventory.zsh` now captures focused policy files in addition to the broader string inventories:

- `dyld-policy-strings.txt`
- `symbols-policy-targets.txt`
- `mediaremoted-policy-strings.txt`
- `mediaremoteagent-policy-strings.txt`

Use those files when updating this note so entitlement and policy evidence remains easy to diff across OS and SDK captures.

See `entitlement-model.md` for the current mapping between named entitlement strings, daemon bitfield evidence, and unresolved bit-position questions.
