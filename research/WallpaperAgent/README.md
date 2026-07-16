# WallpaperAgent Raw Research

This directory holds raw, machine-specific evidence for the WallpaperAgent and
its debug XPC service. The matching durable writeup is
[`docs/frameworks/WallpaperAgent/README.md`](../../docs/frameworks/WallpaperAgent/README.md).

## Capture Baseline

- Active OS: macOS 26.5.2, build 25F84
- Xcode: 27.0, build 27A5218g
- Wallpaper component build: `WallpaperMac-245.4.8`
- Agent binary: `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent`
- Shared-cache location: `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/`

## Repeatable Commands

Run from the repository root:

```zsh
launchctl print "gui/$(id -u)/com.apple.wallpaper.agent"
plutil -p /System/Library/LaunchAgents/com.apple.wallpaper.plist
codesign -dvvv --entitlements :- /System/Library/CoreServices/WallpaperAgent.app
strings -a /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent | rg -i 'WallpaperDebug|invalidateSnapshots|updateRuntimeState'
```

The private framework images are represented by stubs on the sealed system
volume. Search the active dyld shared-cache slice for their strings:

```zsh
strings -a /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05 |
  rg -C 5 'WallpaperDebugRequest|WallpaperDebugResponse|AgentXPCProtocol'

python3 tools/extract-wallpaper-types-metadata.py

tools/restart-wallpaper-agent.sh

swift run xpc-wire-format --wallpaper-debug
```

The restart helper sends `SIGTERM` to the current user's agent, then waits for
launchd to publish a replacement PID. It visibly rebuilds the wallpaper path;
do not run it while a stable desktop is required.

The `xpc-wire-format` probe sends only the `accessAllAssets(.all)` debug case
to the built-in Aerials extension. It does not request a download, removal, or
wallpaper setting change. The listener decodes the mirrored request, but the
built-in Aerials extension does not call `reply(_)`; that is a provider-level
debug-handler limitation, not an XPC decoding failure.

For function-to-string cross references in the agent binary, run the bundled
Ghidra script after importing and analysing the binary:

```zsh
/Applications/Ghidra/ghidra_12.1.2_PUBLIC/support/analyzeHeadless \
  /tmp/WallpaperAgentGhidra WallpaperAgent \
  -import /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent \
  -postScript DumpWallpaperDebugReferences.java
```

Pass `-scriptPath "$PWD/tools/ghidra"` if Ghidra does not automatically find
the repository script directory.
