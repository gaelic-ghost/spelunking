# Tools

Standalone helper scripts and notes live here until they deserve to become SwiftPM targets under `Sources/`.

Prefer small repeatable tools that capture evidence into `research/<Target>/` and keep polished docs under `docs/`.

`ghidra/DumpWallpaperDebugReferences.java` is a static-analysis helper for the
private WallpaperAgent debug XPC research target.

`extract-wallpaper-types-metadata.py` reads the active shared-cache reflection
metadata and prints the current Debug XPC request/response model without
loading private frameworks.

`restart-wallpaper-agent.sh` performs the verified SIP-enabled, current-user
WallpaperAgent restart and confirms that launchd supplied a replacement PID.

`xpc-wire-format` inspects the typed Swift-XPC envelope locally. Run
`swift run xpc-wire-format --wallpaper-debug` only for the read-only
`accessAllAssets(.all)` Wallpaper Debug XPC probe.
