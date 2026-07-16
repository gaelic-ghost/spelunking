# WallpaperAgent and Wallpaper Debug XPC

## Scope

This writeup covers local, private research into `WallpaperAgent`, its normal
and debug Mach services, the recovered `WallpaperDebugServer` request surface,
and userland-accessible restart or redraw candidates that should still be
callable with SIP enabled.

This is not public API guidance, App Store guidance, or a redistribution path.
It is evidence for private, local tooling and follow-up experiments.

`launchctl kickstart` is explicitly out of scope for the reset path. It is not
treated as a SIP-enabled userland solution here.

## Environment

| Field | Value |
| --- | --- |
| Active OS observed | macOS 26.5.2, build 25F84 |
| Selected toolchain observed | Xcode beta, Swift 6.4 |
| SIP state during this capture | Disabled |
| Target access model | Ordinary userland with SIP enabled |
| Wallpaper component build | `WallpaperMac-245.4.8` |
| Agent executable | `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent` |
| LaunchAgent | `/System/Library/LaunchAgents/com.apple.wallpaper.plist` |
| Launchd job | `gui/<uid>/com.apple.wallpaper.agent` |
| Primary shared-cache evidence | `dyld_shared_cache_arm64e.05` |

The SIP state matters. Runtime observations in this pass were collected on a
machine with SIP disabled, but this document only promotes mechanisms as
SIP-enabled candidates when they are same-user userland operations, public API
operations, or namespace lookups that do not require task attachment, code
injection, launchd bootstrapping, private entitlements, or filesystem mutation.

## Repository Helper

The `spelunk` executable now has a WallpaperAgent helper surface:

```zsh
swift run spelunk wallpaper-agent inventory
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper
swift run spelunk wallpaper-agent xpc-ping-empty com.apple.wallpaper.debug.service
swift run spelunk wallpaper-agent redraw-static-plan
swift run spelunk wallpaper-agent signal-plan --signal TERM
```

Those commands are non-mutating. The mutating commands require `--execute`:

```zsh
swift run spelunk wallpaper-agent redraw-static --execute
swift run spelunk wallpaper-agent signal --execute --signal TERM
```

The helper deliberately does not offer a `kickstart` path.

Observed non-mutating results from this branch:

| Command | Result |
| --- | --- |
| `inventory` | Found current-user `WallpaperAgent` and all four expected Mach services. |
| `xpc-ping-empty com.apple.wallpaper` | Succeeded with an empty dictionary reply. |
| `xpc-ping-empty com.apple.wallpaper.debug.service` | Failed with `Underlying connection interrupted`. |
| `redraw-static-plan` | Found the current static desktop image URL without reapplying it. |
| `signal-plan --signal TERM` | Found the current `WallpaperAgent` pid and planned `SIGTERM` without executing it. |

## Evidence Inventory

- [x] LaunchAgent declaration for `com.apple.wallpaper.agent`
- [x] Live launchd service inventory from the user's Aqua namespace
- [x] Running process ownership and bundle path
- [x] Agent signing, platform, sandbox, and entitlement inventory
- [x] Agent dynamic dependency list
- [x] Agent strings for debug server, debug listener, normal XPC handlers, and
      internal redraw/rebuild methods
- [x] SDK `.tbd` exported Swift symbols for `Wallpaper`,
      `WallpaperTypes`, and `WallpaperExtensionKit`
- [x] Shared-cache strings for debug request, response, and extension bridge
      vocabulary
- [x] Demangled signatures for `AgentXPCProtocol`, `AgentXPCMessage`,
      `WallpaperDebugRequestMessage`, `WallpaperDebugRequest`,
      `WallpaperDebugResponse`, and related payloads
- [x] SwiftPM helper for safe inventory, empty XPC ping, static-redraw dry run,
      and same-user signal dry run
- [x] Headless Ghidra string/data-reference pass for debug and redraw anchors
- [ ] Receiver-side implementation trace of `WallpaperDebugServer`
- [ ] SIP-enabled proof that an ordinary client can successfully call the
      private Swift/XPC envelope
- [ ] SIP-enabled proof for a non-mutating redraw request
- [ ] SIP-enabled proof for same-user restart and launchd respawn behavior

## Service Ownership

`com.apple.wallpaper.agent` is an Aqua-session LaunchAgent. Its launch plist
declares:

| Key | Observed value |
| --- | --- |
| `Label` | `com.apple.wallpaper.agent` |
| `Program` | `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent` |
| `LimitLoadToSessionType` | `Aqua` |
| `POSIXSpawnType` | `App` |
| `KeepAlive.AfterInitialDemand` | `true` |
| `KeepAlive.SuccessfulExit` | `false` |
| `RunAtLoad` | `false` |
| `ThrottleInterval` | `1` |

The LaunchAgent declares four Mach services:

| Mach service | Role |
| --- | --- |
| `com.apple.wallpaper` | Normal agent control surface |
| `com.apple.wallpaper.debug.service` | Debug request tunnel to wallpaper extensions |
| `com.apple.wallpaper.CacheDelete` | CacheDelete integration |
| `com.apple.usernotifications.delegate.com.apple.wallpaper.notifications.sonoma-first-run` | Notification delegate |

`launchctl print gui/<uid>` confirms that the active user namespace has live
entries for `com.apple.wallpaper`, `com.apple.wallpaper.debug.service`, and
`com.apple.wallpaper.CacheDelete`. This proves namespace ownership and lookup
visibility. It does not prove client authorization for every message.

## Agent Boundary

The agent is Apple signed as `com.apple.wallpaper.agent` and carries platform
identifier `26`. It is sandboxed and has private entitlements for wallpaper,
extension hosting, SkyLight desktop effects, Dock spaces, CacheDelete,
RunningBoard assertions, TCC access, and read/write access to wallpaper support
state.

Relevant entitlements include:

| Entitlement | Practical meaning |
| --- | --- |
| `com.apple.security.app-sandbox` | The agent runs sandboxed. |
| `com.apple.private.wallpaper.extension-host` | It can host wallpaper extensions. |
| `com.apple.private.wallpaper.export` | It can use wallpaper export surfaces. |
| `com.apple.private.skylight.desktop-effects` | It can talk to protected desktop/compositor state. |
| `com.apple.private.dock.spaces` | It can inspect or manipulate Spaces-related state. |
| `com.apple.runningboard.underlyingassertion` | It can take underlying RunningBoard assertions. |
| `com.apple.extensionkit.host.extension-point-identifiers` | It hosts `com.apple.wallpaper` and `com.apple.wallpaper.development`. |
| `com.apple.private.CacheDelete` | It participates in CacheDelete purge accounting. |
| `com.apple.private.tcc.allow` | It has broad local data access for system policy and Photos. |

This boundary is why Mach-service reachability is not enough. A normal user
process can see the services, but the normal and debug protocols are private
Swift/XPC protocols with their own envelope, metadata identity, and security
policy.

## Linked Frameworks

`WallpaperAgent` links the private Wallpaper stack and Swift XPC:

- `Wallpaper.framework`
- `WallpaperTypes.framework`
- `WallpaperExtensionKit.framework`
- `WallpaperFoundation.framework`
- `WallpaperAnalytics.framework`
- `WallpaperAerialAssets.framework`
- `DynamicDesktop.framework`
- `SkyLight.framework`
- `RunningBoardServices.framework`
- `ChronoServices.framework`
- `ExtensionFoundation.framework`
- `libswiftXPC.dylib`

The sealed system volume exposes private framework stubs and SDK `.tbd` files,
but the implementation lives in the dyld shared cache on this system.

## Normal Agent XPC API

The normal service is `com.apple.wallpaper`. The SDK `.tbd` symbols expose the
private protocol `Wallpaper.AgentXPCProtocol` and the request enum
`Wallpaper.AgentXPCMessage`.

### Transport Model

The normal protocol is Swift/XPC, not a simple dictionary API. Prior probes
using plain XPC dictionaries reached the service but produced empty replies or
decode errors. The recovered protocol uses `WallpaperXPCRemoteProcess?` sender
metadata and a private `AgentXPCSecurityPolicy`.

The security policy exports:

| Symbol | Signature |
| --- | --- |
| `allow` | `allow(process: WallpaperXPCRemoteProcess) -> Bool` |
| `checkAccess` | `checkAccess(message: AgentXPCMessage, for: WallpaperXPCRemoteProcess) throws` |

This means every normal-agent message must be evaluated as both a Codable
message-shape problem and an authorization problem.

### Request Enum

Recovered `AgentXPCMessage` cases:

| Case | Payload |
| --- | --- |
| `updateDesktopWallpaperUserSettings` | `WallpaperUserSettings` |
| `updateScreenSaverWallpaperUserSettings` | `WallpaperUserSettings` |
| `getOverride` | `Override` |
| `setOverride` | `OverrideValue` |
| `purgeChoice` | `WallpaperChoice.ID` |
| `pauseDownload` | `WallpaperChoice.ID` |
| `cancelDownload` | `WallpaperChoice.ID` |
| `downloadChoice` | `WallpaperChoice.ID` |
| `resumeDownload` | `WallpaperChoice.ID` |
| `setAssertions` | `[AssertionID: AssertionValue]` |
| `takeAssertion` | `(AssertionID, AssertionValue)` |
| `releaseAssertion` | `AssertionID` |
| `diagnosticState` | none |
| `snapshotAllSpaces` | none |
| `addChoiceRequest` | `WallpaperChoiceRequest` |
| `removeChoiceRequest` | `WallpaperChoiceRequest` |
| `skipShuffledContent` | `UUID?` |
| `canSkipShuffledContent` | `UUID` |
| `setDisplaySpacesInfo` | `WallpaperDisplaySpacesInfo` |
| `invokeContextMenuAction` | `(ContextMenuItem.ID, WallpaperSettingsItem.ID, WallpaperChoiceProviderID)` |
| `registerSettingsObserver` | none |
| `ensureViewModelIsUpToDate` | `([ContentType], ViewModelRefreshReason)` |
| `getLegacyDesktopPictureConfiguration` | `(SpaceName, DisplayIdentifier)` |
| `setLegacyDesktopPictureConfiguration` | `(LegacyDesktopPictureConfiguration, SpaceName, DisplayIdentifier, audit_token_t?)` |
| `getCaches` | none |

### Protocol Methods

Recovered `AgentXPCProtocol` methods:

| Method | Return |
| --- | --- |
| `updateDesktopWallpaperUserSettings(_:sender:) async throws` | `Void` |
| `updateScreenSaverWallpaperUserSettings(_:sender:) async throws` | `Void` |
| `getOverride(override:sender:) async throws` | `OverrideValue` |
| `setOverride(override:sender:) async throws` | `Void` |
| `purgeChoice(_:sender:) async throws` | `Void` |
| `pauseDownload(_:sender:) async throws` | `Void` |
| `cancelDownload(_:sender:) async throws` | `Void` |
| `downloadChoice(_:sender:) async throws` | `Void` |
| `resumeDownload(_:sender:) async throws` | `Void` |
| `setAssertions(_:sender:) async throws` | `[AssertionID: UInt32]` |
| `takeAssertion(id:value:sender:) async throws` | `AssertionReply` |
| `releaseAssertion(id:sender:) async throws` | `Void` |
| `diagnosticState(sender:) async throws` | `Data` |
| `snapshotAllSpaces(sender:) async throws` | `[AnnotatedSnapshot]` |
| `updateViewModel(addingChoiceRequest:sender:) async throws` | `WallpaperChoiceRequestAdditionResult` |
| `updateViewModel(removingChoiceRequest:sender:) async throws` | `Void` |
| `skipShuffledContent(displayUUID:sender:) async throws` | `Void` |
| `canSkipShuffledContent(on:sender:) async throws` | `Bool` |
| `setDisplaySpacesInfo(info:sender:) throws` | `Void` |
| `invokeContextMenuAction(menuItemID:groupItemID:choiceProviderID:sender:) async throws` | `Void` |
| `registerSettingsObserver(sender:) async throws` | `Void` |
| `ensureViewModelIsUpToDate(contentTypes:reason:sender:) async throws` | `Void` |
| `getLegacyDesktopPictureConfiguration(for:on:sender:) async throws` | `LegacyDesktopPictureConfiguration` |
| `setLegacyDesktopPictureConfiguration(_:for:on:onBehalfOfProcess:sender:) async throws` | `Void` |
| `getCaches(sender:) async throws` | `WallpaperCaches` |

### Redraw-Relevant Normal Messages

The closest normal-agent redraw candidates are:

| Candidate | Evidence | Confidence |
| --- | --- | --- |
| `ensureViewModelIsUpToDate(contentTypes:reason:sender:)` | Exported protocol method and enum case. `ViewModelRefreshReason` has `launch`, `navigation`, and `wallpaperInstallation`. | Strong API evidence, unproven ordinary-client access |
| `snapshotAllSpaces(sender:)` | Exported protocol method, agent handler string, and returns `[AnnotatedSnapshot]`. | Strong diagnostics evidence, not necessarily redraw |
| `diagnosticState(sender:)` | Exported protocol method, agent handler string, returns `Data`. | Strong diagnostics evidence, not redraw |
| `setDisplaySpacesInfo(info:sender:)` | Exported protocol method. | Strong API evidence, likely privileged and state-mutating |
| `skipShuffledContent(displayUUID:sender:)` | Exported protocol method and UI control string `com.apple.wallpaper.skip`. | Strong API evidence, only shuffle advance |

`ensureViewModelIsUpToDate` is the strongest private redraw candidate, but it
still requires exact Swift/XPC envelope construction and may be blocked by
`AgentXPCSecurityPolicy`.

## WallpaperDebugServer API

### Transport

The debug Mach service is `com.apple.wallpaper.debug.service`. The agent binary
contains:

- `WallpaperDebugServer`
- `WallpaperDebugRequestHandler`
- `com.apple.wallpaper.debug.listener`

The transport payload type recovered from `WallpaperTypes` is:

```swift
struct WallpaperDebugRequestMessage: Codable {
    let extensionIdentifier: String
    let request: WallpaperDebugRequest
}
```

The initializer is exported as:

```swift
init(extensionIdentifier: String, request: WallpaperDebugRequest)
```

The likely route is:

1. A client connects to `com.apple.wallpaper.debug.service`.
2. The client sends a `WallpaperDebugRequestMessage`.
3. The agent decodes the message in `WallpaperDebugServer`.
4. The agent selects a wallpaper extension by `extensionIdentifier`.
5. The agent forwards the request to the extension-side debug handler.
6. The extension returns `WallpaperDebugResponse`.

Steps 1 through 3 are supported by service and type evidence. Steps 4 through 6
are inferred from the message field, extension bridge types, and
`WallpaperExtensionProxy.handleDebugRequest`.

### Request Enum

Recovered `WallpaperDebugRequest` cases:

| Case | Payload | Meaning |
| --- | --- | --- |
| `accessAllAssets` | `WallpaperDebugAssetType` | Ask an extension for an asset list. |
| `downloadAsset` | `String` | Start or request download of an asset by id. |
| `downloadAssetState` | `String` | Query download state for an asset by id. |
| `removeAsset` | `String` | Remove a local asset by id. |

The enum is `Codable`.

### Asset Type Enum

Recovered `WallpaperDebugAssetType` cases:

| Case | Meaning |
| --- | --- |
| `all` | Include all assets known to the extension. |
| `downloaded` | Include downloaded assets only. |

The enum is `Codable`, `Hashable`, and `Equatable`.

### Response Enum

Recovered `WallpaperDebugResponse` cases:

| Case | Payload | Meaning |
| --- | --- | --- |
| `success` | none | Request completed without an additional payload. |
| `error` | `String` | Request failed with a string error. |
| `allAssets` | `WallpaperAssetList` | Asset-list response. |
| `downloadState` | `WallpaperAssetDownloadState` | Download-state response. |

The enum is `Codable`.

### Asset List Payload

Recovered `WallpaperAssetList` shape:

```swift
struct WallpaperAssetList: Codable {
    let assets: [Asset]

    struct Asset: Codable {
        let name: String
        let id: String
        let isDownloaded: Bool
    }
}
```

The exported initializers are:

```swift
WallpaperAssetList.init(assets: [WallpaperAssetList.Asset])
WallpaperAssetList.Asset.init(name: String, id: String, isDownloaded: Bool)
```

### Download State Payload

Recovered `WallpaperAssetDownloadState` shape:

```swift
struct WallpaperAssetDownloadState: Codable {
    let assetID: String
    let progress: Float
    let isDownloaded: Bool
}
```

The exported initializer is:

```swift
init(assetID: String, progress: Float, isDownloaded: Bool)
```

### Extension Bridge

`WallpaperExtensionKit` exports the extension-side bridge:

```swift
WallpaperExtensionProxy.handleDebugRequest(
    _ request: WallpaperDebugRequest
) async throws -> WallpaperDebugResponse
```

The shared-cache strings also expose Objective-C XPC bridge vocabulary:

- `WallpaperDebugRequestXPC`
- `WallpaperDebugResponseXPC`
- `handleDebugRequestFor:reply:`
- method encoding `v32@0:8@"WallpaperDebugRequestXPC"16@?<v@?@"WallpaperDebugResponseXPC"@"NSError">24`

This suggests the agent receives the Swift/XPC debug message, then talks to the
extension through an Objective-C-compatible ExtensionKit XPC wrapper.

### Extension Identifiers

Built-in wallpaper extensions observed in `/System/Library/ExtensionKit/Extensions`:

| Identifier | Bundle |
| --- | --- |
| `com.apple.wallpaper.extension.aerials` | `WallpaperAerialsExtension.appex` |
| `com.apple.wallpaper.extension.dynamic` | `WallpaperDynamicExtension.appex` |
| `com.apple.wallpaper.extension.gradient` | `WallpaperGradientExtension.appex` |
| `com.apple.wallpaper.extension.image` | `WallpaperImageExtension.appex` |
| `com.apple.wallpaper.extension.legacy` | `WallpaperLegacyExtension.appex` |
| `com.apple.wallpaper.extension.macintosh` | `WallpaperMacintoshExtension.appex` |
| `com.apple.wallpaper.extension.monterey` | `WallpaperMontereyExtension.appex` |
| `com.apple.wallpaper.extension.sequoia` | `WallpaperSequoiaExtension.appex` |
| `com.apple.wallpaper.extension.sonoma` | `WallpaperSonomaExtension.appex` |
| `com.apple.wallpaper.extension.ventura` | `WallpaperVenturaExtension.appex` |
| `com.apple.NeptuneOneExtension` | `NeptuneOneWallpaper.appex` |

These are plausible `extensionIdentifier` values for
`WallpaperDebugRequestMessage`. They are not all proven to implement every
debug request.

### What The Debug API Does Not Show

The recovered debug vocabulary is asset-oriented. It exposes asset listing,
asset download, asset download-state lookup, and asset removal. It does not
show a generic redraw, reset, relaunch, snapshot invalidation, runtime rebuild,
Spaces refresh, or desktop-layer invalidation request.

Do not use the debug service as the proposed redraw path until a concrete debug
request is proven to affect rendering. As currently recovered, it is best
described as an asset-debug tunnel for wallpaper extensions.

## Runtime Redraw and Restart Surfaces

### Internal Redraw Chain

The agent binary contains these internal strings and symbols:

- `handleGenerationChange`
- `invalidateSnapshots`
- `updateRuntimeState`
- `Request reload due to wallpaper runtime change`
- `clientGenerationDidChange`
- `clientGenerationID incremented`
- `REBUILD: Update Runtime`
- `REBUILD: Resolve Runtime`

This proves the agent has an internal generation-change and snapshot
invalidation path. It does not prove any external trigger.

### SIP-Enabled Candidate Matrix

| Candidate | Path | SIP-enabled status | Risk | Current confidence |
| --- | --- | --- | --- | --- |
| Same-user POSIX signal | Find `WallpaperAgent` owned by the active user and send `SIGTERM` or `SIGKILL` from a normal process. | Candidate. Same-UID signaling is ordinary userland and does not require task attach or code injection. Needs proof on SIP-enabled machine. | Visible desktop interruption; launchd respawn behavior must be measured. | Strong candidate for restart, unproven here |
| `launchctl kill` | Ask launchd to signal `gui/<uid>/com.apple.wallpaper.agent`. | Candidate if allowed from the user bootstrap. It is not `kickstart`, but still uses launchd. Needs proof under SIP. | Visible interruption; may fail under policy. | Candidate only |
| Public desktop-image reapply | Use AppKit `NSWorkspace` desktop image APIs to set the same current image URL for each screen. | Public userland API. Should be SIP-compatible. | Mutates wallpaper settings or timestamps; may not affect dynamic/video wallpaper. | Best public redraw candidate for static desktop pictures |
| Private `ensureViewModelIsUpToDate` | Send normal `AgentXPCMessage.ensureViewModelIsUpToDate([ContentType], ViewModelRefreshReason)` to `com.apple.wallpaper`. | Mach lookup is visible, but message envelope and authorization are not solved. | Private protocol, may be entitlement-gated. | Best private redraw candidate |
| Private `snapshotAllSpaces` | Send normal diagnostic request to `com.apple.wallpaper`. | Same as above. | Could be diagnostic-only. | Useful probe, not a redraw primitive |
| Private debug asset service | Send `WallpaperDebugRequestMessage` to `com.apple.wallpaper.debug.service`. | Mach lookup is visible, but envelope and handler access are unproven. | Asset mutations possible. No generic redraw vocabulary. | Not currently a redraw candidate |
| Filesystem preference touch | Touch wallpaper preferences or support files. | May be user-writable, but indirect and state-mutating. | Fragile, can corrupt or desync state. | Avoid until a watched key/file is proven |
| Darwin or distributed notification | Post a guessed notification. | No confirmed notification name yet. | Low effect, noisy. | Not proven |

### Restart Candidate Details

The process is owned by the active user. That makes same-user signaling the
cleanest restart hypothesis from runtime:

1. Resolve the active `WallpaperAgent` pid for the current user.
2. Send `SIGTERM`.
3. Watch `launchctl print gui/<uid>/com.apple.wallpaper.agent` for a new pid.
4. Watch logs for agent relaunch, service re-registration, and redraw/rebuild.
5. Confirm whether the desktop actually redraws.

This is a controlled experiment, not a recommendation yet. Run it only when a
visible desktop interruption is acceptable.

`launchctl kickstart -k` is deliberately not part of this path.

### Public Redraw Candidate Details

For static desktop pictures, the public AppKit route is:

1. Enumerate `NSScreen.screens`.
2. Read each screen's current desktop image URL through `NSWorkspace`.
3. Set the same URL back for that screen with the same options.

This is the most SIP-compatible redraw candidate because it uses public
userland APIs instead of private XPC. It may not cover live, dynamic, aerial,
or extension-backed wallpapers, and it is still settings mutation rather than
a pure compositor redraw.

### Private Redraw Candidate Details

The private route to test next is the normal agent message:

```swift
AgentXPCMessage.ensureViewModelIsUpToDate(
    [ContentType],
    ViewModelRefreshReason
)
```

Recovered refresh reasons are:

- `launch`
- `navigation`
- `wallpaperInstallation`

The most plausible redraw probes are:

- all content types with `.launch`
- all content types with `.wallpaperInstallation`
- desktop content type only, if the `ContentType` cases can be recovered

The current blocker is not service visibility. It is exact private
Swift/XPC encoding plus `AgentXPCSecurityPolicy`.

## Accessibility From Userland With SIP Enabled

Accessible or likely accessible:

- Process discovery for the same user's `WallpaperAgent`
- Same-user process signaling, pending SIP-enabled proof
- Mach lookup attempts for `com.apple.wallpaper`
- Mach lookup attempts for `com.apple.wallpaper.debug.service`
- Public `NSWorkspace` desktop picture APIs
- Read-only inspection of launchd job state with `launchctl print`
- Unified log reads permitted to the current user

Not accessible or not assumed accessible:

- Task attachment to `WallpaperAgent`
- Code injection into `WallpaperAgent`
- Unsigned or non-Apple private entitlement acquisition
- Receiver-side tracing that requires task port access
- `launchctl kickstart -k` as a reset mechanism
- Calling private messages without solving the Swift/XPC envelope and security
  policy

## Next Experiments

1. Run a controlled public AppKit redraw probe that reapplies the same static
   desktop image on each screen.
2. Run a controlled same-user `SIGTERM` respawn probe outside active desktop
   work, with pid before/after, launchd state, and log evidence.
3. Use Ghidra or another Mach-O/Swift metadata path to inspect
   `WallpaperDebugServer` implementation details:
   - decode call site
   - message envelope type
   - audit-token or code-signing checks
   - extension selection logic
   - error handling
4. Recover `Wallpaper.ContentType` cases and any raw values.
5. Recover `AssertionValue` cases and presentation-mode raw strings.
6. Extend the Swift helper to encode private Swift/XPC messages only after the
   exact metadata identity is solved.

## References

- Raw command inventory: `../../../research/WallpaperAgent/README.md`
- Ghidra helper: `../../../tools/ghidra/DumpWallpaperDebugReferences.java`
- LaunchAgent: `/System/Library/LaunchAgents/com.apple.wallpaper.plist`
- Agent binary: `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent`
- SDK stubs:
  - `System/Library/PrivateFrameworks/Wallpaper.framework/Versions/A/Wallpaper.tbd`
  - `System/Library/PrivateFrameworks/WallpaperTypes.framework/Versions/A/WallpaperTypes.tbd`
  - `System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit.tbd`
