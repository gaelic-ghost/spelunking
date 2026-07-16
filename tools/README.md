# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

## Current Helpers

- `extract-wallpaper-symbols.sh`: demangles relevant SDK `.tbd` exports for the Wallpaper normal XPC, Wallpaper Debug XPC, extension bridge surfaces, and `WallpaperAgent` debug receiver imports.
- `inspect-wallpaper-debug-api.sh`: demangles dyld shared-cache exports for the complete Wallpaper Debug request, response, payload, and extension handler API surface.
- `inspect-wallpaper-debug-receiver.sh`: prints focused `WallpaperAgent` receiver imports, debug strings, and x86_64 disassembly windows for the debug decode, extension lookup, dispatch, and error-response paths.
- `inspect-wallpaper-swift-metadata.sh`: parses Wallpaper Swift metadata and disassembly anchors for `ContentType`, `ViewModelRefreshReason`, assertion support types, and normal-agent redraw candidate cases.
- `inspect-wallpaper-supporting-types.sh`: prints supporting enum, store-content, and security-policy evidence for the normal-agent redraw blockers.
- `inspect-wallpaper-surfaces.sh`: prints a bounded inventory of Wallpaper launchd jobs, plug-ins, ExtensionKit providers, helper XPCs, diagnostic extensions, feature flags, logging preferences, App Intents metadata summaries, and filtered string/symbol evidence.
- `ghidra/README.md`: records the local Ghidra and Malimite setup paths needed for deeper disassembly work.
- `ghidra/DumpWallpaperDebugReferences.java`: prints WallpaperAgent string and symbol cross references for debug-service, Swift/XPC receiver, and redraw/rebuild anchors after Ghidra analysis.
