# WallpaperAgent and the Debug XPC Service

## Scope

This is private, local-only research into the Aqua-session `WallpaperAgent`,
its `com.apple.wallpaper.debug.service` Mach service, and a non-public redraw
or restart mechanism that can work from userland with SIP enabled. It is not a
public API, a distribution recommendation, or an App Store path.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5.2 (25F84) |
| Installed Xcode | 27.0 (27A5218g) |
| Wallpaper build | `WallpaperMac-245.4.8` |
| Process | `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent` |
| Job | `gui/<uid>/com.apple.wallpaper.agent` |
| Shared-cache source | `dyld_shared_cache_arm64e.05` |
| SIP at runtime verification | enabled (retested 2026-07-16) |

## Evidence Inventory

- [x] LaunchAgent declaration and live job state
- [x] Mach service inventory
- [x] Agent signing and entitlement inventory
- [x] Imported private frameworks
- [x] Agent strings, Swift metadata sections, and Objective-C names
- [x] Wallpaper, WallpaperTypes, and WallpaperExtensionKit shared-cache strings
- [x] Debug request/response vocabulary and adjacent XPC protocol metadata
- [x] Typed Swift-XPC envelope for the debug request
- [x] Ordinary current-user access to the debug listener with SIP disabled
- [x] Current-user `SIGTERM` restart operation with SIP enabled
- [x] SIP-enabled `launchctl kickstart -k` denial captured
- [ ] A non-disruptive redraw request proven from an ordinary SIP-enabled client

## Service Ownership and Lifecycle

`/System/Library/LaunchAgents/com.apple.wallpaper.plist` defines the job as
`com.apple.wallpaper.agent`, limited to the Aqua session. The live job exposes
four managed Mach endpoints:

- `com.apple.wallpaper`
- `com.apple.wallpaper.debug.service`
- `com.apple.wallpaper.CacheDelete`
- `com.apple.usernotifications.delegate.com.apple.wallpaper.notifications.sonoma-first-run`

`launchctl print` confirms that the current user's job owns the first and
second endpoints. This proves the bootstrap namespace and label only.

The fully-qualified service target is essential:

```zsh
launchctl kickstart -kp "gui/$(id -u)/com.apple.wallpaper.agent"
```

Using only `com.apple.wallpaper.agent` fails with launchctl usage error 64;
that is target parsing, not a permission denial. With SIP enabled, the
fully-qualified `kickstart -kp` command fails with exit code 150 and
`Operation not permitted while System Integrity Protection is engaged`.
With SIP disabled, the same fully-qualified command cleanly restarted the
agent and launchd recorded a `SIGTERM` termination.

The verified restart primitive is:

```zsh
tools/restart-wallpaper-agent.sh
```

It obtains the current session's agent PID, sends `SIGTERM`, and waits for
launchd to publish a replacement PID. In the live verification, PID `87092`
became `90265`, the job run count increased from `2` to `3`, and launchd
recorded `last terminating signal = Terminated: 15` with no crash count added.
This was retested with SIP enabled: PID `632` became `9524`, launchd's run
count increased from `1` to `2`, and it recorded `last terminating signal =
Terminated: 15`. It uses ordinary same-user POSIX signalling and the agent's
existing LaunchAgent keep-alive policy; it does not require private
entitlements or injection.

The launchd policy includes `KeepAlive.SuccessfulExit = false`. The restart
does visibly interrupt and rebuild the desktop wallpaper path, so do not run
it during a presentation or other stability-sensitive desktop use.

Do not use `SIGUSR1` as a substitute. The agent imports it for an `os_state`
diagnostic source, but on this build the test ended in `Abort trap: 6` and
launchd recovered it as a successive crash. It is neither a clean restart nor
a redraw interface.

## Agent Boundary

The agent is Apple-signed, sandboxed, and carries private wallpaper,
SkyLight-desktop-effects, Dock-spaces, CacheDelete, extension-host, TCC, and
RunningBoard entitlements. Its dynamic dependencies include `Wallpaper`,
`WallpaperFoundation`, `WallpaperTypes`, `WallpaperExtensionKit`, `SkyLight`,
and Swift XPC. Those privileges explain why an ordinary client cannot assume
it can invoke every request it discovers.

The normal service accepts a connection, but prior typed request probes logged
`Failed to Decode XPC Message: NSCocoaErrorDomain (4865)`. The active blocker
was the message shape, not basic Mach-service reachability. The debug request
now decodes successfully from a reconstructed `Codable` mirror; the top-level
private Swift type identity is not encoded as an access-control requirement.
This observation was made with SIP disabled.

## Normal Agent Protocol

The `Wallpaper` shared-cache image identifies `AgentXPCProtocol`,
`AgentXPCMessage`, and `AgentXPCSender`. Its named request coders enumerate
the normal agent surface:

- assertions: `takeAssertion`, `releaseAssertion`, `setAssertions`
- diagnostics: `diagnosticState`, `snapshotAllSpaces`
- view and configuration updates: settings, display-space, legacy desktop,
  cache, override, observer, download, choice, and shuffle operations
- synchronization: `ensureViewModelIsUpToDate`, `skipShuffledContent`, and
  `canSkipShuffledContent`

The agent binary itself contains the matching handler names
`snapshotAllSpaces(sender:)`, `diagnosticState(sender:)`,
`setAssertions(_:sender:)`, `releaseAssertion(id:sender:)`, and
`takeAssertion(id:value:sender:)`. Ghidra's Swift protocol references recover
the two diagnostic signatures exactly:

```swift
func diagnosticState(sender: WallpaperXPCRemoteProcess?) async throws -> Data
func snapshotAllSpaces(sender: WallpaperXPCRemoteProcess?) async throws -> [AnnotatedSnapshot]
```

The assertion operations' exact parameters, all coding keys, and the
authorization predicates still need metadata extraction or a receiver-side
trace.

## Debug XPC Reverse-Engineering Map

### Transport and routing

`com.apple.wallpaper.debug.service` is explicitly registered by the same Aqua
LaunchAgent as the normal service. The `WallpaperTypes` image contains the
service name and `WallpaperDebugRequestMessage`; the agent contains
`WallpaperDebugServer` (a class with a `listener` field) and
`WallpaperDebugRequestHandler`; and
`WallpaperExtensionKit` contains `WallpaperExtensionDebugHandler` plus the
Objective-C XPC operation `handleDebugRequest:reply:`. Together, these facts
support the following routing model:

1. A client sends a private `WallpaperDebugRequestMessage` to the debug Mach
   service.
2. `WallpaperDebugServer` decodes it and selects a wallpaper extension using
   its extension identifier.
3. The agent forwards a bridged debug request to that extension's exported
   `WallpaperExtensionDebugHandler` over a separate NSXPC connection.
4. The extension returns a debug response, which the agent sends back to the
   original client.

Steps 1 and 4 are inferred from co-located names and the previous decode
failure; steps 2 and 3 are strongly inferred from the handler names and the
extension protocol. They are not yet runtime-traced.

### Request and response vocabulary

The `WallpaperTypes` reflection strings establish these private types:

| Type | Verified fields or variants | Confidence |
| --- | --- | --- |
| `WallpaperDebugRequestMessage` | `extensionIdentifier`, `request` | verified string evidence |
| `WallpaperDebugRequest` | `accessAllAssets`, `downloadAsset`, `downloadAssetState`, `removeAsset` | verified Swift reflection field metadata |
| `WallpaperDebugResponse` | `error`, `allAssets`, `downloadState`, `success` | verified Swift reflection field metadata |
| `WallpaperDebugAssetType` | `all`, `downloaded` | verified Swift reflection field metadata |
| `WallpaperAssetList` | `assets` | verified Swift reflection field metadata |
| `WallpaperAssetList.Asset` | `name`, `id`, `isDownloaded` | verified Swift reflection field metadata |
| `WallpaperAssetDownloadState` | `assetID`, `progress`, `isDownloaded` | verified Swift reflection field metadata |

The request's download and removal variants use an `assetID` payload. The
response model has the matching asset-list and download-state payload types.
That payload association is supported by the generated coding-key families and
by the reflection records, but the associated-value labels still require the
private type descriptor or a captured message to be called exact Swift API.

### Wire envelope and live probe

Swift XPC wraps a typed `Codable` request in an XPC dictionary containing:

- `_CodableBody`: the binary Codable payload
- `_CodableCoderVersion`: `1`
- `_CodableIsSync`: the request's sync flag
- `_CodableOutOfLine`: an array for out-of-line values
- `_CodableOutOfLine4CodableObject`: an array for Codable object references

`xpc-wire-format` reproduces that envelope locally, then sends the mirrored
`WallpaperDebugRequestMessage` over `XPCSession(machService:)`. On this
machine, the ordinary current user successfully sent
`accessAllAssets(.all)` for `com.apple.wallpaper.extension.aerials` to
`com.apple.wallpaper.debug.service`; the listener decoded the request and
returned a message. This proves that the SIP-disabled environment does not
require a client entitlement for the listener's read-only decode path. It does
not establish the same result under SIP.

The built-in Aerials provider did not call `reply(_)` for that request. This
is consistent with the static finding that the service delegates to the
provider's optional `WallpaperExtensionDebugHandler`: WallpaperAgent owns the
transport, while each extension decides whether to implement a useful debug
response. The other built-in wallpaper extension binaries contain no direct
`handleDebugRequest` implementation strings, so they should not be assumed to
provide an asset-debug backend either.

`WallpaperExtensionKit` also has `WallpaperDebugRequestXPC` and
`WallpaperDebugResponseXPC`, so the agent-to-extension hop is not necessarily
the same Codable representation as the client-to-agent Swift-XPC message.

### What it is not

Nothing in the recovered debug vocabulary indicates a generic redraw, restart,
or desktop-layer invalidation request. The service is best understood as an
asset-management debugging tunnel for a wallpaper extension, not a known
general-purpose agent-control service. It should not be used as the proposed
SIP-enabled redraw path until a specific request is proven.

## Runtime Redraw Candidates

The agent binary does contain an internal rendering refresh chain:

`handleGenerationChange` -> `invalidateSnapshots` -> `updateRuntimeState` ->
`REBUILD: Update Runtime` / `REBUILD: Resolve Runtime`.

It also logs `Request reload due to wallpaper runtime change`. This is proof
that redraw/rebuild behavior exists internally, not proof of an external
trigger. The normal-agent operation `ensureViewModelIsUpToDate` is the closest
named external candidate, but its private envelope and authorization policy
remain unproven.

The `com.apple.wallpaper.skip` control is unrelated: the built-in Wallpaper
Controls widget uses it only to advance a shuffled collection.

## Permissions and Entitlements

SIP does not grant an arbitrary client the agent's private entitlements, nor
does it supply private Swift type metadata. The earlier ordinary-client decode
error and an interrupted debug-service connection are consistent with that
boundary. SIP does block launchctl's managed `kickstart -k` operation for this
system-owned LaunchAgent, but it does not block a same-user `SIGTERM` restart.

## Experiments

1. Extract the exact `WallpaperDebugRequestMessage` metadata from the shared
   cache and decode its `Codable` keys and enum discriminators.
2. Use the Ghidra cross-reference script to locate `WallpaperDebugServer`'s
   receiver, its authorization checks, and the message decoder call site. The
   script is validated against the agent binary and currently locates the
   server metadata plus the two diagnostic protocol requirements.
3. Capture a receiver-side trace while Apple wallpaper settings performs a
   debug-asset action. This requires an explicit decision about introspection
   permissions; do not weaken SIP just to retry guessed payloads.
4. Determine whether a SIP-enabled redraw can be initiated without process
   termination. The restart boundary is now verified: `launchctl kickstart
   -k` is denied, whereas same-user `SIGTERM` is accepted and respawned.

## Open Questions

- Which built-in or third-party development wallpaper providers implement a
  reply-producing `WallpaperExtensionDebugHandler`?
- What exact associated-value labels does Apple use for the request and
  response enums? The payload types and fields are recovered, but Swift's
  synthesized labels are not part of the reflection records.
- Can `ensureViewModelIsUpToDate` produce an observable redraw without
  modifying wallpaper state?
- Is there an externally reachable notification or store-generation change
  that safely invokes the internal `invalidateSnapshots` chain?

## References

- `research/WallpaperAgent/README.md` for repeatable local capture commands
- `tools/extract-wallpaper-types-metadata.py` for the repeatable reflection
  metadata decoder
- `Sources/xpc-wire-format/XPCWireFormatMain.swift` for the local envelope and
  read-only live-probe harness
- `tools/ghidra/DumpWallpaperDebugReferences.java` for static cross references
- `/System/Library/LaunchAgents/com.apple.wallpaper.plist`
- `/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent`
- `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05`
