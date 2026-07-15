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
- [ ] `otool` metadata for extracted framework binary
- [ ] exported symbols
- [ ] Objective-C classes
- [ ] protocols
- [ ] selectors
- [ ] strings
- [ ] notifications
- [x] entitlements for support binaries
- [x] related daemons and agents
- [ ] related services and XPC endpoints
- [ ] generated headers or interfaces
- [ ] runtime experiments

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
