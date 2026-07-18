# Contributing to Spelunking

Use this guide to keep public Apple-platform research understandable, reproducible, and safe to revisit.

## Table of Contents

- [Overview](#overview)
- [Contribution Workflow](#contribution-workflow)
- [Local Setup](#local-setup)
- [Development Expectations](#development-expectations)
- [Pull Request Expectations](#pull-request-expectations)
- [Communication](#communication)
- [License and Contribution Terms](#license-and-contribution-terms)

## Overview

### Who This Guide Is For

This guide serves contributors and agents preparing documentation, evidence captures, Swift probes, or maintainer-tooling changes in this public repository.

### Before You Start

Read [`AGENTS.md`](./AGENTS.md), the relevant target index under `docs/frameworks/`, and the target's raw-evidence README under `research/`. Check [`ROADMAP.md`](./ROADMAP.md) and open GitHub issues before starting work that may overlap another branch.

## Contribution Workflow

### Choosing Work

Choose one framework, service, daemon, or tightly related category. Define the evidence question and whether the experiment is read-only before collecting data. Use a focused feature or research branch and keep unrelated targets separate.

### Making Changes

1. Record the host OS and relevant SDK or Xcode version.
2. Store repeatable commands, raw captures, and generated interfaces under the target's named directory in `research/`.
3. Put reusable Swift code under `Sources/` with Swift Testing coverage under `Tests/` where practical.
4. Promote only cleaned, stable conclusions into the target's matching named directory under `docs/frameworks/`.
5. Label inference explicitly and link conclusions to the evidence that supports them.

Do not commit ignored bulk captures, personal account data, secrets, or unrelated machine state. Before committing a capture, redact home-directory usernames, email addresses, phone numbers, device names, personal signing identities, certificate hashes, and developer-team identifiers while preserving the technical result.

### Asking For Review

A change is ready when the diff is scoped, commands are reproducible, environment details are present, claims match the evidence, links are portable, and the relevant validation passes. Call out private API, entitlement, TCC, sandbox, SIP, XPC, daemon, and side-effect boundaries in the review summary.

## Local Setup

### Runtime Config

There are no required environment files, secrets, external packages, or local services. Use the selected Xcode command-line toolchain without hard-coded `DEVELOPER_DIR` or build-output paths.

Some target-specific experiments require TCC permission, private-framework availability, a specific OS build, or SIP-disabled conditions. Document those requirements in the target writeup; never encode personal machine paths or credentials into the repo.

### Runtime Behavior

Build and test the package first:

```sh
swift build
swift test
swift run spelunk
```

Start with a read-only probe. A successful build does not prove that a private runtime call is available or authorized, so record the observed process output and failure mode separately.

## Development Expectations

### Naming Conventions

- Prefix project-owned Swift types with `SPK` unless a narrower target prefix is documented.
- Use matching named directories under `docs/frameworks/` and `research/` with the target's canonical Apple name.
- Name captures with enough OS, SDK, date, or experiment context to distinguish their environment.
- Keep shared support code in dedicated types or extensions rather than hiding it inside an unrelated probe entrypoint.

### Accessibility Expectations

Follow [`ACCESSIBILITY.md`](./ACCESSIBILITY.md). The repository currently ships command-line tools and Markdown, not a graphical product, so relevant obligations are readable output, semantic document structure, non-color-only meaning, and preserving user control over TCC-gated or mutating experiments.

When researching Apple's Accessibility API, distinguish the API being observed from claims about this repository's own accessibility conformance.

### Verification

Run the repo-owned validation entrypoint, which includes the package build and tests:

```sh
scripts/repo-maintenance/validate-all.sh
```

For documentation-only work, also inspect the changed Markdown structure and links. Do not run visible apps, simulators, GUI automation, or disruptive service checks without approval.

Automated validation and runtime evidence prove different things:

- Swift tests should cover deterministic parsing, target metadata, formatting, and reusable helper behavior.
- Builds prove that the checked-in source compiles against the selected toolchain.
- Runtime captures prove the observed private-framework, daemon, notification, Accessibility, permission, or entitlement behavior only for the recorded environment.

Do not convert an environment-specific observation into a unit-test claim, and do not describe a passing build or test as proof that a private runtime surface is present, permitted, or stable across OS versions.

## Pull Request Expectations

Summarize the target, evidence gathered, conclusions promoted, commands run, environment used, and any remaining inference or blocked runtime proof. Keep reviewable raw captures separate from generated or ignored bulk output.

## Communication

Surface uncertain interpretation, risky mutation, public-facing implications, and scope expansion before they become part of the implementation. If a new queue, subsystem, storage model, dependency, or ownership boundary becomes necessary, stop and make that architecture decision explicit.

## License and Contribution Terms

A formal reuse license has not been selected yet. Contributions should advance the public research record without adding Apple-owned code, personal data, secrets, or third-party material that the repository cannot lawfully redistribute.
