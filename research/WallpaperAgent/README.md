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

Use the bundled helper for the current extraction set:

```zsh
tools/extract-wallpaper-symbols.sh
```

The helper intentionally filters after demangling. Some Swift symbols compress
type names in their mangled form, so filtering before `swift-demangle` can miss
the `WallpaperTypes` debug protocol.

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

The private modules are not importable directly from this SDK:

```zsh
xcrun swift -I "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks" \
  -F "$(xcrun --sdk macosx --show-sdk-path)/System/Library/PrivateFrameworks" \
  -e 'import Wallpaper'
```

Observed result: `error: no such module 'Wallpaper'`. `WallpaperTypes` is the
same. Treat SDK `.tbd` exports and shared-cache strings as the current
repeatable source, not Swift source import.

Additional recovered payloads from the fixed extractor:

- `WallpaperChoiceRequest` cases: `imageFolder(URL)`,
  `screenSaver(ScreenSaverParameters)`, `photoLibraryAsset(String)`,
  `photoLibraryPerson(String)`, `photoLibraryCollection(String)`,
  `color(CGColorRef)`, and `image(URL)`.
- `WallpaperChoiceRequest.ScreenSaverParameters` has `module: URL`.
- `WallpaperChoiceRequestAdditionResult` cases: `choice(WallpaperChoice.ID)`
  and `group(WallpaperSettingsGroup.ID, WallpaperChoice.ID)`.
- `WallpaperSettingsViewModels` has optional `desktop` and `screenSaver`
  view models.
- `WallpaperSettingsViewModel.RefreshPolicy` cases: `default` and
  `discretionary`.
- `WallpaperSettingsViewModel.ContentType` is an `Int` raw-value enum, but its
  cases were not recovered from the SDK stub.

`tools/extract-wallpaper-symbols.sh` also extracts the agent's receiver-side
debug imports from the live `WallpaperAgent` binary. Important imports:

- `WallpaperTypes.WallpaperDebugService.getter`
- `WallpaperTypes.WallpaperDebugRequestMessage.extensionIdentifier`
- `WallpaperTypes.WallpaperDebugRequestMessage.request`
- `WallpaperTypes.WallpaperDebugRequestMessage : Decodable`
- `WallpaperTypes.WallpaperDebugRequest` metadata
- `WallpaperTypes.WallpaperDebugResponse : Encodable`
- `WallpaperExtensionKit.WallpaperExtensionProxy.handleDebugRequest`
- `XPC.XPCListener`
- `XPC.XPCListener.IncomingSessionRequest.accept`
- `XPC.XPCReceivedMessage.decode(as:)`
- `XPC.XPCReceivedMessage.handoffReply(to:_:)`
- `XPC.XPCReceivedMessage.reply(_:)`

## Supporting Type and Security Evidence

Use the repository helper for a repeatable static inventory:

```zsh
tools/inspect-wallpaper-supporting-types.sh
```

The helper combines SDK stub symbols, `WallpaperAgent` strings, and dyld-cache
string windows for the supporting types that are currently blocking a real
normal-agent redraw message.

Observed static facts:

- `Wallpaper.ContentType` exports `Codable`, `CaseIterable`,
  `CustomStringConvertible`, `allCases`, `description`, `init(from:)`, and
  `encode(to:)`.
- `Wallpaper.AssertionValue` exports `Codable`, `Hashable`, `Equatable`,
  `CustomStringConvertible`, `description`, `init(from:)`, and `encode(to:)`.
- `Wallpaper.AssertionPresentationMode` exports `RawRepresentable`,
  `Codable`, `init(rawValue:)`, and `rawValue` with raw type `String`.
- No `Wallpaper.ContentType` cases, `AssertionValue` cases, or
  `AssertionPresentationMode` raw strings were recovered from the current SDK
  stubs, agent import symbols, or dyld-cache string windows.
- `WallpaperTypes.WallpaperSettingsViewModel.ContentType` is a separate
  `Int` raw-value enum with `init(rawValue:)` and `rawValue`; its cases were
  not recovered.
- `WallpaperAgent` strings include `WallpaperStoreContentType`,
  `running-assertions`, `extension`, `screenSaver`, `inProcess`,
  `ContentDescriptor type=inprocess`, `ContentDescriptor type=screensaver`,
  and `ContentDescriptor type=extension`. Treat these as agent/store/provider
  vocabulary unless a later runtime or metadata pass ties them to
  `Wallpaper.ContentType`.
- Agent strings also include `Unknown XPC Sender`, `Remote process %{public}s
  attempting to connect`, `Added Client Assertion: %{public}s`, and
  `Removed Client Assertion: %{public}s`.
- Dyld-cache strings name `AllowAllXPCSecurityPolicy`,
  `EntitlementXPCSecurityPolicy`, `AgentXPCSecurityPolicy`, and
  `WallpaperXPCConnectionSecurityPolicy`.
- `Wallpaper.AgentXPCSecurityPolicy` exports `allow(process:)` and
  `checkAccess(message:for:)`, confirming that normal-agent messages need both
  valid Swift/XPC encoding and per-message access evaluation.

`swift-inspect --help` was checked as a possible metadata route. It is a live
runtime process-inspection tool, not a static extractor, so it was not used
against `WallpaperAgent` in this pass.

## Runtime Debug XPC Probe

The first typed probe used local mirrored types in the `SpelunkingKit` module
and modeled `WallpaperDebugAssetType` as a raw-string enum. It reached the
debug service, but the receiver did not enter the reply path:

```zsh
.build/debug/spelunk wallpaper-agent debug-xpc-probe
```

Observed result:

```text
machService: com.apple.wallpaper.debug.service
extensionIdentifier: com.apple.wallpaper.extension.aerials
request: accessAllAssets(downloaded)
succeeded: false
error: Debug XPC replied, but the response could not be decoded as SPKWallpaperDebugResponse: Receiver didn't call reply(_) or handoffReply(_) before returning from the message handler for this sync IPC message
```

This matched the static receiver trace: decode failure returns before
`handoffReply`.

The working probe moved the mirrored debug wire types into a local SwiftPM
target named `WallpaperTypes` and changed `WallpaperDebugAssetType` to a
normal synthesized `Codable` enum, matching the exported symbols.

```zsh
swift build
.build/debug/spelunk wallpaper-agent debug-xpc-probe
```

Observed result on the current boot:

```text
machService: com.apple.wallpaper.debug.service
extensionIdentifier: com.apple.wallpaper.extension.aerials
request: accessAllAssets(downloaded)
succeeded: true
decodedResponse: allAssets(count: 2)
assets:
  id=4C108785-A7BA-422E-9C79-B0129F1D5550 downloaded=true name=Tahoe Day
  id=D8C8FC8B-9D11-4803-944F-DF284B35FE58 downloaded=true name=Mac Purple
```

Invalid extension probe:

```zsh
.build/debug/spelunk wallpaper-agent debug-xpc-probe \
  --extension com.apple.wallpaper.extension.not-real
```

Observed result:

```text
succeeded: true
decodedResponse: error(No valid extension)
```

Download-state probe for a known downloaded asset:

```zsh
.build/debug/spelunk wallpaper-agent debug-xpc-probe \
  --extension com.apple.wallpaper.extension.aerials \
  --request download-state \
  --asset-id 4C108785-A7BA-422E-9C79-B0129F1D5550
```

Observed result:

```text
succeeded: true
decodedResponse: downloadState(assetID: 4C108785-A7BA-422E-9C79-B0129F1D5550, progress: 1.0, isDownloaded: true)
```

SIP evidence from the same session:

```zsh
csrutil status
```

Observed result:

```text
System Integrity Protection status: disabled.
```

Therefore this proves the ordinary-user debug XPC wire shape and dispatch on
the current boot, but it does not satisfy the SIP-enabled proof requirement.

The SIP validation report command bundles the non-mutating proof set for a
future SIP-enabled boot:

```zsh
.build/debug/spelunk wallpaper-agent sip-validation-report
```

Observed result on the current boot:

```text
SIP validation report
sipStatus: System Integrity Protection status: disabled.
sipEnabled: false
...
debugXPCReadProbe:
succeeded: true
decodedResponse: allAssets(count: 2)
...
staticRedrawPlan:
execute: false
screen: Built-in Retina Display
  imageURL: file:///System/Library/CoreServices/DefaultDesktop.heic
  reapplied: false

redrawProbePlan:
execute: false
screen: Built-in Retina Display
  beforeImageURL: file:///System/Library/CoreServices/DefaultDesktop.heic
  afterImageURL: <not collected>
  beforeOptionKeys:
  afterOptionKeys: <not collected>
  reapplied: false
  preservedImageURL: <not executed>
...
signalPlan:
execute: false
signal: 15
targetedPIDs: 67606

restartProbePlan:
execute: false
signal: 15
waitSeconds: 5.0
targetedPIDs: 67606
beforePIDs: 67606
afterPIDs: <not collected>
respawnObserved: <not executed>

sipProofClaim: not eligible because SIP is not enabled for this boot.
```

On a SIP-enabled boot, this same command is the first validation gate. If it
prints `sipEnabled: true` and the debug XPC read probe succeeds, it proves
ordinary-user debug XPC reachability under SIP for the read/query surface. It
still does not prove restart or redraw mutation.

Recent log snapshot:

```zsh
.build/debug/spelunk wallpaper-agent log-snapshot --last 10m --limit 12
```

Observed result:

```text
lastInterval: 10m
limit: 12
truncated: true
predicate: process == "WallpaperAgent" AND (...)
lines:
  2026-07-16 04:48:29.571 Df WallpaperAgent[...] activating connection: ... name=com.apple.wallpaper.debug.service.peer[...]
  2026-07-16 04:48:29.571 Df WallpaperAgent[...] BEGIN - [com.apple.wallpaper.extension.aerials] handleDebugRequest
  2026-07-16 04:48:29.586 Df WallpaperAgent[...] END - [com.apple.wallpaper.extension.aerials] handleDebugRequest
  2026-07-16 04:48:29.586 Df WallpaperAgent[...] invalidated because the client process ... cancelled the connection or exited
  2026-07-16 04:52:36.312 Df WallpaperAgent[...] activating connection: ... name=com.apple.wallpaper.debug.service.peer[...]
  2026-07-16 04:52:36.312 Df WallpaperAgent[...] BEGIN - [com.apple.wallpaper.extension.aerials] handleDebugRequest
  2026-07-16 04:52:36.327 Df WallpaperAgent[...] END - [com.apple.wallpaper.extension.aerials] handleDebugRequest
  2026-07-16 04:52:36.327 Df WallpaperAgent[...] invalidated because the client process ... cancelled the connection or exited
```

The log snapshot corroborates the runtime debug XPC result: the request reaches
`WallpaperAgent`, crosses into the extension proxy, and returns from
`handleDebugRequest`.

For focused receiver disassembly windows, use:

```zsh
tools/inspect-wallpaper-debug-receiver.sh
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

## Adjacent Userland Surface Inventory

Use the repository helper for a bounded repeatable inventory:

```zsh
tools/inspect-wallpaper-surfaces.sh
```

Manual commands used for the current pass:

```zsh
plutil -p /System/Library/LaunchDaemons/com.apple.wallpaper.export.plist
plutil -p /System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/XPCServices/WallpaperHelper.xpc/Contents/Info.plist
plutil -p /System/Library/PrivateFrameworks/DiagnosticExtensions.framework/PlugIns/WallpaperDiagnosticExtension.appex/Contents/Info.plist
```

```zsh
for plist in /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/*.appex/Contents/Info.plist; do
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist"
  /usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c 'Print :EXAppExtensionAttributes:EXExtensionPointIdentifier' "$plist" 2>/dev/null || true
done
```

```zsh
find /System/Library/ExtensionKit/Extensions \
  -maxdepth 3 \
  -path '*Wallpaper*.appex/Contents/Info.plist' \
  -print |
  sort |
  while IFS= read -r plist; do
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c 'Print :EXAppExtensionAttributes:EXExtensionPointIdentifier' "$plist" 2>/dev/null || true
done
```

```zsh
plutil -p /System/Library/FeatureFlags/Domain/Wallpaper.plist
plutil -p /System/Library/FeatureFlags/Domain/NeptuneWallpaper.plist
plutil -p /System/Library/Preferences/Logging/Subsystems/com.apple.wallpaper.plist
```

```zsh
LC_ALL=C strings -a /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperControlsExtension.appex/Contents/MacOS/WallpaperControlsExtension |
  rg -i 'wallpaper|skip|reload|refresh|redraw|xpc|intent|control|widget|notification|distributed|darwin|defaults|UserDefaults|desktop|screen'
```

```zsh
LC_ALL=C strings -a /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperIntents.appex/Contents/MacOS/WallpaperIntents |
  rg -i 'wallpaper|skip|reload|refresh|redraw|xpc|intent|appintent|shortcut|notification|distributed|darwin|defaults|UserDefaults|desktop|screen|set|get'
```

```zsh
jq -r '.actions | to_entries[] | [.key, .value.title.key, (.value.descriptionMetadata.descriptionText.key // ""), (.value.openAppWhenRun|tostring), ((.value.parameters // []) | map(.name + ":" + (.title.key // "")) | join(", "))] | @tsv' \
  /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperControlsExtension.appex/Contents/Resources/Metadata.appintents/extract.actionsdata
jq -r '.actions | to_entries[] | [.key, .value.title.key, (.value.descriptionMetadata.descriptionText.key // ""), (.value.openAppWhenRun|tostring), ((.value.parameters // []) | map(.name + ":" + (.title.key // "")) | join(", "))] | @tsv' \
  /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperIntents.appex/Contents/Resources/Metadata.appintents/extract.actionsdata
jq -r '.actions | to_entries[] | [.key, .value.title.key, (.value.descriptionMetadata.descriptionText.key // ""), (.value.openAppWhenRun|tostring), ((.value.parameters // []) | map(.name + ":" + (.title.key // "")) | join(", "))] | @tsv' \
  /System/Library/ExtensionKit/Extensions/WallpaperSettingsIntents.appex/Contents/Resources/Metadata.appintents/extract.actionsdata
```

```zsh
LC_ALL=C strings -a /System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/XPCServices/WallpaperHelper.xpc/Contents/MacOS/WallpaperHelper |
  rg -i 'wallpaper|reload|refresh|redraw|xpc|helper|notification|distributed|darwin|defaults|UserDefaults|desktop|screen|set|get|url|extension'
```

```zsh
LC_ALL=C strings -a /usr/libexec/wallpaperexportd |
  rg -i 'wallpaper|export|reload|refresh|redraw|xpc|mach|notification|distributed|darwin|defaults|UserDefaults|desktop|screen|set|get|url|service'
```

Key observations:

- `com.apple.wallpaper.export` is a LaunchDaemon Mach service backed by
  `/usr/libexec/wallpaperexportd`.
- `wallpaperexportd` exports `Wallpaper.ExportXPCProtocol` methods:
  `write`, `clear`, `readMetadata`, and `markIdleAssetsAsPurgeable`.
- `wallpaperexportd` uses `EntitlementXPCSecurityPolicy` with
  `com.apple.private.wallpaper.export`.
- `wallpaperexportd` strings reference `/var/db/Wallpapers`,
  `/Library/Application Support/com.apple.idleassetsd`,
  `com.apple.wallpaper.idleassets.delete`, and export/clear/read-metadata
  log messages.
- `WallpaperHelper.xpc` declares
  `com.apple.preferencepanessupport.WallpaperHelper` and strings expose
  `WallpaperHelperProtocol` plus `removeWallpaperFiles:`.
- `WallpaperDiagnosticExtension.appex` declares extension point
  `com.apple.diagnosticextensions-service` with attachment name `Wallpaper`.
- `WallpaperControlsExtension.appex` is a WidgetKit extension with
  `SkipShuffledContentAction`, `SkipShuffledContentButton`, and
  `com.apple.wallpaper.skip`.
- `WallpaperControlsExtension` App Intents metadata exposes one discoverable
  action: `SkipShuffledContentAction`, title `Skip Wallpaper`,
  `openAppWhenRun=false`, no parameters.
- `WallpaperIntents.appex` is an App Intents extension with
  `SetWallpaperIntent`, `SetWallpaperPhotoIntent`, `WallpaperEntityQuery`,
  `_wallpaper`, and `_showAsScreenSaver`.
- `WallpaperIntents` App Intents metadata exposes `SetWallpaperIntent`
  (`Set Wallpaper`, parameters `wallpaper`, `showOnAllSpaces`,
  `showAsScreenSaver`) and `SetWallpaperPhotoIntent` (`Set Wallpaper Photo`,
  parameters `photo`, `showOnAllSpaces`).
- `WallpaperSettingsIntents.appex` metadata exposes discoverable Settings
  actions: `OpenWallpaperDeepLinks`, `ScreenSaverNameIntent`,
  `UpdateShowAsScreenSaverEntityValueIntent`,
  `UpdateShowAsWallpaperEntityValueIntent`,
  `UpdateShowScreenSaverOnAllSpacesEntityValueIntent`, and
  `UpdateShowWallpaperOnAllSpacesEntityValueIntent`.
- `Wallpaper.plist` feature flags expose `Gradients` and `LivePreviews` as
  `FeatureComplete`.
- `NeptuneWallpaper.plist` exposes `one` as `FeatureComplete`.
- `com.apple.wallpaper` logging preferences enable persisted performance
  signposts and configure default log TTL.

## Logs

```zsh
log show --last 24h --style compact \
  --predicate 'process == "WallpaperAgent" AND (eventMessage CONTAINS[c] "debug" OR eventMessage CONTAINS[c] "Failed to Decode" OR eventMessage CONTAINS[c] "Accepted XPC" OR eventMessage CONTAINS[c] "reload" OR eventMessage CONTAINS[c] "generation")'
```

Prior ordinary-client probes reached the normal service and logged
`Failed to Decode XPC Message: NSCocoaErrorDomain (4865)`. Treat this as a
private envelope or metadata mismatch until receiver-side evidence proves a
different cause.

## Runtime Normal XPC Probe

The branch now includes a minimal local SwiftPM target named `Wallpaper` with
no-payload `AgentXPCMessage` cases for `diagnosticState`, `snapshotAllSpaces`,
and `getCaches`.

```zsh
.build/debug/spelunk wallpaper-agent normal-xpc-probe --request diagnostic-state
```

Observed result:

```text
machService: com.apple.wallpaper
request: diagnosticState
succeeded: false
rawReply: XPCReceivedMessage(dictionary: <dictionary: ...> { count = 0, transaction: 0, voucher = 0x0, contents =
}, metadata: XPC.XPCReceivedMessage.XPCReceivedMessageMetadata)
error: Normal XPC replied, but diagnosticState could not be decoded as Data: DecodingError.valueNotFound: Expected value of type Data but found null instead. Debug description: Received message from a process running old XPC coder
```

The other no-payload probes also returned empty replies:

```zsh
.build/debug/spelunk wallpaper-agent normal-xpc-probe --request snapshot-all-spaces
.build/debug/spelunk wallpaper-agent normal-xpc-probe --request get-caches
```

Observed log evidence:

```text
Accepted XPC Connection
Failed to Decode XPC Message: NSCocoaErrorDomain (4865) <private>
```

Interpretation: the normal Mach service is reachable, but local module/type
identity alone is not enough for `Wallpaper.AgentXPCMessage`. The normal-agent
Swift/XPC envelope remains unsolved, which keeps
`ensureViewModelIsUpToDate` blocked as a private redraw probe.

## Repository Helper

Non-mutating commands:

```zsh
swift run spelunk wallpaper-agent inventory
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper.debug.service
swift run spelunk wallpaper-agent debug-xpc-probe
swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80
swift run spelunk wallpaper-agent normal-xpc-probe --request diagnostic-state
swift run spelunk wallpaper-agent sip-validation-report
swift run spelunk wallpaper-agent restart-probe-plan
swift run spelunk wallpaper-agent redraw-static-plan
swift run spelunk wallpaper-agent redraw-probe-plan
swift run spelunk wallpaper-agent signal-plan --signal TERM
```

Mutating commands require an explicit execute flag:

```zsh
swift run spelunk wallpaper-agent redraw-static --execute
swift run spelunk wallpaper-agent signal --execute --signal TERM
swift run spelunk wallpaper-agent restart-probe --execute --signal TERM
swift run spelunk wallpaper-agent redraw-probe --execute
```

Observed in this branch:

- `inventory`: confirmed current-user `WallpaperAgent` and all expected Mach
  services.
- `xpc-ping-empty com.apple.wallpaper`: returned an empty dictionary reply.
- `xpc-ping-empty com.apple.wallpaper.debug.service`: failed with
  `Underlying connection interrupted`.
- `debug-xpc-probe`: decoded downloaded Aerial assets through
  `WallpaperDebugRequestMessage` on this SIP-disabled boot.
- `log-snapshot --last 10m --limit 12`: captured recent debug XPC peer
  connection activation and `handleDebugRequest` begin/end lines.
- `normal-xpc-probe --request diagnostic-state`: reached
  `com.apple.wallpaper` but received an empty old-coder reply; logs showed
  `Accepted XPC Connection` followed by `Failed to Decode XPC Message:
  NSCocoaErrorDomain (4865)`.
- `sip-validation-report`: collected SIP status, inventory, debug-XPC read
  probe, static redraw plan, redraw probe plan, signal plan, restart probe
  plan, and bounded log snapshot; reported `sipProofClaim: not eligible
  because SIP is not enabled for this boot.`
- `restart-probe-plan`: reported the current target pid and did not collect
  after/respawn evidence because it did not execute.
- `redraw-probe-plan`: reported the current desktop image URL and did not
  collect after/preserved-image evidence because it did not execute.
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

Additional receiver-side trace from the expanded script and narrow disassembly
windows:

```zsh
/Applications/Ghidra/ghidra_12.1.2_PUBLIC/support/analyzeHeadless \
  /tmp/WallpaperAgentGhidra WallpaperAgent \
  -import /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent \
  -scriptPath "$PWD/tools/ghidra" \
  -postScript DumpWallpaperDebugReferences.java \
  -analysisTimeoutPerFile 180 \
  -deleteProject
```

```zsh
otool -arch x86_64 -tV /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent |
  awk '$1 >= "000000010009b400" && $1 <= "000000010009bc80" { print }'
```

Key addresses from the x86_64 slice:

- `0x10009b455`: debug request receiver path.
- `0x10009b4de`: loads `WallpaperDebugRequestMessage` metadata.
- `0x10009b52e`: loads `WallpaperDebugRequestMessage : Decodable`.
- `0x10009b54d`: calls `XPCReceivedMessage.decode(as:)`.
- `0x10009b685`: calls `XPCReceivedMessage.handoffReply(to:_:)`.
- `0x10009b892`: async path loads `WallpaperDebugRequest` metadata.
- `0x10009b8ba`: async path loads `WallpaperDebugResponse` metadata.
- `0x10009b930`: calls `WallpaperDebugRequestMessage.request`.
- `0x10009b935`: calls
  `WallpaperDebugRequestMessage.extensionIdentifier`.
- `0x10009ba4f`: loads `WallpaperDebugResponse : Encodable`.
- `0x10009ba64`: calls `XPCReceivedMessage.reply(_:)`.
- `0x1001444d9`: extension/provider lookup helper; loads
  `WallpaperChoiceProviderID` metadata and iterates a dictionary-like
  collection.
- `0x10014406e`: reads a candidate extension/proxy object from the resolved
  entry.
- `0x100144071`: loads the imported async function pointer for
  `WallpaperExtensionProxy.handleDebugRequest`.
- `0x1001440bc`: tail-calls
  `WallpaperExtensionProxy.handleDebugRequest(WallpaperDebugRequest)`.
- `0x100144151`: loads `WallpaperDebugResponse.error(String)` for a branch
  using the literal `com.apple.wallpaper.extension`.
- `0x1001442b3`: builds an error string beginning with `No valid extension`.
- `0x100144340`: loads `WallpaperDebugResponse.error(String)` for the
  `No valid extension` path.

Ghidra symbol cross-reference notes:

- `WallpaperDebugRequestMessage : Decodable` has a parameter reference in
  `FUN_10009b455` at `0x10009b52e`.
- `WallpaperDebugResponse : Encodable` has a parameter reference at
  `0x10009ba4f`.
- `WallpaperDebugResponse.error(String)` has read references around
  `0x100144158` and `0x100144347`, which look like error-response construction
  paths but were not traced in this slice.
- The agent string table also contains `Unable to handle request:`, adjacent
  to the extension-error literals. Treat it as a likely failed-request logging
  or error-composition prefix until decompiled.

Interpretation: the debug listener receives a Swift/XPC request, decodes the
body as `WallpaperDebugRequestMessage`, extracts `request` and
`extensionIdentifier`, resolves the matching extension/provider entry,
dispatches asynchronously to `WallpaperExtensionProxy.handleDebugRequest`, then
replies by encoding `WallpaperDebugResponse`. This rules out a plain XPC
dictionary protocol for successful calls.

## Controlled Experiments To Capture

Do these only when visible desktop interruption is acceptable:

1. Same-user `SIGTERM` restart probe:
   - record pid and `launchctl print` before
   - run `swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80`
   - run `swift run spelunk wallpaper-agent restart-probe --execute --signal TERM`
   - record pid and `launchctl print` after, using the command's
     `respawnObserved` result as the first pass
   - rerun `swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80`
     to capture relaunch, reload, generation, runtime, or snapshot evidence
2. Public AppKit same-image reapply:
   - record current image URL and options for every `NSScreen`
   - run `swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80`
   - run `swift run spelunk wallpaper-agent redraw-probe --execute`
   - rerun `swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80`
   - capture visual result
3. Private `ensureViewModelIsUpToDate` probe:
   - only after the private Swift/XPC envelope is solved
   - test safe refresh reasons before any mutating messages
4. Debug XPC asset-list probe:
   - rerun `swift run spelunk wallpaper-agent sip-validation-report` on a
     SIP-enabled boot
   - prefer `accessAllAssets(.downloaded)` before any download or removal
     request
