# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

## Current Helpers

- `extract-wallpaper-symbols.sh`: demangles relevant SDK `.tbd` exports for the Wallpaper normal XPC, Wallpaper Debug XPC, extension bridge surfaces, and `WallpaperAgent` debug receiver imports.
- `inspect-wallpaper-surfaces.sh`: prints a bounded inventory of Wallpaper launchd jobs, plug-ins, ExtensionKit providers, helper XPCs, diagnostic extensions, feature flags, logging preferences, and filtered string/symbol evidence.
- `ghidra/DumpWallpaperDebugReferences.java`: prints WallpaperAgent string and symbol cross references for debug-service, Swift/XPC receiver, and redraw/rebuild anchors after Ghidra analysis.
