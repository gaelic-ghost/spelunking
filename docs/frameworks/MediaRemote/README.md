# MediaRemote.framework

## Scope

Research `MediaRemote.framework` and related now-playing, media-control, route, and userland access surfaces on:

- active macOS 26.5 system frameworks
- installed macOS 27 beta SDK frameworks and generated interfaces

The goal is to document types, functions, signatures, hooks, notifications, callbacks, and experiments that improve userland access to media controls and now-playing state.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5.2, build 25F84 |
| SDK comparison | Xcode 26.6 MacOSX26.5 SDK and Xcode 27.0 beta SDK |
| Primary machine | GMBP16 |
| Swift toolchain at repo bootstrap | Apple Swift 6.3.3 |

The first evidence capture is recorded in `../../../research/MediaRemote/baseline-2026-07-15.md`.

## Evidence Inventory

- [x] Active framework path
- [x] Beta SDK framework path
- [x] `otool` metadata for support binaries
- [x] exported symbols from live dyld cache
- [x] Objective-C class names from exported symbols
- [x] protocols from selected runtime classes
- [x] selectors and method strings from dyld capture
- [x] strings
- [x] notifications
- [x] entitlements for support binaries
- [x] related daemons and agents
- [x] related services and XPC endpoints
- [x] runtime interface descriptions for selected classes
- [x] read-only runtime experiments

## Interesting Areas

- now-playing metadata
- now-playing queues
- playback state
- playback commands
- origins and clients
- routes, destinations, and endpoint selection
- notifications and callbacks
- app and daemon boundaries
- sandbox, TCC, entitlement, and SIP-disabled behavior

## Notes

Keep raw captures in `research/MediaRemote/`. Promote stable findings into the topic files in this directory.

Start with read-only discovery before sending playback commands or mutating routes.

Initial local evidence shows the active framework directories are dyld-cache framework shells rather than ordinary binary-bearing framework directories. Live binary inspection should use dyld shared-cache tooling or extracted cache images.

See `live-dyld-cache.md` for the first live export classification and read-only now-playing probe result.

See `runtime-probes.md` for the Spotify and fixture-backed runtime results.

## Topic Files

- `inventory-captures.md`: repeatable capture workflow and latest capture inventory.
- `live-dyld-cache.md`: dyld-cache inspection notes, live/SDK symbol counts, and export buckets.
- `symbols.md`: exported symbol families and SDK differences.
- `now-playing-architecture.md`: now-playing identity, notifications, metadata keys, playback queues, and controller generations.
- `runtime-probes.md`: local Swift probes and observed runtime behavior.
- `runtime-interfaces.md`: recovered Objective-C runtime class interfaces and high-value request wrappers.
- `agents-daemons.md`: `mediaremoted`, `mediaremoteagent`, entitlements, mach services, and daemon authority boundaries.
- `daemon-observation.md`: repeatable unified-log captures around probe runs and daemon-side client evidence.
- `entitlement-model.md`: entitlement helper symbols, daemon bitfield evidence, named entitlement status, and mapping gaps.
- `xpc-and-messages.md`: XPC service names, message keys, command paths, endpoint routing, and serialization hints.
- `permissions-policy.md`: runtime Code 3 denials, entitlement names, audit-token policy, and signed-helper experiment boundaries.
- `routes-output-devices.md`: endpoint, route, output context, output device, and discovery surfaces.
- `experiments.md`: experiment log and next steps.
- `references.md`: links within this research package.
