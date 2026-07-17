# Spelunking

Private Apple-platform framework and service research, durable evidence, and prototype Swift tooling.

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

Active private research repository; findings are environment-specific and not prepared for public distribution.

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

The safest starting points are the read-only commands:

```sh
swift run spelunk notifications --max-depth 6
swift run mr-now-playing-probe --all
swift run mr-now-playing-probe --observe 10 --application
swift run mr-interface-probe
swift run mr-route-probe
```

The package also contains `mr-internal-probe`, `now-playing-fixture`, and the `MRXPCTraceInterpose` dynamic library for narrower experiments. Repeatable MediaRemote capture helpers live under [`tools/`](./tools/README.md).

For each target, use:

- Named target directories under [`docs/frameworks/`](./docs/README.md) for cleaned, durable findings.
- Named target directories under `research/` for raw evidence, generated interfaces, command transcripts, and experiment notes.
- `Sources/` and `Tests/` for reusable Swift helpers and probes.

Every writeup should identify the active OS and SDK or Xcode version, distinguish verified behavior from inference, and document permissions, entitlements, sandbox, SIP, XPC, notification, or daemon boundaries that affect the result.

## Development

For research intake, local setup, validation, documentation boundaries, and review expectations, see [`CONTRIBUTING.md`](./CONTRIBUTING.md). Durable agent-facing rules live in [`AGENTS.md`](./AGENTS.md), and planned work lives in [`ROADMAP.md`](./ROADMAP.md).

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

This private research workspace does not currently publish versioned releases. Notable planning changes are recorded in [`ROADMAP.md`](./ROADMAP.md), while research findings remain attached to their target writeups and Git history.

## License

No open-source license is granted. This is a private research repository containing local observations of Apple-platform software and is not prepared for redistribution.
