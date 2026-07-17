# Project Roadmap

This roadmap tracks durable research milestones without turning raw investigation notes into a second planning system.

## Table of Contents

- [Vision](#vision)
- [Product Principles](#product-principles)
- [Milestone Progress](#milestone-progress)
- [Milestone 0: Repository Foundation](#milestone-0-repository-foundation)
- [Milestone 1: MediaRemote Baseline](#milestone-1-mediaremote-baseline)
- [Milestone 2: Media Control Experiments](#milestone-2-media-control-experiments)
- [Milestone 3: Reusable Research Tooling](#milestone-3-reusable-research-tooling)
- [Small Tickets](#small-tickets)
- [Backlog Candidates](#backlog-candidates)
- [History](#history)

## Vision

Build a trustworthy private knowledge base and set of local tools for understanding Apple-platform frameworks and services from source evidence through safe runtime experiments.

## Product Principles

- Study one coherent target at a time.
- Keep raw evidence separate from cleaned documentation.
- Prefer read-only, repeatable experiments before mutation.
- Record environment and permission boundaries with every claim they affect.
- Keep public release and redistribution outside this private research lane unless explicitly reconsidered.

## Milestone Progress

- Milestone 0: Repository Foundation - Completed
- Milestone 1: MediaRemote Baseline - In Progress
- Milestone 2: Media Control Experiments - Planned
- Milestone 3: Reusable Research Tooling - In Progress

## Milestone 0: Repository Foundation

### Status

Completed

### Scope

- [x] Establish a SwiftPM-ready private research repository with durable documentation, evidence directories, agent guidance, and local maintenance entrypoints.

### Tickets

- [x] Create a SwiftPM-ready research repository.
- [x] Add local agent guidance for Apple docs, private research evidence, and Swift tooling.
- [x] Establish durable documentation and raw research directories.
- [x] Seed the first target outline for `MediaRemote.framework`.
- [x] Install repo-owned validation, shared-sync, and release-maintenance entrypoints.

### Exit Criteria

- [x] A new target has clear locations for source, tests, raw evidence, polished docs, and repeatable maintenance commands.

## Milestone 1: MediaRemote Baseline

### Status

In Progress

### Scope

- [ ] Map the active MediaRemote framework and beta SDK surfaces, prove safe userland observations, and document the permission and process boundaries around now-playing, routes, XPC, and daemon behavior.

### Tickets

- [x] Locate active macOS 26.5 framework paths and installed macOS 27 beta SDK framework paths.
- [x] Record framework metadata, linked libraries, entitlements, strings, exports, Objective-C names, selectors, and notifications.
- [x] Compare macOS 26.5 and macOS 27 beta SDK symbol surfaces.
- [x] Query the live dyld shared-cache export surface for `MediaRemote.framework`.
- [x] Identify local wrappers, XPC services, jobs, daemons, and related frameworks.
- [ ] Generate or recover private headers and interfaces for high-value symbols.
- [x] Document userland-callable now-playing, command, queue, origin, route, and destination APIs.
- [x] Mark entitlement, privilege, SIP, and private-framework boundaries.
- [x] Build and test a non-mutating now-playing probe against active Spotify playback.
- [x] Build a metadata-only now-playing fixture and test its MediaRemote visibility.
- [x] Resolve active Spotify identity through origin and player-path APIs.
- [ ] Confirm a non-empty now-playing dictionary through origin/player paths, daemon observation, or an app-bundle fixture.

### Exit Criteria

- [ ] High-value interfaces are documented and a non-empty now-playing path is reproduced with environment evidence.

## Milestone 2: Media Control Experiments

### Status

Planned

### Scope

- [ ] Extend the baseline into narrowly bounded media-state and command experiments after the read-only behavior and permission model are understood.

### Tickets

- [ ] Build targeted experiments for read-only now-playing state.
- [ ] Build targeted experiments for playback command dispatch.
- [ ] Explore notification and callback delivery behavior.
- [ ] Explore per-app, per-origin, and route-aware media state.
- [ ] Document failure modes, required host context, sandbox behavior, and privacy prompts.

### Exit Criteria

- [ ] Each experiment has a reproducible command, captured result, documented side effects, and explicit permission boundary.

## Milestone 3: Reusable Research Tooling

### Status

In Progress

### Scope

- [ ] Turn repeated evidence-gathering work into small composable Swift helpers and scripts that future research targets can reuse.

### Tickets

- [ ] Add shared Swift helpers for command execution, symbol inventory parsing, plist parsing, and evidence capture.
- [x] Add repeatable MediaRemote inventory and observation scripts.
- [ ] Generalize framework inventory scripts for future targets.
- [ ] Add reusable diff tooling for active OS versus SDK surfaces.
- [ ] Add report templates for frameworks, daemons, XPC services, and subsystem categories.

### Exit Criteria

- [ ] A second framework target can reuse the core capture and reporting path without copying MediaRemote-specific implementation.

## Small Tickets

- [x] Add a Markdown link sanity check to repo-maintenance validation.
- [ ] Normalize the existing Swift sources against the checked-in SwiftFormat profile; the initial lint audit found formatting drift while SwiftLint remained clean.
- [ ] Decide whether the private repository should adopt an explicit proprietary license file.

## Backlog Candidates

- [ ] Continue related media-framework, daemon, and service targets discovered during the MediaRemote pass.
- [ ] Expand Messages and Phone research from the existing ownership and surface maps.
- [ ] Expand UserNotifications and Notification Center accessibility research from the current read-only baseline.
- [ ] Continue `WallpaperAgent` and debug XPC research on its dedicated branch.
- [ ] Explore other macOS and iOS private frameworks that can inform local educational tools.

## History

- 2026-07-15: Created the repository foundation and seeded the MediaRemote baseline.
- 2026-07-16: Added Messages, Phone, UserNotifications, Notification Center, and WallpaperAgent research slices.
- 2026-07-17: Normalized repository documentation and installed the SwiftPM repo-maintenance profile.
