# Spelunking

Private Apple platform research for SIP-disabled, "peer behind the curtain" exploration.

This repository is for focused investigations into macOS, iOS, and Apple-platform frameworks, services, daemons, private APIs, headers, symbols, and runtime behavior. Each pass should study one framework, service, subsystem, or tightly related category at a time, then leave behind documentation that is useful for future tools and projects.

The first research target is `MediaRemote.framework` on macOS 26.5 and the installed macOS 27 beta SDK, with related now-playing, media-control, route, and userland access surfaces in scope.

## Repo Layout

- `docs/`: durable writeups meant to be read later.
- `docs/frameworks/<Name>/`: polished notes for one framework, service, or subsystem.
- `research/<Name>/`: raw evidence, command notes, symbol dumps, generated headers, experiments, and local-only working material for one research target.
- `Sources/`: Swift package sources for reusable research helpers and command-line tools.
- `Tests/`: Swift package tests for reusable helpers.
- `tools/`: standalone scripts and helper notes that are not SwiftPM targets yet.

## Current Tools

- `spelunk`: prints the current seeded research target paths.
- `mr-now-playing-probe`: read-only dynamic `MediaRemote.framework` probe for global now-playing info, app PID/is-playing/client state, client/player lists, and short notification observation windows.
- `mr-internal-probe`: Objective-C helper for internal `MediaRemote.framework` wrapper experiments that need direct Objective-C runtime calls.
- `now-playing-fixture`: metadata-only fixture for testing whether `MPNowPlayingInfoCenter` publication appears through MediaRemote.
- `tools/mediaremote-inventory.zsh`: repeatable local capture script for dyld-cache exports, imports, strings, ObjC names, SDK diffs, support binaries, resources, and entitlements.
- `tools/mediaremote-entitlement-experiment.zsh`: repeatable local runner that builds `mr-internal-probe`, signs copied variants with candidate private entitlements, and captures runtime differences.
- `tools/mediaremote-daemon-observe.zsh`: repeatable local runner that executes a probe and captures focused `mediaremoted`/unified-log evidence for the same time window.

## Research Shape

Every target should answer the same core questions:

- What public, private, and runtime-discovered entry points exist?
- Which types, functions, notifications, constants, callbacks, and XPC or daemon edges look useful?
- Which symbols are present in the active OS framework, and which appear in the installed beta SDK?
- What can userland call directly, what needs entitlements or TCC, and what only works under SIP-disabled/private-lane conditions?
- Which observations were verified locally, and which are still inferred from headers, symbols, strings, or behavior?

Keep raw captures in `research/<Name>/` and promote only cleaned, reusable knowledge into `docs/frameworks/<Name>/`.

## Current Target

`MediaRemote.framework` and related media-control surfaces:

- now-playing metadata and queues
- playback state and command dispatch
- origin, route, and destination discovery
- app, daemon, XPC, notification, and private-framework boundaries
- macOS 26.5 versus macOS 27 beta SDK differences

See `docs/frameworks/MediaRemote/README.md` for the starting outline.

Useful current commands:

```sh
swift run mr-now-playing-probe --all
swift run mr-now-playing-probe --origins
swift run mr-internal-probe
swift run mr-now-playing-probe --observe 10 --application
tools/mediaremote-inventory.zsh
tools/mediaremote-entitlement-experiment.zsh
tools/mediaremote-daemon-observe.zsh
```
