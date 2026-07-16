# WallpaperAgent Raw Research

This directory holds raw, machine-specific evidence for `WallpaperAgent` and
the Wallpaper Debug XPC service. Promote cleaned conclusions into
`docs/frameworks/WallpaperAgent/README.md`.

## Capture Baseline

- Active OS: macOS 26.5.2, build 25F84
- Selected toolchain: Xcode beta with Swift 6.4
- SIP state during capture: disabled
- Target access model: ordinary userland with SIP enabled
- Wallpaper component build observed in private frameworks:
  `WallpaperMac-245.4.8`
- Agent binary:
  `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent`
- LaunchAgent:
  `/System/Library/LaunchAgents/com.apple.wallpaper.plist`
- Shared-cache directory:
  `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/`

## Baseline Commands

Run from the repository root.

```zsh
sw_vers
xcode-select -p
xcrun swift --version
csrutil status
```

```zsh
id -u
pgrep -af WallpaperAgent
ps -axo pid,ppid,uid,user,comm,args | rg 'WallpaperAgent|Wallpaper'
```

```zsh
plutil -p /System/Library/LaunchAgents/com.apple.wallpaper.plist
launchctl print "gui/$(id -u)" | rg -i 'wallpaper' -C 3
launchctl print "gui/$(id -u)/com.apple.wallpaper.agent"
```

Do not use `launchctl kickstart` for the reset path. It is intentionally not a
candidate in this research lane.

## Binary and Signing Inventory

```zsh
codesign -dvvv --entitlements :- /System/Library/CoreServices/WallpaperAgent.app
otool -L /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent
otool -l /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent |
  rg '__swift5|__TEXT|__DATA'
```

```zsh
strings -a /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent |
  rg -i 'WallpaperDebug|debug\.service|debug\.listener|XPC|snapshotAllSpaces|diagnosticState|assertion|invalidateSnapshots|updateRuntimeState|handleGenerationChange|generation|reload|redraw|refresh|wallpaper\.skip'
```

Key strings captured from the agent:

- `WallpaperDebugServer`
- `WallpaperDebugRequestHandler`
- `com.apple.wallpaper.debug.listener`
- `snapshotAllSpaces(sender:)`
- `diagnosticState(sender:)`
- `setAssertions(_:sender:)`
- `releaseAssertion(id:sender:)`
- `takeAssertion(id:value:sender:)`
- `invalidateSnapshots`
- `handleGenerationChange`
- `updateRuntimeState`
- `Request reload due to wallpaper runtime change`
- `clientGenerationID incremented`
- `com.apple.wallpaper.skip`

## Private Framework Evidence

The sealed system volume may expose broken symlinks or stubs for the private
framework binaries. The SDK `.tbd` files and dyld shared cache are more useful
for this target.

```zsh
find /System/Library/PrivateFrameworks/Wallpaper*.framework -maxdepth 4 -type f |
  sort
```

```zsh
find /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld \
  -maxdepth 1 -type f -name 'dyld_shared_cache_arm64e*' |
  sort
```

```zsh
find "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks" \
  -path '*Wallpaper.framework*' -o \
  -path '*WallpaperTypes.framework*' -o \
  -path '*WallpaperExtensionKit.framework*'
```

## Demangling `.tbd` Symbols

Normal agent protocol:

```zsh
rg -o '_\$s9Wallpaper[0-9A-Za-z_]+' \
  "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks/Wallpaper.framework/Versions/A/Wallpaper.tbd" |
  cut -d: -f2- |
  rg 'AgentXPCProtocol|AgentXPCMessage|AgentXPCSecurityPolicy|ContentType|ViewModelRefreshReason|ensureViewModelIsUpToDate|diagnosticState|snapshotAllSpaces|skipShuffledContent|canSkipShuffledContent|Assertion' |
  sort -u |
  xcrun swift-demangle
```

Debug request and response types:

```zsh
rg -o '_\$s14WallpaperTypes[0-9A-Za-z_]+' \
  "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks/WallpaperTypes.framework/Versions/A/WallpaperTypes.tbd" |
  cut -d: -f2- |
  rg 'WallpaperDebug(Request|Response|RequestMessage)|DebugResponse|DebugRequest|AssetDownloadState|AssetList' |
  sort -u |
  xcrun swift-demangle
```

Extension bridge:

```zsh
rg -o '_\$s21WallpaperExtensionKit[0-9A-Za-z_]+' \
  "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit.tbd" |
  cut -d: -f2- |
  rg 'handleDebugRequest|DebugRequest|DebugResponse|invalidateSnapshots|skipShuffled|HostProxy|WallpaperProxy|ExportedObject|XPC' |
  sort -u |
  xcrun swift-demangle
```

## Shared-Cache String Windows

```zsh
strings -a /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05 |
  rg -A 80 -B 20 'MacintoshWallpaperChoiceConfiguration|WallpaperDebugAssetType|WallpaperDebugRequest|WallpaperDebugResponse|WallpaperAssetList|WallpaperAssetDownloadState|WallpaperDebugRequestMessage'
```

```zsh
strings -a /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05 |
  rg -A 80 -B 20 'AgentXPCProtocol|AgentXPCMessage|ensureViewModelIsUpToDate|snapshotAllSpaces|diagnosticState|WallpaperXPCCodable'
```

## Extension Inventory

```zsh
find /System/Library/ExtensionKit/Extensions \
  -maxdepth 3 -name Info.plist -path '*Wallpaper*' \
  -print -exec plutil -p {} \; |
  rg -i 'Wallpaper|NSExtension|EXAppExtension|debug|mach|service|identifier' -C 2
```

Observed wallpaper extension identifiers:

- `com.apple.wallpaper.extension.aerials`
- `com.apple.wallpaper.extension.dynamic`
- `com.apple.wallpaper.extension.gradient`
- `com.apple.wallpaper.extension.image`
- `com.apple.wallpaper.extension.legacy`
- `com.apple.wallpaper.extension.macintosh`
- `com.apple.wallpaper.extension.monterey`
- `com.apple.wallpaper.extension.sequoia`
- `com.apple.wallpaper.extension.sonoma`
- `com.apple.wallpaper.extension.ventura`
- `com.apple.NeptuneOneExtension`

## Logs

```zsh
log show --last 24h --style compact \
  --predicate 'process == "WallpaperAgent" AND (eventMessage CONTAINS[c] "debug" OR eventMessage CONTAINS[c] "Failed to Decode" OR eventMessage CONTAINS[c] "Accepted XPC" OR eventMessage CONTAINS[c] "reload" OR eventMessage CONTAINS[c] "generation")'
```

Prior ordinary-client probes reached the normal service and logged
`Failed to Decode XPC Message: NSCocoaErrorDomain (4865)`. Treat this as a
private envelope or metadata mismatch until receiver-side evidence proves a
different cause.

## Repository Helper

Non-mutating commands:

```zsh
swift run spelunk wallpaper-agent inventory
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper.debug.service
swift run spelunk wallpaper-agent redraw-static-plan
swift run spelunk wallpaper-agent signal-plan --signal TERM
```

Mutating commands require an explicit execute flag:

```zsh
swift run spelunk wallpaper-agent redraw-static --execute
swift run spelunk wallpaper-agent signal --execute --signal TERM
```

Observed in this branch:

- `inventory`: confirmed current-user `WallpaperAgent` and all expected Mach
  services.
- `xpc-ping-empty com.apple.wallpaper`: returned an empty dictionary reply.
- `xpc-ping-empty com.apple.wallpaper.debug.service`: failed with
  `Underlying connection interrupted`.
- `redraw-static-plan`: reported the current desktop image URL without
  changing it.
- `signal-plan --signal TERM`: reported the current target pid without sending
  the signal.

## Ghidra Cross References

Use the repository script:

```zsh
/Applications/Ghidra/ghidra_12.1.2_PUBLIC/support/analyzeHeadless \
  /tmp/WallpaperAgentGhidra WallpaperAgent \
  -import /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent \
  -scriptPath "$PWD/tools/ghidra" \
  -postScript DumpWallpaperDebugReferences.java \
  -analysisTimeoutPerFile 180 \
  -deleteProject
```

The script prints string references for debug server, debug listener, normal
diagnostic methods, and internal redraw/rebuild strings.

Observed Ghidra notes from this branch:

- Full auto-analysis timed out at 120 seconds, but the Java post-script still
  ran on the partially analysed program.
- The script found `WallpaperDebugServer` at `10016dcb0` with a data reference
  at `10017c484`.
- The script found `WallpaperDebugRequestHandler` at `10016e8d0` with a data
  reference at `10017c98c`.
- `snapshotAllSpaces(sender:)` referenced data at `10000b5da`.
- `diagnosticState(sender:)` referenced data at `10000a710`.
- `updateRuntimeState` referenced data at `1000dfa15` and `1001896f8`.
- Runtime/redraw strings were found for `invalidateSnapshots`,
  `handleGenerationChange`, `snapshotAllSpaces`, `updateRuntimeState`, and
  `Request reload due to wallpaper runtime change`.
- Demangled `AgentXPCProtocol` requirement strings for `diagnosticState`,
  `snapshotAllSpaces`, and `ensureViewModelIsUpToDate` were present in the
  imported agent image.

## Controlled Experiments To Capture

Do these only when visible desktop interruption is acceptable:

1. Same-user `SIGTERM` restart probe:
   - record pid and `launchctl print` before
   - run `swift run spelunk wallpaper-agent signal --execute --signal TERM`
   - record pid and `launchctl print` after
   - capture logs around relaunch and redraw
2. Public AppKit same-image reapply:
   - record current image URL and options for every `NSScreen`
   - run `swift run spelunk wallpaper-agent redraw-static --execute`
   - capture logs and visual result
3. Private `ensureViewModelIsUpToDate` probe:
   - only after the private Swift/XPC envelope is solved
   - test safe refresh reasons before any mutating messages
4. Debug XPC asset-list probe:
   - only after `WallpaperDebugRequestMessage` can be encoded with the correct
     metadata identity
   - prefer `accessAllAssets(.downloaded)` before any download or removal
     request
