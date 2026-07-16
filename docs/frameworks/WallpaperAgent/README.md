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
swift run spelunk wallpaper-agent debug-xpc-probe
swift run spelunk wallpaper-agent debug-xpc-probe --request download-state --asset-id <asset-id>
swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80
swift run spelunk wallpaper-agent sip-validation-report
swift run spelunk wallpaper-agent normal-xpc-probe --request diagnostic-state
swift run spelunk wallpaper-agent restart-probe-plan
swift run spelunk wallpaper-agent launchctl-kill-plan --signal TERM
swift run spelunk wallpaper-agent redraw-static-plan
swift run spelunk wallpaper-agent redraw-probe-plan
swift run spelunk wallpaper-agent signal-plan --signal TERM
```

Those commands are non-mutating. The mutating commands require `--execute`:

```zsh
swift run spelunk wallpaper-agent redraw-static --execute
swift run spelunk wallpaper-agent debug-xpc-probe --request download-asset --asset-id <asset-id> --execute
swift run spelunk wallpaper-agent debug-xpc-probe --request remove-asset --asset-id <asset-id> --execute
swift run spelunk wallpaper-agent signal --execute --signal TERM
swift run spelunk wallpaper-agent restart-probe --execute --signal TERM
swift run spelunk wallpaper-agent launchctl-kill --execute --signal TERM
swift run spelunk wallpaper-agent redraw-probe --execute
```

The helper deliberately does not offer a `kickstart` path.

Observed non-mutating results from this branch:

| Command | Result |
| --- | --- |
| `inventory` | Found current-user `WallpaperAgent` and all four expected Mach services. |
| `xpc-ping-empty com.apple.wallpaper` | Succeeded with an empty dictionary reply. |
| `xpc-ping-empty com.apple.wallpaper.debug.service` | Failed with `Underlying connection interrupted`. |
| `debug-xpc-probe` with `accessAllAssets(downloaded)` | Succeeded on the current boot and decoded two downloaded Aerial assets. Current boot has SIP disabled, so this is not SIP-enabled proof yet. |
| `debug-xpc-probe --extension com.apple.wallpaper.extension.not-real` | Succeeded on the current boot and decoded `WallpaperDebugResponse.error("No valid extension")`, confirming the receiver dispatch/error path. Current boot has SIP disabled. |
| `debug-xpc-probe --request download-state` | Succeeded on the current boot and decoded `WallpaperAssetDownloadState` for a known asset id. Current boot has SIP disabled. |
| `debug-xpc-probe --request download-asset` without `--execute` | Refused before sending the mutating debug request. |
| `debug-xpc-probe --request remove-asset` without `--execute` | Refused before sending the mutating debug request. |
| `log-snapshot --last 10m --limit 12` | Captured recent `WallpaperAgent` unified log lines showing debug XPC peer connection activation and `handleDebugRequest` begin/end events. |
| `sip-validation-report` | Collected SIP status, inventory, debug-XPC read probe, static redraw plan, redraw probe plan, signal plan, restart probe plan, launchctl-kill plan, and a bounded log snapshot; refused the SIP proof claim because SIP is disabled on this boot. |
| `normal-xpc-probe --request diagnostic-state` | Reached `com.apple.wallpaper` but received an empty old-coder reply; logs showed `Accepted XPC Connection` followed by `Failed to Decode XPC Message: NSCocoaErrorDomain (4865)`. |
| `restart-probe-plan` | Captured current target pid, planned `SIGTERM`, and left after/respawn evidence uncollected because it did not execute. |
| `launchctl-kill-plan --signal TERM` | Planned `/bin/launchctl kill SIGTERM gui/<uid>/com.apple.wallpaper.agent`, captured the current pid, and left exit/after/respawn evidence uncollected because it did not execute. |
| `redraw-probe-plan` | Captured current desktop image URL and options, and left after/preserved-image evidence uncollected because it did not execute. |
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
- [x] SwiftPM local `WallpaperTypes` mirror and debug XPC probe coverage for
      all recovered `WallpaperDebugRequest` cases, with `downloadAsset` and
      `removeAsset` guarded behind `--execute`
- [x] SwiftPM SIP validation report that gates proof claims on
      `csrutil status`
- [x] SwiftPM restart probe plan/execute command that captures before and
      after pids without using `launchctl kickstart`
- [x] SwiftPM `launchctl kill` probe plan/execute command that captures the
      user-bootstrap service target, command arguments, before/after pids, and
      launchctl exit output without using `launchctl kickstart`
- [x] SwiftPM redraw probe plan/execute command that captures before and
      after `NSWorkspace` desktop image state
- [x] SwiftPM unified-log snapshot command for bounded `WallpaperAgent`
      debug/reload/generation evidence
- [x] SwiftPM local `Wallpaper` mirror and non-mutating normal XPC probe for
      `diagnosticState`, `snapshotAllSpaces`, and `getCaches`
- [x] Headless Ghidra string/data-reference pass for debug and redraw anchors
- [x] Adjacent userland surface inventory for export daemon, Settings helper,
      diagnostic extension, WallpaperAgent plug-ins, ExtensionKit wallpaper
      extensions, feature flags, logging preferences, and filtered
      string/symbol evidence
- [x] Static receiver-side implementation trace of `WallpaperDebugServer`
      decode, async handoff, extension lookup, `handleDebugRequest` dispatch,
      error-response construction, and response reply
- [x] Static supporting-type and security-policy evidence for
      `ContentType`, `AssertionValue`, `AssertionPresentationMode`,
      `WallpaperStoreContentType`, and `AgentXPCSecurityPolicy`
- [x] Swift metadata recovery of `Wallpaper.ContentType` cases and byte values
      for the private redraw candidate
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

The broader system also includes a LaunchDaemon for wallpaper export:

| Key | Observed value |
| --- | --- |
| `Label` | `com.apple.wallpaper.export` |
| `Program` | `/usr/libexec/wallpaperexportd` |
| `MachServices` | `com.apple.wallpaper.export` |
| `EnablePressuredExit` | `true` |
| `EnableTransactions` | `true` |
| `POSIXSpawnType` | `Adaptive` |
| `ThrottleInterval` | `1` |

This daemon is root-launched and separate from the Aqua-session
`WallpaperAgent`. Its recovered protocol is an export/preboot/idle-assets
surface, not a redraw or restart surface.

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

## Adjacent Userland Surfaces

This inventory covers surfaces that are discoverable from ordinary userland on
this system. Discoverable means the plist, bundle, service name, or public
metadata is readable. It does not mean an unsigned ordinary client can perform
the privileged operation behind that surface.

### Export Daemon

`/usr/libexec/wallpaperexportd` owns the Mach service
`com.apple.wallpaper.export`. Demangled symbols recover the private protocol
`Wallpaper.ExportXPCProtocol`:

| Method | Return |
| --- | --- |
| `write(_:sender:) async throws` | `Void` |
| `clear(sender:) async throws` | `Void` |
| `readMetadata(sender:) async throws` | `EncodedExportedWallpaperMetadata?` |
| `markIdleAssetsAsPurgeable(sender:) async throws` | `Void` |

The daemon constructs an `EntitlementXPCSecurityPolicy` for the entitlement
`com.apple.private.wallpaper.export`. Strings reference
`/var/db/Wallpapers`, `/Library/Application Support/com.apple.idleassetsd`,
`com.apple.wallpaper.idleassets.delete`, and export/clear/read-metadata log
messages.

Conclusion: this is a real Wallpaper XPC service, but the recovered API is
for exported wallpaper state and idle-assets cleanup. It is entitlement-gated
and not currently a SIP-enabled redraw or restart candidate.

### Settings Helper XPC

`WallpaperHelper.xpc` lives under
`PreferencePanesSupport.framework` and declares:

| Field | Value |
| --- | --- |
| Bundle identifier | `com.apple.preferencepanessupport.WallpaperHelper` |
| Executable | `WallpaperHelper` |
| Package type | `XPC!` |
| XPC service type | `Application` |

Filtered strings expose `WallpaperHelperProtocol` and
`removeWallpaperFiles:`. The helper is therefore a Settings-support cleanup
surface, not a redraw primitive. It may be relevant when tracing wallpaper
file removal from Settings, but it does not expose any recovered refresh,
reload, or restart vocabulary.

### Diagnostic Extension

`WallpaperDiagnosticExtension.appex` declares:

| Field | Value |
| --- | --- |
| Bundle identifier | `com.apple.DiagnosticExtensions.WallpaperMac` |
| Executable | `WallpaperDiagnosticExtension` |
| Extension point | `com.apple.diagnosticextensions-service` |
| Principal class | `WallpaperDiagnosticExtension.WallpaperDiagnosticExtension` |
| Attachment name | `Wallpaper` |

This is a diagnostics collection surface. It should be treated as useful for
sysdiagnose-style evidence, not as a redraw/reset hook.

### WallpaperAgent Plug-ins

`WallpaperAgent.app` embeds two plug-ins:

| Bundle identifier | Executable | Extension point | Relevant evidence |
| --- | --- | --- | --- |
| `com.apple.wallpaper.agent.controls` | `WallpaperControlsExtension` | `com.apple.widgetkit-extension` | Metadata action `SkipShuffledContentAction`, title `Skip Wallpaper`, `openAppWhenRun=false`, no parameters; binary strings also expose `SkipShuffledContentButton`, `com.apple.wallpaper.skip`, and the description "Skips to the next wallpaper when using a shuffled collection." |
| `com.apple.wallpaper.agent.WallpaperIntents` | `WallpaperIntents` | `com.apple.appintents-extension` | Metadata actions `SetWallpaperIntent` and `SetWallpaperPhotoIntent`, both `openAppWhenRun=false`; symbols and strings also expose `WallpaperEntityQuery`, `_wallpaper`, `_photo`, `_showOnAllSpaces`, `_showAsScreenSaver`, "Set Wallpaper Photo", and "Show As Screen Saver". |

The controls extension lines up with the normal-agent
`skipShuffledContent`/`canSkipShuffledContent` methods. It is a narrow
shuffle-advance control and not a generic redraw hook. The App Intents
metadata marks the action discoverable and does not list any input parameters,
so the userland surface appears to be "advance shuffled wallpaper if the
current wallpaper supports it."

The App Intents extension appears to expose wallpaper selection actions for
Shortcuts/Siri-style callers. `SetWallpaperIntent` is titled `Set Wallpaper`
with the description "Sets the wallpaper from the list of available system
wallpapers." Its parameters are `wallpaper`, `showOnAllSpaces`, and
`showAsScreenSaver`. `SetWallpaperPhotoIntent` is titled `Set Wallpaper Photo`
with the description "Sets the wallpaper to the specified image." Its
parameters are `photo` and `showOnAllSpaces`.

Conclusion: these are userland-visible automation surfaces for changing
wallpaper selection. They are not a reset primitive and not a redraw of the
current runtime in place.

### Wallpaper Settings Intents

`WallpaperSettingsIntents.appex` has bundle identifier
`com.apple.settings-intents.WallpaperIntents` and declares the WidgetKit
extension point `com.apple.widgetkit-extension`. Its App Intents metadata
exposes:

| Identifier | Title | Behavior |
| --- | --- | --- |
| `OpenWallpaperDeepLinks` | `Wallpaper` | Opens Settings (`openAppWhenRun=true`) to one of `root`, `screenSaver`, or `clockAppearance`. |
| `ScreenSaverNameIntent` | `Main Display Screen Saver Name` | Reads the main-display screen saver name. |
| `UpdateShowAsScreenSaverEntityValueIntent` | `Update Show wallpaper as screen saver on main display` | Updates the main-display "show wallpaper as screen saver" boolean. |
| `UpdateShowAsWallpaperEntityValueIntent` | `Update Show screen saver as wallpaper on main display` | Updates the main-display "show screen saver as wallpaper" boolean. |
| `UpdateShowScreenSaverOnAllSpacesEntityValueIntent` | `Update Show screen saver on all Spaces` | Updates the screen-saver all-Spaces boolean. |
| `UpdateShowWallpaperOnAllSpacesEntityValueIntent` | `Update Show wallpaper on all Spaces` | Updates the wallpaper all-Spaces boolean. |

These are discoverable ordinary App Intents surfaces. The update actions are
state-mutating Settings toggles, not generic repaint or agent lifecycle hooks.

### ExtensionKit Wallpaper Providers

Built-in `com.apple.wallpaper` ExtensionKit providers are the likely targets
for `WallpaperDebugRequestMessage.extensionIdentifier`:

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

The separate `Wallpaper.appex` has bundle identifier
`com.apple.Wallpaper-Settings.extension` and extension point
`com.apple.Settings.extension.ui`; it is the Settings UI extension, not a
wallpaper provider.

`WallpaperSettingsIntents.appex` is not a wallpaper provider extension.

### Feature Flags and Logging

Wallpaper feature flags are present in
`/System/Library/FeatureFlags/Domain/Wallpaper.plist`:

| Flag | Development phase |
| --- | --- |
| `Gradients` | `FeatureComplete` |
| `LivePreviews` | `FeatureComplete` |

`/System/Library/FeatureFlags/Domain/NeptuneWallpaper.plist` declares `one`
as `FeatureComplete`.

The logging preferences at
`/System/Library/Preferences/Logging/Subsystems/com.apple.wallpaper.plist`
configure default log level TTL and enable persisted performance signposts.
These plists are useful for understanding behavior and log capture, but they
are not runtime redraw hooks.

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

The agent also contains receiver-side strings for `Unknown XPC Sender` and
`Remote process %{public}s attempting to connect`. These strings confirm that
the agent records remote-process identity during normal-service connection
handling. They do not prove which caller identities are accepted for each
message.

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

### Normal-Service Runtime Probe Results

A local SwiftPM target named `Wallpaper` can encode no-payload
`AgentXPCMessage` cases, but that mirror is not enough for the normal agent on
this boot:

```zsh
swift run spelunk wallpaper-agent normal-xpc-probe --request diagnostic-state
swift run spelunk wallpaper-agent normal-xpc-probe --request snapshot-all-spaces
swift run spelunk wallpaper-agent normal-xpc-probe --request get-caches
```

Observed results:

| Probe | Runtime result |
| --- | --- |
| `diagnosticState` | `com.apple.wallpaper` returned an empty XPC reply. Decoding as `Data` failed with `Received message from a process running old XPC coder`. |
| `snapshotAllSpaces` | `com.apple.wallpaper` returned an empty XPC reply. No local mirror for `[AnnotatedSnapshot]` was attempted. |
| `getCaches` | `com.apple.wallpaper` returned an empty XPC reply. No local mirror for `WallpaperCaches` was attempted. |

The matching log evidence is stronger than the empty reply alone:

```text
Accepted XPC Connection
Failed to Decode XPC Message: NSCocoaErrorDomain (4865) <private>
```

Interpretation: the normal Mach service is reachable, but a local module/type
name mirror of `Wallpaper.AgentXPCMessage` does not satisfy the private
Swift/XPC envelope expected by `AgentListener`. This keeps
`ensureViewModelIsUpToDate` blocked on the exact normal-agent envelope and
security policy; it does not disprove the redraw API itself.

### Supporting Enums

Recovered supporting enum detail:

| Type | Recovered cases or values | Evidence |
| --- | --- | --- |
| `ViewModelRefreshReason` | `launch`, `navigation`, `wallpaperInstallation` | Exported case constructor symbols in `Wallpaper.tbd`. |
| `ContentType` | `desktop`, `screenSaver`; byte values `desktop = 0`, `screenSaver = 1` | Exported as `Codable`, `CaseIterable`, `CustomStringConvertible`, with `allCases`, `description`, `init(from:)`, and `encode(to:)`. Swift field metadata descriptors contain the two case names. `WallpaperDisplayAttributes.desktop` stores zero; `WallpaperDisplayAttributes.screenSaver` stores one. `ContentType.description` compares against `1` and returns `desktop` or `screenSaver`. |
| `AssertionValue` | cases not recovered | Exported as `Codable`, `Hashable`, `Equatable`, and `CustomStringConvertible`, with `description`, `init(from:)`, and `encode(to:)`. No case constructors or raw values were recovered from the SDK stub, agent imports, or dyld-cache string windows. |
| `AssertionPresentationMode` | raw type `String`; concrete raw values not recovered | `init(rawValue:)`, `rawValue`, `RawRepresentable`, and `Codable` are exported, but no raw string constants were recovered from the current static evidence. |
| `WallpaperTypes.WallpaperSettingsViewModel.ContentType` | raw type `Int`; cases not recovered | Exported as a separate settings-view-model enum with `init(rawValue:)` and `rawValue`; this is not enough to map it to `Wallpaper.ContentType`. |
| `WallpaperStoreContentType` | likely store/runtime categories: `running-assertions`, `extension`, `screenSaver`, `inProcess` | Recovered from `WallpaperAgent` string windows near `ContentDescriptor type=inprocess`, `ContentDescriptor type=screensaver`, and `ContentDescriptor type=extension`. This appears to be agent/store vocabulary, not the exported `Wallpaper.ContentType` enum. |

The private `Wallpaper` and `WallpaperTypes` Swift modules are not importable
from this SDK, even though their `.tbd` exports exist. Runtime queries such as
`ContentType.allCases` are therefore unavailable from a normal Swift client,
but `tools/inspect-wallpaper-swift-metadata.sh` recovers the case names and
byte values from dyld metadata and disassembly.

Keep these similarly named surfaces distinct:

- `Wallpaper.ContentType` is the normal-agent parameter type used by
  `ensureViewModelIsUpToDate(contentTypes:reason:sender:)`.
- `WallpaperTypes.WallpaperSettingsViewModel.ContentType` is a separate
  settings-model enum with `Int` raw values.
- `WallpaperStoreContentType` and `ContentDescriptor type=...` strings are
  agent/store/provider vocabulary observed in `WallpaperAgent`.
- Strings such as `idle`, `linked`, `DesktopCodingKeys`, and
  `ScreenSaverCodingKeys` are useful context for settings models and coding
  keys, but are separate from the now-recovered `Wallpaper.ContentType`
  `desktop` and `screenSaver` cases.

### Choice and Settings Payloads

Several normal-agent messages operate on `WallpaperTypes` payloads. These are
not direct redraw commands, but they are part of the userland-visible message
surface exposed by `AgentXPCMessage`.

Recovered `WallpaperChoiceRequest` cases:

| Case | Payload |
| --- | --- |
| `imageFolder` | `URL` |
| `screenSaver` | `WallpaperChoiceRequest.ScreenSaverParameters` |
| `photoLibraryAsset` | `String` |
| `photoLibraryPerson` | `String` |
| `photoLibraryCollection` | `String` |
| `color` | `CGColorRef` |
| `image` | `URL` |

`ScreenSaverParameters` currently exposes:

| Field | Type |
| --- | --- |
| `module` | `URL` |

Recovered `WallpaperChoiceRequestAdditionResult` cases:

| Case | Payload |
| --- | --- |
| `choice` | `WallpaperChoice.ID` |
| `group` | `(WallpaperSettingsGroup.ID, WallpaperChoice.ID)` |

Recovered `WallpaperSettingsViewModels` shape:

```swift
struct WallpaperSettingsViewModels: Codable, Equatable {
    let desktop: WallpaperSettingsViewModel?
    let screenSaver: WallpaperSettingsViewModel?
}
```

Recovered `WallpaperSettingsViewModel` fields:

| Field | Type |
| --- | --- |
| `groups` | `[WallpaperSettingsGroup]` |
| `refreshPolicy` | `WallpaperSettingsViewModel.RefreshPolicy` |
| `isModificationDisabled` | `Bool` |

Recovered `WallpaperSettingsViewModel.RefreshPolicy` cases:

| Case |
| --- |
| `default` |
| `discretionary` |

`WallpaperSettingsViewModel.ContentType` exists as an `Int` raw-value enum, but
its concrete cases were not recovered from the SDK stub.

Current static evidence does not prove that settings view-model content cases
share names or values with `Wallpaper.ContentType`.

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

Runtime probing showed that a local mirror type in the `SpelunkingKit` module
is not sufficient. The receiver returned XPC `_CodableError` with:

```text
Receiver didn't call reply(_) or handoffReply(_) before returning from the message handler for this sync IPC message
```

That matches the static decode-failure branch that returns before
`handoffReply`. A local SwiftPM target named `WallpaperTypes`, with mirrored
non-raw debug enums, produced messages that the receiver decoded successfully
on the current SIP-disabled boot.

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

The repository helper exposes all four cases. The read/query cases can be sent
directly:

```zsh
swift run spelunk wallpaper-agent debug-xpc-probe --request access-downloaded
swift run spelunk wallpaper-agent debug-xpc-probe --request access-all
swift run spelunk wallpaper-agent debug-xpc-probe --request download-state --asset-id <asset-id>
```

The asset mutation cases require explicit execution:

```zsh
swift run spelunk wallpaper-agent debug-xpc-probe --request download-asset --asset-id <asset-id> --execute
swift run spelunk wallpaper-agent debug-xpc-probe --request remove-asset --asset-id <asset-id> --execute
```

Without `--execute`, the CLI refuses before opening the XPC session or sending
the mutating `WallpaperDebugRequest`.

### Asset Type Enum

Recovered `WallpaperDebugAssetType` cases:

| Case | Meaning |
| --- | --- |
| `all` | Include all assets known to the extension. |
| `downloaded` | Include downloaded assets only. |

The enum is `Codable`, `Hashable`, and `Equatable`.

No `rawValue` symbols were recovered for `WallpaperDebugAssetType`; model it
as a normal synthesized `Codable` enum, not a raw-string enum.

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

### Receiver-Side Implementation Trace

Static disassembly of the x86_64 slice of `WallpaperAgent` gives a concrete
receiver flow for the debug service. Ghidra still timed out full analysis on
the Swift-heavy binary, but the post-script and narrow `otool` windows
recovered the relevant call sequence.

Imported-symbol evidence from the agent includes:

| Imported symbol | Meaning |
| --- | --- |
| `WallpaperTypes.WallpaperDebugService.getter` | The service name is supplied by `WallpaperTypes`, not only a raw string in the agent. |
| `WallpaperTypes.WallpaperDebugRequestMessage` metadata | The receiver knows the concrete request envelope type. |
| `WallpaperTypes.WallpaperDebugRequestMessage : Decodable` | The receiver decodes incoming XPC payloads as this envelope. |
| `WallpaperTypes.WallpaperDebugRequestMessage.extensionIdentifier` | The receiver reads the target extension identifier from the decoded envelope. |
| `WallpaperTypes.WallpaperDebugRequestMessage.request` | The receiver reads the debug request enum from the decoded envelope. |
| `WallpaperTypes.WallpaperDebugRequest` metadata | The async path allocates storage for the request enum. |
| `WallpaperTypes.WallpaperDebugResponse` metadata | The async path allocates storage for the response enum. |
| `WallpaperTypes.WallpaperDebugResponse : Encodable` | The receiver replies with an encodable debug response. |
| `WallpaperExtensionKit.WallpaperExtensionProxy.handleDebugRequest` | The extension-side forwarding primitive is linked into the agent. |
| `XPC.XPCListener` and `IncomingSessionRequest.accept` | The debug service uses Swift XPC listener/session handling. |
| `XPC.XPCReceivedMessage.decode(as:)` | Incoming messages are decoded as Swift `Decodable` payloads. |
| `XPC.XPCReceivedMessage.handoffReply(to:_:)` | The receiver hands reply work off asynchronously. |
| `XPC.XPCReceivedMessage.reply(_:)` | The receiver sends the final encoded response on the original XPC message. |

The key x86_64 receiver window starts at `0x10009b455`:

1. Load `XPCReceivedMessage` metadata.
2. Load `WallpaperDebugRequestMessage` metadata.
3. Load the `WallpaperDebugRequestMessage : Decodable` conformance.
4. Call `XPCReceivedMessage.decode(as:)`.
5. On decode failure, release the Swift error and return without entering the
   extension-dispatch path.
6. On decode success, retain the decoded message and original received
   message, allocate a reply context, and call `handoffReply(to:_:)`.
7. The async continuation allocates `WallpaperDebugRequest` and
   `WallpaperDebugResponse` task storage.
8. The continuation calls `WallpaperDebugRequestMessage.request` and
   `WallpaperDebugRequestMessage.extensionIdentifier`.
9. The continuation dispatches with the recovered `(request,
   extensionIdentifier)` pair.
10. The response continuation loads `WallpaperDebugResponse` metadata plus its
    `Encodable` conformance and calls `XPCReceivedMessage.reply(_:)`.

The extension-dispatch path is now traced further in the x86_64 slice:

| Address | Evidence |
| --- | --- |
| `0x1001444d9` | Helper path loads `WallpaperTypes.WallpaperChoiceProviderID` metadata and iterates a dictionary-like collection at object offset `0x78`. This appears to resolve a requested extension/provider entry from `extensionIdentifier`. |
| `0x10014406e` | Reads a candidate extension/proxy object from the resolved entry. |
| `0x100144071` | Loads the imported async function pointer for `WallpaperExtensionProxy.handleDebugRequest`. |
| `0x1001440bc` | Tail-calls `WallpaperExtensionProxy.handleDebugRequest(WallpaperDebugRequest) async throws -> WallpaperDebugResponse`. |
| `0x100144151` | Loads `WallpaperDebugResponse.error(String)` for a failure branch using the literal `com.apple.wallpaper.extension`. |
| `0x1001442b3` | Builds an error string beginning with `No valid extension`. |
| `0x100144340` | Loads `WallpaperDebugResponse.error(String)` for the `No valid extension` path. |

The agent string table also contains the prefix `Unable to handle request:`.
It sits next to the extension-error literals and likely belongs to the
thrown-error/logging path around failed debug request handling, but the exact
string composition was not fully decompiled in this slice.

This proves the receiver is not expecting a bare dictionary or a method-name
selector. It expects a Swift/XPC message whose body decodes exactly as
`WallpaperDebugRequestMessage` and whose reply encodes exactly as
`WallpaperDebugResponse`.

The trace did not recover a separate debug-service authorization check. That
absence is not proof of open access: Swift XPC listener setup, ExtensionKit
host policy, sandbox policy, or framework-level checks may still reject an
ordinary client before or during dispatch. Treat ordinary-client access as
unproven until a SIP-enabled runtime probe succeeds.

Shared-cache strings name `AllowAllXPCSecurityPolicy`,
`EntitlementXPCSecurityPolicy`, `AgentXPCSecurityPolicy`, and
`WallpaperXPCConnectionSecurityPolicy`, while the normal service explicitly
exports `AgentXPCSecurityPolicy.checkAccess(message:for:)`. Current static
evidence does not prove that any of those policies is attached to
`WallpaperDebugServer`.

### Runtime Probe Results

The current SwiftPM probe sends read-only debug messages with a local module
named `WallpaperTypes`:

```zsh
swift run spelunk wallpaper-agent debug-xpc-probe
swift run spelunk wallpaper-agent debug-xpc-probe \
  --extension com.apple.wallpaper.extension.not-real
swift run spelunk wallpaper-agent debug-xpc-probe \
  --request download-state \
  --asset-id 4C108785-A7BA-422E-9C79-B0129F1D5550
```

Current observed results on macOS 26.5.2 build 25F84:

| Probe | Decoded response |
| --- | --- |
| `accessAllAssets(downloaded)` against `com.apple.wallpaper.extension.aerials` | `allAssets(count: 2)`: `Tahoe Day`, `Mac Purple` |
| `accessAllAssets(downloaded)` against `com.apple.wallpaper.extension.not-real` | `error(No valid extension)` |
| `downloadAssetState(4C108785-A7BA-422E-9C79-B0129F1D5550)` against Aerials | `downloadState(... progress: 1.0, isDownloaded: true)` |

Recent unified-log evidence from the same boot shows `WallpaperAgent` accepting
debug-service peer connections and dispatching to the extension bridge:

```text
activating connection: ... name=com.apple.wallpaper.debug.service.peer[...]
BEGIN - [com.apple.wallpaper.extension.aerials] handleDebugRequest
END - [com.apple.wallpaper.extension.aerials] handleDebugRequest
invalidated because the client process ... cancelled the connection or exited
```

These calls prove the ordinary-user wire shape and debug receiver dispatch on
this boot. They do not prove SIP-enabled access because `csrutil status`
reported `System Integrity Protection status: disabled.` during the probe.
The exact same commands need to be rerun on a SIP-enabled boot before checking
off the SIP-enabled access requirement.

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

The agent binary also contains the provider string
`com.apple.wallpaper.extension.photos`, but this filesystem inventory did not
find a matching ExtensionKit bundle on the current OS image. Treat it as an
agent-known provider identifier until a concrete bundle or runtime registration
is found.

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
| Private `ensureViewModelIsUpToDate` | Send normal `AgentXPCMessage.ensureViewModelIsUpToDate([ContentType], ViewModelRefreshReason)` to `com.apple.wallpaper`. | Mach lookup is visible, but the local `Wallpaper.AgentXPCMessage` mirror fails decode with `NSCocoaErrorDomain (4865)`. | Private protocol, may be entitlement-gated. | Best private redraw candidate, envelope still blocked |
| Private `snapshotAllSpaces` | Send normal diagnostic request to `com.apple.wallpaper`. | Local no-payload mirror reaches the service but fails decode and returns an empty reply. | Could be diagnostic-only. | Useful probe, not a redraw primitive |
| Private debug asset service | Send `WallpaperDebugRequestMessage` to `com.apple.wallpaper.debug.service`. | Wire shape and read-only handler access are proven on this SIP-disabled boot. Needs identical proof on a SIP-enabled boot. | Asset mutations possible if using `downloadAsset` or `removeAsset`; current helper exposes only read/query requests. No generic redraw vocabulary. | Useful debug API surface, not a redraw candidate |
| Wallpaper controls widget | Use `com.apple.wallpaper.agent.controls` / metadata action `SkipShuffledContentAction`. | WidgetKit/App Intents metadata is discoverable; action title is `Skip Wallpaper`, `openAppWhenRun=false`, no parameters. Invocation path still needs controlled proof. | Only advances shuffled wallpaper content. | Narrow shuffle hook only |
| Wallpaper App Intents | Use `SetWallpaperIntent` or `SetWallpaperPhotoIntent`. | App Intents metadata is discoverable; actions are titled `Set Wallpaper` and `Set Wallpaper Photo`, both `openAppWhenRun=false`. Invocation path still needs controlled proof. | Changes wallpaper choices rather than refreshing the current runtime in place. | Automation surface, not reset |
| Wallpaper Settings Intents | Use `WallpaperSettingsIntents` deep links, reads, or update actions. | Metadata exposes `OpenWallpaperDeepLinks`, `ScreenSaverNameIntent`, and four Settings property update actions. | Opens Settings or mutates screen-saver/wallpaper Settings booleans. | Settings automation, not reset |
| Export daemon | Call `com.apple.wallpaper.export`. | Service is discoverable, but protocol uses `com.apple.private.wallpaper.export`. | Entitlement-gated and state-mutating export/preboot path. | Not a redraw candidate |
| Settings helper XPC | Call `WallpaperHelper.xpc` / `removeWallpaperFiles:`. | XPC bundle is discoverable. Authorization and callers are not mapped. | Wallpaper file removal, not redraw. | Cleanup surface only |
| Diagnostic extension | Invoke `WallpaperDiagnosticExtension.appex`. | Diagnostic extension metadata is discoverable. | Evidence collection only. | Not a redraw candidate |
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

The repository helper now has a proof-oriented version of this experiment:

```zsh
swift run spelunk wallpaper-agent restart-probe-plan
swift run spelunk wallpaper-agent restart-probe --execute --signal TERM
swift run spelunk wallpaper-agent launchctl-kill-plan --signal TERM
swift run spelunk wallpaper-agent launchctl-kill --execute --signal TERM
```

The plan form is non-mutating and records the current target pid. The execute
form sends the selected same-user POSIX signal, polls for a replacement
`WallpaperAgent` pid for five seconds, and reports whether respawn was
observed. It still needs to be run on a SIP-enabled boot before it can be
promoted from candidate to proven restart path.

The `launchctl-kill-plan` form is also non-mutating. On this boot it planned:

```text
/bin/launchctl kill SIGTERM gui/501/com.apple.wallpaper.agent
```

The execute form asks launchd to deliver the selected signal to the user
bootstrap service target, then records the launchctl exit status, stdout,
stderr, after-pids, and whether a new `WallpaperAgent` pid appeared. It is a
separate candidate from direct POSIX signaling and still needs SIP-enabled
runtime proof before promotion.

Use the log snapshot immediately before and after the execute form to capture
relaunch, reload, generation, runtime, or snapshot evidence:

```zsh
swift run spelunk wallpaper-agent log-snapshot --last 10m --limit 80
```

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

The repository helper now has a proof-oriented version of this experiment:

```zsh
swift run spelunk wallpaper-agent redraw-probe-plan
swift run spelunk wallpaper-agent redraw-probe --execute
```

The plan form is non-mutating and records each screen's current desktop image
URL plus option keys. The execute form reapplies the same image URL and options,
then reads `NSWorkspace` state again and reports whether the image URL was
preserved. It still needs a SIP-enabled boot and a moment where visible desktop
mutation is acceptable before this can be promoted from candidate to proven
redraw path.

Use the same log snapshot command around the execute form to capture any
`WallpaperAgent` reload, generation, runtime rebuild, or snapshot invalidation
messages.

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
- `.desktop` content type only
- `.screenSaver` content type only

The current blocker is not service visibility. It is exact private
Swift/XPC encoding plus `AgentXPCSecurityPolicy`. A local SwiftPM module named
`Wallpaper` with mirrored `AgentXPCMessage`, `ContentType`, and
`ViewModelRefreshReason` cases is not sufficient by itself: the agent logs
`Failed to Decode XPC Message: NSCocoaErrorDomain (4865)` for the current
normal-probe envelope.

## Accessibility From Userland With SIP Enabled

Accessible or likely accessible:

- Process discovery for the same user's `WallpaperAgent`
- Same-user process signaling, pending SIP-enabled proof
- Same-user `launchctl kill` against
  `gui/<uid>/com.apple.wallpaper.agent`, pending SIP-enabled proof
- Mach lookup attempts for `com.apple.wallpaper`
- Mach lookup attempts for `com.apple.wallpaper.debug.service`
- Read-only `WallpaperDebugRequestMessage` calls to
  `com.apple.wallpaper.debug.service`, proven on this SIP-disabled boot and
  pending SIP-enabled rerun
- Read-only discovery of `com.apple.wallpaper.export`,
  `WallpaperHelper.xpc`, `WallpaperDiagnosticExtension.appex`, bundled
  WallpaperAgent plug-ins, and ExtensionKit wallpaper providers
- Public `NSWorkspace` desktop picture APIs
- App Intents / WidgetKit surfaces declared by WallpaperAgent plug-ins,
  pending controlled invocation proof
- App Intents / WidgetKit surfaces declared by
  `WallpaperSettingsIntents.appex`, pending controlled invocation proof
- Read-only inspection of launchd job state with `launchctl print`
- Unified log reads permitted to the current user

Not accessible or not assumed accessible:

- Task attachment to `WallpaperAgent`
- Code injection into `WallpaperAgent`
- Unsigned or non-Apple private entitlement acquisition
- Calling `com.apple.wallpaper.export` successfully without
  `com.apple.private.wallpaper.export`
- Receiver-side tracing that requires task port access
- `launchctl kickstart -k` as a reset mechanism
- Calling normal-agent private messages without solving the Swift/XPC envelope
  and security policy

## Next Experiments

1. Reboot or move to a SIP-enabled runtime, then run
   `swift run spelunk wallpaper-agent sip-validation-report` and preserve the
   complete output.
2. Run a controlled public AppKit redraw probe that reapplies the same static
   desktop image on each screen.
3. Run a controlled same-user `SIGTERM` respawn probe outside active desktop
   work, with pid before/after, launchd state, and log evidence.
4. Deepen the remaining `WallpaperDebugServer` implementation trace:
   - identify any listener/session-level audit-token or code-signing checks
   - decompile the exact string composition for `No valid extension` and
     `Unable to handle request:`
5. Deepen normal-agent Swift/XPC envelope reconstruction now that
   `Wallpaper.ContentType` cases are recovered.
6. Recover `AssertionValue` cases and presentation-mode raw strings.
7. Extend the Swift helper to encode private Swift/XPC messages only after the
   exact metadata identity is solved.

## References

- Raw command inventory: `../../../research/WallpaperAgent/README.md`
- SDK and receiver-import symbol helper:
  `../../../tools/extract-wallpaper-symbols.sh`
- Receiver disassembly-window helper:
  `../../../tools/inspect-wallpaper-debug-receiver.sh`
- Supporting enum/security helper:
  `../../../tools/inspect-wallpaper-supporting-types.sh`
- Ghidra string and symbol xref helper:
  `../../../tools/ghidra/DumpWallpaperDebugReferences.java`
- LaunchAgent: `/System/Library/LaunchAgents/com.apple.wallpaper.plist`
- Agent binary: `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent`
- SDK stubs:
  - `System/Library/PrivateFrameworks/Wallpaper.framework/Versions/A/Wallpaper.tbd`
  - `System/Library/PrivateFrameworks/WallpaperTypes.framework/Versions/A/WallpaperTypes.tbd`
  - `System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit.tbd`
