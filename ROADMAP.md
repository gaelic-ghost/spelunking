# Roadmap

## Phase 0: Repository Foundation

- [x] Create a SwiftPM-ready research repository.
- [x] Add local agent guidance for Apple docs, private research evidence, and Swift tooling.
- [x] Establish durable documentation and raw research directories.
- [x] Seed the first target outline for `MediaRemote.framework`.

## Phase 1: MediaRemote Baseline

- [ ] Locate active macOS 26.5 framework paths and installed macOS 27 beta SDK framework paths.
- [ ] Record framework metadata: install names, architectures, linked libraries, entitlements, strings, exported symbols, Objective-C classes, protocols, selectors, and notifications.
- [ ] Compare macOS 26.5 and macOS 27 beta SDK symbol surfaces.
- [x] Query the live dyld shared-cache export surface for `MediaRemote.framework`.
- [ ] Identify public wrappers, private headers, generated headers, XPC services, launchd jobs, daemons, and related frameworks.
- [ ] Document userland-callable APIs for now-playing metadata, playback commands, queue information, origin discovery, and route or destination behavior.
- [ ] Mark calls that require entitlements, elevated privileges, SIP-disabled conditions, or private-framework linking.
- [x] Build one small Swift helper that safely probes now-playing state without mutating playback.
- [ ] Confirm non-empty now-playing dictionary shape while active media is playing.

## Phase 2: Media Control Experiments

- [ ] Build targeted experiments for read-only now-playing state.
- [ ] Build targeted experiments for playback command dispatch.
- [ ] Explore notification and callback delivery behavior.
- [ ] Explore per-app, per-origin, and route-aware media state.
- [ ] Document failure modes, required host context, sandbox behavior, and privacy prompts.

## Phase 3: Reusable Research Tooling

- [ ] Add shared Swift helpers for command execution, symbol inventory parsing, plist parsing, and evidence capture.
- [ ] Add repeatable framework inventory scripts for future targets.
- [ ] Add diff tooling for active OS versus SDK framework surfaces.
- [ ] Add report templates for frameworks, daemons, XPC services, and subsystem categories.

## Later Targets

- [ ] Related media frameworks, daemons, and services discovered during the `MediaRemote.framework` pass.
- [ ] Other macOS and iOS private frameworks that can inform Gale's educational projects and local tools.
- [ ] SIP-disabled local-only workflows that should never be promoted into public package, App Store, or customer-facing surfaces without a separate decision.
