# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

## Current Scripts

- `mediaremote-inventory.zsh`: captures live `MediaRemote.framework` dyld-cache evidence, selected/beta SDK stub symbols, support-binary linkage and entitlements, framework resources, and symbol diffs into `research/MediaRemote/captures/<timestamp>/`.
