# Spelunking

Public Apple-platform framework and service research, durable evidence, and prototype Swift tooling.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Development](#development)
- [Repo Structure](#repo-structure)
- [Release Notes](#release-notes)
- [License](#license)

## Overview

### Status

Active public research repository. Findings are environment-specific, and experimental tools are not packaged as supported public products.

### What This Project Is

This repository is for focused investigations into macOS, iOS, and Apple-platform frameworks, services, daemons, private APIs, headers, symbols, and runtime behavior. Each pass studies one framework, service, subsystem, or tightly related category at a time.

### Motivation

Research should leave behind evidence and documentation that can support future local tools and projects. Raw captures remain separate from cleaned conclusions so later work can distinguish verified observations from inference.

## Quick Start

The package requires macOS 26 or later and Swift 6.2 or later. Build the research tools and run the non-mutating target index:

```sh
swift build
swift test
swift run spelunk
```

Individual probes may require a particular macOS build, private frameworks, TCC permission, or SIP-disabled conditions. Read the relevant framework writeup before running one.

## Usage

Start with the target inventory, then read the target overview linked from [`docs/README.md`](./docs/README.md):

```sh
swift run spelunk targets
```

### Command Safety

These commands are read-only in intent: they do not send playback commands, change routes, dismiss notifications, or alter account or message state. Loading private frameworks and querying system services can still fail because of OS, entitlement, TCC, sandbox, or SIP boundaries.

| Command | Purpose | Runtime Boundary | Output |
| --- | --- | --- | --- |
| `swift run spelunk targets` | List every seeded research target and its documentation paths. | None beyond building the package. | Human-readable target index. |
| `swift run spelunk notifications --max-depth 6` | Inspect the Notification Center Accessibility tree. | Requires Accessibility trust to expose the tree; captured strings may contain personal notification content. | JSON capability and tree snapshot. |
| `swift run spelunk objc-runtime ...` | Load selected framework images and inventory matching Objective-C metadata. | The requested image is loaded into the probe process; private images may reject loading or execute framework initialization. | Text or JSON metadata. |
| `swift run spelunk string-constants ...` | Resolve selected exported string constants from a framework image. | Loads the requested image; symbols may be absent or use an unsupported representation. | Text or JSON resolution results. |
| `swift run spelunk notification-observe ...` | Observe named Darwin or distributed notifications for a bounded duration. | Waits for live events; payload contents are not recorded. | Text or JSON registration and event results. |
| `swift run mr-now-playing-probe [options]` | Query MediaRemote now-playing, client, player, origin, or queue state. | Contacts private media services; some options register notifications or issue read requests. | Human-readable runtime observations. |
| `swift run mr-interface-probe` | Inspect selected MediaRemote Objective-C runtime interfaces. | Loads the private framework into the probe process. | Human-readable class and method inventory. |
| `swift run mr-route-probe [options]` | Query endpoints, routes, contexts, and output-device metadata. | Contacts private routing services; default invocation does not change the active route. | Human-readable route observations. |

Common read-only examples:

```sh
swift run spelunk notifications --max-depth 6
swift run mr-now-playing-probe --all
swift run mr-now-playing-probe --observe 10 --application
swift run mr-interface-probe
swift run mr-route-probe
```

The package also contains `mr-internal-probe`, `now-playing-fixture`, and the `MRXPCTraceInterpose` dynamic library for narrower experiments. These are not general starting points: read the [MediaRemote experiment documentation](./docs/frameworks/MediaRemote/experiments.md) before using them. Repeatable MediaRemote capture helpers and their individual purposes live under [`tools/`](./tools/README.md).

For each target, use:

- Named target directories under [`docs/frameworks/`](./docs/README.md) for cleaned, durable findings.
- Named target directories under `research/` for raw evidence, generated interfaces, command transcripts, and experiment notes.
- `Sources/` and `Tests/` for reusable Swift helpers and probes.

Every writeup should identify the active OS and SDK or Xcode version, distinguish verified behavior from inference, and document permissions, entitlements, sandbox, SIP, XPC, notification, or daemon boundaries that affect the result.

## Development

For research intake, local setup, validation, documentation boundaries, and review expectations, see [`CONTRIBUTING.md`](./CONTRIBUTING.md). Durable agent-facing rules live in [`AGENTS.md`](./AGENTS.md), and planned work lives in [`ROADMAP.md`](./ROADMAP.md).

Automated tests cover deterministic, reusable helper behavior. Environment-specific private-framework calls, daemon responses, permissions, and OS behavior require a documented runtime observation; a passing unit test or build does not prove that those live surfaces are available or authorized on another machine.

## Repo Structure

```text
.
├── Sources/                 Swift libraries, executables, and probe targets
├── Tests/                   Swift Testing coverage for reusable helpers
├── docs/frameworks/         Cleaned framework and subsystem writeups
├── research/                Raw captures and target-specific evidence
├── scripts/repo-maintenance Local validation, sync, and release entrypoints
└── tools/                   Standalone evidence-capture helpers
```

## Release Notes

This research workspace does not currently publish versioned releases. Notable planning changes are recorded in [`ROADMAP.md`](./ROADMAP.md), while research findings remain attached to their target writeups and Git history.

## License

A formal reuse license has not been selected yet. The repository is public because research knowledge should be available to learn from, verify, and extend; public visibility does not grant rights to redistribute Apple-owned code, private data, or third-party material captured during research.
