# AGENTS.md

## Project Scope

This is Gale's private Apple-platform spelunking repository for SIP-disabled, local-only research, educational notes, and prototype Swift tooling.

Default to source-of-truth-first work: inspect the local framework, SDK, binary, headers, symbols, runtime behavior, or official documentation before summarizing. Keep public-release, App Store, marketplace, customer-facing, or redistributed use out of scope unless Gale explicitly opens that path.

## Research Workflow

- Work on one framework, service, daemon, or tightly related category at a time.
- Keep raw captures, generated headers, command transcripts, and experimental notes under `research/<Target>/`.
- Promote cleaned, stable documentation into `docs/frameworks/<Target>/`.
- Separate verified observations from inference. Label anything inferred from strings, symbols, generated headers, or behavior as inference until a runtime or documentation source confirms it.
- For OS comparisons, record both the active OS version and the SDK version or Xcode path used for evidence.
- Prefer repeatable commands and small helper tools over one-off manual notes when the result will matter again.
- Do not commit secrets, private tokens, personal account data, or unrelated machine-local state.

## Apple Documentation Gate

- For Apple, Swift, SwiftPM, and Xcode work, use the relevant Apple Dev Skill before implementation or architectural advice.
- For official docs lookup, use `explore-apple-swift-docs`: Xcode MCP `DocumentationSearch` first, Dash.app MCP second, Dash HTTP only when needed, then checked-out source, generated DocC, GitHub/source repositories, release notes, or readable official web docs.
- Do not treat generic web snippets, metadata shells, or bare Apple Developer URLs as proof that documentation was read.
- If no official or local documentation is available for a private API, say that plainly and continue from local evidence.

## Swift Package Workflow

- Treat `Package.swift` as the source of truth for Swift tools in this repo.
- Use `bootstrap-swift-package` only when creating a fresh Swift package from scratch.
- Use `sync-swift-package-guidance` when this repo's SwiftPM guidance needs to be refreshed or merged forward.
- Use `swift-package-build-run-workflow` for manifest, dependency, plugin, resource, build, and run work.
- Use `swift-package-testing-workflow` for Swift Testing, XCTest holdouts, fixtures, and package test diagnosis.
- Use `swift build` and `swift test` as default validation after package-level changes.
- Prefer Swift Testing for new tests.
- Keep Swift code in Swift 6 language mode.
- Choose project-owned Swift names with the `SPK` prefix unless a narrower target-specific prefix is introduced and documented.

## Private Framework Handling

- Keep private-framework experiments local-first and clearly labeled.
- Do not imply a private API is safe for public distribution, App Store submission, or a public package unless Gale explicitly asks for that separate analysis.
- When linking private frameworks, loading symbols dynamically, using generated headers, or relying on SIP-disabled behavior, document the exact boundary and observed failure mode.
- Prefer read-only experiments before mutating media state, playback state, routes, account state, or system services.

## Documentation Standards

- Preserve existing document structure and checklists unless Gale asks to reorganize them.
- Use portable relative links in repository docs.
- Each framework writeup should include: scope, environment, evidence inventory, type and symbol notes, interesting APIs, hooks or notifications, permissions and entitlements, experiments, open questions, and references.
- Keep command examples reproducible and explicit about the working directory, SDK, target OS, and toolchain when those details affect output.

## Validation

- For docs-only changes, run a quick file inventory or Markdown sanity check when practical.
- For Swift changes, run `swift build` and `swift test` unless the change is explicitly documentation-only or the toolchain is blocked.
- Do not run GUI validation, simulators, visible apps, or disruptive local service checks without Gale's approval.
