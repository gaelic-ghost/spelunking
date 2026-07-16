# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

## Current Scripts

- `mediaremote-inventory.zsh`: captures live `MediaRemote.framework` dyld-cache evidence, selected/beta SDK stub symbols, support-binary linkage and entitlements, framework resources, and symbol diffs into `research/MediaRemote/captures/<timestamp>/`.
- `mediaremote-interface-capture.zsh`: builds `mr-interface-probe` and captures selected Objective-C runtime class metadata into `research/MediaRemote/experiments/interfaces/<timestamp>/`.
- `mediaremote-message-surfaces.zsh`: extracts XPC keys, request/response log templates, daemon request handlers, protobuf/message symbols, and transport helpers from an inventory capture into `research/MediaRemote/experiments/messages/<timestamp>/`.
- `mediaremote-message-id-callsites.zsh`: disassembles `MediaRemote.framework` through `dyld_info` or reuses a disassembly file, then extracts immediate message type values passed to `MRXPCConnection` send helpers and `MRCreateXPCMessage`.
