# AGENTS.md

Use this file for durable repo-local guidance before changing research, documentation, Swift tooling, or maintainer workflow surfaces in this repository.

## Repository Scope

### What This File Covers

This is Gale's public Apple-platform spelunking repository for SIP-disabled, local-only experiments, educational notes, and prototype Swift tooling. Cleaned research knowledge is intentionally public; supported product releases, App Store or marketplace distribution, customer-facing deployment, and redistribution of Apple-owned or third-party material remain out of scope unless Gale explicitly opens that path.

### Where To Look First

- Read [`README.md`](./README.md) for the current repository shape and [`ROADMAP.md`](./ROADMAP.md) for planned work.
- Read the target's named directory under `docs/frameworks/` before inspecting its matching raw captures under `research/`.
- Treat `Package.swift` as the source of truth for Swift products and targets.
- Read [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the human research and review workflow.

## Working Rules

### Change Scope

- Work on one framework, service, daemon, or tightly related category at a time.
- Keep raw captures, generated headers, command transcripts, and experimental notes in the target's named directory under `research/`.
- Promote cleaned, stable documentation into the matching named directory under `docs/frameworks/`.
- Preserve existing document structure and checklists unless the requested work includes a documentation normalization pass.
- Surface any move from public research documentation into supported tool distribution or a materially broader research target before implementing it.

### Source of Truth

- Inspect the local framework, SDK, binary, headers, symbols, runtime behavior, or official documentation before summarizing.
- For Apple documentation, use the applicable Apple Dev Skill: Xcode `DocumentationSearch` first, Dash second, then checked-out source, generated DocC, canonical source repositories, release notes, or readable official web docs.
- Do not treat generic web snippets, metadata shells, or bare Apple Developer URLs as proof that documentation was read.
- Separate verified observations from inference. Label conclusions inferred from strings, symbols, generated headers, or behavior until runtime or documentation evidence confirms them.
- For OS comparisons, record both the active OS version and the SDK version or Xcode path used for evidence.

### Communication and Escalation

- Explain an evidence gap plainly when a private API has no official or local documentation, then continue from local evidence.
- Ask before widening the target, mutating media or account state, launching visible apps, running simulators, or performing disruptive service checks.
- Make architecture pivots and public-facing implications explicit before implementation.

## Commands

### Setup

```sh
swift build
```

The package has no required secrets, environment files, or external package dependencies. Individual probes may still depend on the host OS, TCC grants, private-framework availability, or SIP state documented by their target writeups.

### Validation

Run the repo-owned validation entrypoint:

```sh
scripts/repo-maintenance/validate-all.sh
```

For a Swift change, this must include serialized `swift build` and `swift test` checks. For a documentation-only change, also run a Markdown inventory or link sanity check when practical.

### Optional Project Commands

```sh
scripts/repo-maintenance/sync-shared.sh
scripts/repo-maintenance/release.sh --help
```

Use `sync-shared.sh` only for explicit repo-owned shared-sync steps. Use `release.sh` only when Gale explicitly requests release or publish choreography; this research repo does not currently publish versioned releases.

## Review and Delivery

### Review Expectations

- Keep evidence, interpretation, and open questions visibly distinct.
- Confirm commands, paths, OS versions, SDK versions, symbols, and failure modes against current evidence.
- Keep repository-facing links portable and relative.
- Update nearby documentation and tests when a tool, target, or verified conclusion changes.

### Definition of Done

Work is complete when the requested slice is coherent, raw evidence is stored under the correct target, stable findings are promoted into the target docs, relevant validation passes, and remaining uncertainty is recorded without overclaiming.

## Safety Boundaries

### Never Do

- Do not commit secrets, private tokens, personal account data, unrelated machine-local state, or ignored bulk captures.
- Redact home-directory usernames, email addresses, phone numbers, device names, personal signing identities, certificate hashes, and developer-team identifiers from captures and documentation before committing them.
- Do not imply a private API is safe for public distribution, App Store submission, or a public package without a separate explicit analysis.
- Do not perform mutating framework experiments before a read-only boundary is understood and documented.
- Do not run GUI validation, simulators, visible apps, or disruptive local service checks without approval.
- Do not hard-code `DEVELOPER_DIR`, DerivedData, build-products, or artifact paths.

### Ask Before

- Mutating media state, playback state, routes, account state, system services, or user data.
- Linking private frameworks into a new distributable surface or changing the boundary between public knowledge and redistributable artifacts.
- Adding a new queue, subsystem, storage model, dependency, or ownership boundary.
- Starting release, tag, merge, or publication choreography.

## Local Overrides

There are no more-specific `AGENTS.md` files in this repository currently. If one is added later, its closer guidance refines this root file for work in that subtree.
