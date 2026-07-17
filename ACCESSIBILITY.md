# Accessibility

This document defines the accessibility expectations for the repository's command-line output and Markdown documentation; it does not claim conformance for the Apple software being researched.

## Table of Contents

- [Overview](#overview)
- [Standards Baseline](#standards-baseline)
- [Accessibility Architecture](#accessibility-architecture)
- [Engineering Workflow](#engineering-workflow)
- [Known Gaps](#known-gaps)
- [User Support and Reporting](#user-support-and-reporting)
- [Verification and Evidence](#verification-and-evidence)

## Overview

### Status

The repository has a documented accessibility baseline but no formal conformance audit.

### Scope

This contract covers project-owned command-line output, Markdown structure, and any future user-facing surface. It does not cover or certify macOS, private frameworks, target applications, or raw third-party runtime output.

### Accessibility Goals

Keep research usable without relying on color, pointer input, animation, or visual-only structure, and preserve user control over TCC-gated and potentially mutating experiments.

## Standards Baseline

### Target Standard

Documentation and future web or graphical surfaces should target applicable WCAG 2.2 Level AA criteria. Command-line tools use an internal baseline of plain-text readability, stable ordering, descriptive diagnostics, and keyboard-only operation.

### Conformance Language Rules

Do not make unqualified compliance, certification, or conformance claims without a scoped audit and recorded evidence. State targets, tested surfaces, gaps, and dates precisely.

### Supported Platforms and Surfaces

The current project-owned surfaces are macOS command-line tools and GitHub-flavored Markdown. Research involving the macOS Accessibility API is an experimental input surface, not proof of this repository's conformance.

## Accessibility Architecture

### Semantic Structure

Use ordered headings, descriptive link text, fenced commands, lists for real sets, and tables only when relationships benefit from them. Do not encode meaning through indentation or typography alone.

### Input and Keyboard Model

Current tools are invoked from the keyboard and must not require pointer input. Future interactive tools must document shortcuts and preserve standard platform input behavior.

### Focus Management

There is no project-owned graphical focus model today. Any future UI must provide predictable focus order, visible focus, and recovery after sheets, dialogs, or asynchronous updates.

### Naming and Announcements

CLI labels, warnings, errors, and state changes must be descriptive and identify the affected target or operation. Future UI controls and dynamic status must expose meaningful accessible names and announcements.

### Color, Contrast, and Motion

CLI and documentation meaning must not depend on color. Any future UI must provide sufficient contrast, support Reduce Motion, and avoid unnecessary flashing or animation.

### Zoom, Reflow, and Responsive Behavior

Keep CLI output readable as plain text without fixed-width layout assumptions beyond code blocks. Documentation should remain understandable under browser zoom and narrow layouts.

### Media, Captions, and Alternatives

The repository currently ships no project-owned audio or video documentation. Any future media used to explain research must include an equivalent transcript or captioned alternative.

## Engineering Workflow

### Design and Implementation Rules

Prefer semantic Markdown and plain text, descriptive actions and errors, deterministic output, and explicit consent before TCC prompts or state mutation. Keep research probes non-interactive unless interaction is essential and documented.

### Automated Testing

Swift Testing covers reusable helper behavior, but there is no dedicated automated accessibility test suite for the current CLI and Markdown surfaces.

### Manual Testing

For accessibility-relevant changes, inspect heading order, link meaning, non-color communication, terminal readability, and whether the documented command can be completed from the keyboard.

### Assistive Technology Coverage

No recurring VoiceOver or other assistive-technology test matrix is currently recorded. Add scoped evidence before claiming support for a specific assistive technology.

### Definition of Done

An accessibility-relevant change is ready when the affected surface follows this baseline, its manual checks are recorded, new gaps are listed here or in the roadmap, and no unsupported conformance claim is introduced.

## Known Gaps

### Current Exceptions

- No formal WCAG audit has been completed.
- No recurring VoiceOver verification matrix exists.
- Raw framework, daemon, and unified-log output may contain inaccessible formatting outside project control.

### Planned Remediation

Track concrete, issue-sized accessibility work in [`ROADMAP.md`](./ROADMAP.md) when a project-owned surface needs remediation. Add a dedicated test matrix if a graphical or interactive product surface is introduced.

### Ownership

Maintainers changing a project-owned user-facing surface are responsible for updating this document and recording the evidence for their change.

## User Support and Reporting

### Feedback Path

Use a GitHub issue in this repository and identify the command, document, OS version, assistive technology when relevant, expected behavior, and observed barrier. Do not include personal notifications, messages, account data, or sensitive raw captures in a public issue.

### Triage Expectations

Treat loss of access, destructive behavior, or blocked keyboard operation as high priority. Preserve privacy by excluding personal notifications, messages, account data, and raw captures from issue reports.

## Verification and Evidence

### CI Signals

```sh
scripts/repo-maintenance/validate-all.sh
```

This checks repository structure and Swift behavior. It is supporting engineering evidence, not a conformance audit.

### Audit Cadence

Review accessibility whenever a project-owned user-facing surface changes and before making a stronger accessibility claim. No calendar-based audit cadence is currently established.

### Review History

- 2026-07-17: Established the initial CLI and Markdown accessibility baseline; no formal conformance audit was performed.
