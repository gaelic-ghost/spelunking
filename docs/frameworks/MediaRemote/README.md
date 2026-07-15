# MediaRemote.framework

## Scope

Research `MediaRemote.framework` and related now-playing, media-control, route, and userland access surfaces on:

- active macOS 26.5 system frameworks
- installed macOS 27 beta SDK frameworks and generated interfaces

The goal is to document types, functions, signatures, hooks, notifications, callbacks, and experiments that improve userland access to media controls and now-playing state.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5 |
| SDK comparison | macOS 27 beta SDK |
| Primary machine | GMBP16 |
| Swift toolchain at repo bootstrap | Apple Swift 6.3.3 |

Update this table with exact build numbers, Xcode paths, SDK paths, and command output once the first evidence capture starts.

## Evidence Inventory

- [ ] Active framework path
- [ ] Beta SDK framework path
- [ ] `otool` metadata
- [ ] exported symbols
- [ ] Objective-C classes
- [ ] protocols
- [ ] selectors
- [ ] strings
- [ ] notifications
- [ ] entitlements
- [ ] related daemons, agents, services, and XPC endpoints
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
