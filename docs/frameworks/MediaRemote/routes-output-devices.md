# MediaRemote Routes and Output Devices

## Scope

This note captures route, endpoint, and output-device symbols. These are mostly read/write surfaces, so treat them as documentation targets first and experiment targets only behind explicit flags.

## Runtime Probe

`mr-route-probe` is the current read-oriented helper for endpoint and output-device boundary checks.

Default command:

```sh
swift run mr-route-probe
```

Observed result from capture `research/MediaRemote/experiments/daemon-observation/20260716T092557Z`:

```text
MediaRemote read-only route/output-device probe
Local endpoint endpoint: <MRAVLocalEndpoint>
Local endpoint localizedName: skipped; pass --localized-name to call MRAVEndpointGetLocalizedName
Local endpoint uid: skipped; pass --uid to call MRAVEndpointGetUniqueIdentifier
Local endpoint output devices: skipped; pass --output-devices to copy endpoint output devices
Output context probe: skipped; pass --contexts to query shared output contexts
```

The helper deliberately keeps endpoint identity getters, output-device copying, and shared output-context lookups behind explicit flags:

- `--routing-context <uid>`: passes a routing-context UID to `MRAVEndpointGetLocalEndpoint`; by default the helper passes `NULL`.
- `--localized-name`: calls `MRAVEndpointGetLocalizedName`.
- `--uid`: calls `MRAVEndpointGetUniqueIdentifier`.
- `--endpoint-details`: calls both endpoint identity getters.
- `--output-devices`: calls `MRAVEndpointCopyOutputDevices` and read-only getters for returned devices.
- `--contexts`: calls shared output-context getters and `MRAVOutputContextCopyOutputDevices`.
- `--describe`: prints Objective-C `description` for route objects, which can trigger additional lazy state reads.

Important boundary: even the class-only local endpoint run is not purely local. Capture `research/MediaRemote/experiments/daemon-observation/20260716T092557Z` skipped localized name, UID, output-device copying, shared contexts, and object descriptions, but still observed these XPC message IDs before printing the local endpoint:

| Message Type | Known Meaning | Observed Log Context |
| --- | --- | --- |
| `0x0200000000000018` | resolve player path | local endpoint setup side path |
| `0x0100000000000004` | get media playback volume | `mediaPlaybackVolume` request |
| `0x0300000000000004` | get picked route volume control capabilities | `volumeControlCapabilities` request |
| `0x0100000000000008` | not mapped by static call-site extraction yet | `getSystemIsMuted` request by process log context |

`mediaremoted` also added and removed the route probe as an `entitlements=0` client in the same capture window. No route-selection, output-device mutation, or volume mutation was requested by the helper.

Getter isolation:

| Capture | Flags | Probe Result | Added Message IDs |
| --- | --- | --- | --- |
| `20260716T092557Z` | none | endpoint class only | baseline set above |
| `20260716T092614Z` | `--localized-name` | localized name returned empty string | none beyond baseline |
| `20260716T092620Z` | `--uid` | UID returned `LOCAL` | none beyond baseline |
| `20260716T092638Z` | `--output-devices` | `MRAVEndpointCopyOutputDevices` returned zero devices | none beyond baseline |
| `20260716T092644Z` | `--contexts` | shared system audio and screen contexts returned nil | none beyond baseline |

Interpretation: on this macOS 26.5.2 run, the first `MRAVEndpointGetLocalEndpoint(NULL)` call is enough to hydrate MediaRemote route/volume state. The endpoint localized-name, UID, output-device, and shared-context reads did not add distinct XPC message IDs in these captures.

Routing-context isolation:

| Capture | Flags | Probe Result | Added Message IDs |
| --- | --- | --- | --- |
| `20260716T093257Z` | none | endpoint class only with `NULL` routing context | baseline set above |
| `20260716T093305Z` | `--routing-context LOCAL` | endpoint class only with explicit `LOCAL` routing context | none beyond baseline |
| `20260716T093325Z` | `--routing-context SPK-SYNTHETIC-ROUTING-CONTEXT` | endpoint class only with synthetic routing context | none beyond baseline |

Interpretation: the route/volume and `0x0200000000000018` now-playing side path is not specific to the `NULL` fallback or the `LOCAL` routing context. It appears during `MRAVLocalEndpoint` creation or cache hydration for any tested routing-context UID.

Static setup path from disassembly:

- `_MRAVEndpointGetLocalEndpoint` is a thin exported wrapper. It opens an autorelease pool and sends `+[MRAVLocalEndpoint sharedLocalEndpointForRoutingContextWithUID:]`.
- `+[MRAVLocalEndpoint sharedLocalEndpointForRoutingContextWithUID:]` derives a default UID from `MRAVOutputContext.sharedAudioPresentationContext.uniqueIdentifier` when passed `NULL`, then synchronously consults or updates a context-UID-to-local-endpoint map.
- The cache-miss block chooses an `MRAVConcreteOutputContext` for shared audio-presentation or shared system-audio contexts, otherwise calls `+[MRAVConcreteOutputContext createOutputContextWithUniqueIdentifier:]`.
- The block allocates `MRAVLocalEndpoint`, calls `-[MRAVLocalEndpoint initWithOutputContext:]`, and may attach an `MROutputContextController` for shared audio-presentation/system-audio contexts.
- `-[MRAVLocalEndpoint initWithOutputContext:]` calls the superclass initializer with the output context and `MRAVOutputDevice.localDeviceUID`, sets origin to `MROrigin.localOrigin`, then registers for `MRActiveGroupSessionInfoDidChangeNotification`.

Inference: the repeated `ConcreteOutputContext` warnings and identical XPC message set across `NULL`, `LOCAL`, and synthetic routing-context runs point at shared output-context/local-endpoint creation rather than endpoint detail getters. The exact internal call that sends `0x0200000000000018` was not recovered from the endpoint disassembly path; the immediate constructors for that ID remain `MRMediaRemoteService` player-path resolution wrappers documented in `message-id-map.md`.

## Endpoint Surface

Representative exported functions:

- `MRAVEndpointGetLocalEndpoint`
- `MRAVEndpointResolveActiveSystemEndpoint`
- `MRAVEndpointResolveActiveSystemEndpointWithTimeout`
- `MRAVEndpointResolveActiveSystemEndpointWithType`
- `MRAVEndpointResolveOutputDeviceUID`
- `MRAVEndpointResolveOutputDeviceUIDs`
- `MRAVEndpointCopyOutputDevices`
- `MRAVEndpointCopyPersonalOutputDevices`
- `MRAVEndpointGetUniqueIdentifier`
- `MRAVEndpointGetLocalizedName`
- `MRAVEndpointGetVolume`
- `MRAVEndpointGetVolumeControlCapabilities`
- `MRAVEndpointObserverCreateWithOutputDeviceUID`
- `MRAVEndpointObserverBegin`
- `MRAVEndpointObserverEnd`

Mutating endpoint functions include:

- `MRAVEndpointSetOutputDevices`
- `MRAVEndpointAddOutputDevices`
- `MRAVEndpointRemoveOutputDevices`
- `MRAVEndpointMoveOutputGroupToDevices`
- `MRAVEndpointSetVolume`
- `MRAVEndpointSetOutputDeviceVolume`
- `MRAVEndpointSetOutputDeviceUIDVolume`
- `MRAVEndpointUpdateActiveSystemEndpoint*`
- `MRAVEndpointMigrate`

Notifications:

- `MRAVEndpointDidConnectNotification`
- `MRAVEndpointDidDisconnectNotification`
- `MRAVEndpointOutputDevicesDidChangeNotification`
- `MRAVEndpointVolumeDidChangeNotification`
- `MRAVEndpointVolumeMutedDidChangeNotification`
- `MRAVEndpointVolumeControlCapabilitiesDidChangeNotification`
- `MRAVEndpointGroupSessionInfoDidChangeNotification`
- `MRAVEndpointGroupSessionHostingEligibilityDidChangeNotification`

## Output Context Surface

Representative exported functions:

- `MRAVOutputContextGetSharedSystemAudioContext`
- `MRAVOutputContextGetSharedSystemScreenContext`
- `MRAVOutputContextGetSharedAudioPresentationContext`
- `MRAVOutputContextCreateRoutingContext`
- `MRAVOutputContextCreateiTunesAudioContext`
- `MRAVOutputContextCopyOutputDevices`
- `MRAVOutputContextCopyPredictedOutputDevice`
- `MRAVOutputContextGetUniqueIdentifier`
- `MRAVOutputContextGetType`

Mutating output-context functions include:

- `MRAVOutputContextSetOutputDevice`
- `MRAVOutputContextSetOutputDeviceWithPassword`
- `MRAVOutputContextSetOutputDevices`
- `MRAVOutputContextAddOutputDevice`
- `MRAVOutputContextAddOutputDevices`
- `MRAVOutputContextRemoveOutputDevice`
- `MRAVOutputContextRemoveOutputDevices`
- `MRAVOutputContextRemoveAllDevices`
- `MRAVOutputContextResetPredictedOutputDevice`

Output-context modification notifications include begin/finish, will/did add, will/did remove, request-to-add/remove, output-device changes, local/personal device changes, and volume changes.

## Output Device Surface

Representative read functions:

- `MRAVOutputDeviceCreateLocalDevice`
- `MRAVOutputDeviceGetName`
- `MRAVOutputDeviceGetUniqueIdentifier`
- `MRAVOutputDeviceGetType`
- `MRAVOutputDeviceGetSubtype`
- `MRAVOutputDeviceGetModelID`
- `MRAVOutputDeviceGetBatteryLevel`
- `MRAVOutputDeviceGetEndpoint`
- `MRAVOutputDeviceCopyBluetoothID`
- `MRAVOutputDeviceCopyFirmwareVersion`
- `MRAVOutputDeviceCopyGroupIdentifier`
- `MRAVOutputDeviceCopyHeadTrackedSpatialAudioMode`
- `MRAVOutputDeviceIsLocalDevice`
- `MRAVOutputDeviceIsGroupLeader`
- `MRAVOutputDeviceIsGroupable`
- `MRAVOutputDeviceIsRemoteControllable`
- `MRAVOutputDeviceIsVolumeControlAvailable`
- `MRAVOutputDeviceSupportsRapport`
- `MRAVOutputDeviceSupportsHAP`
- `MRAVOutputDeviceSupportsHeadTrackedSpatialAudio`
- `MRAVOutputDeviceSupportsExternalScreen`

Mutation-capable functions include:

- `MRAVOutputDeviceSetCurrentBluetoothListeningMode`
- `MRAVOutputDeviceSetAllowsHeadTrackedSpatialAudio`
- `MRAVOutputDeviceSetRecentAVOutputDeviceUID`
- `MRAVOutputDeviceRemoveFromParentGroup`

## Discovery Surface

`MRAVRoutingDiscoverySession*` functions cover route discovery:

- create a discovery session
- set/get discovery mode
- set routing context UID
- set target audio session ID
- add/remove endpoints changed callbacks
- add/remove output devices changed callbacks
- copy available endpoints/output devices
- detect device presence

Inference: this may be the safest read-only route inventory path once signatures are confirmed, because it can observe available endpoints without immediately modifying route selection.

## Daemon Boundary

`mediaremoted` has `com.apple.avfoundation.allows-set-output-device`, CoreMedia route/volume mach lookups, AirPlay receiver services, Bluetooth services, and MediaRemote route-control entitlements.

Userland tooling in this repo should assume route mutation may fail, no-op, or require daemon mediation. Prefer endpoint discovery and output-device listing before any `Set*`, `Add*`, `Remove*`, or volume operation.

The runtime probe shows that even endpoint identity can hydrate route/volume state through daemon-backed requests. Treat default route probing as read-only but daemon-visible, not side-effect-free.
