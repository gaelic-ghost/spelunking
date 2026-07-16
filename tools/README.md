# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

## Current Helpers

- `extract-wallpaper-symbols.sh`: demangles relevant SDK `.tbd` exports for the Wallpaper normal XPC, Wallpaper Debug XPC, and extension bridge surfaces.
- `ghidra/DumpWallpaperDebugReferences.java`: prints WallpaperAgent function cross references for debug-service and redraw/rebuild strings after Ghidra analysis.
