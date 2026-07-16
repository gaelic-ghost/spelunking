# MediaRemote Routes and Output Devices

## Scope

This note captures route, endpoint, and output-device symbols. These are mostly read/write surfaces, so treat them as documentation targets first and experiment targets only behind explicit flags.

## Runtime Probe

`mr-route-probe` is the current read-oriented helper for endpoint and output-device boundary checks.

Default command:

```sh
swift run mr-route-probe
```

Observed result from capture `research/MediaRemote/experiments/daemon-observation/20260716T092126Z`:

```text
MediaRemote read-only route/output-device probe
Local endpoint endpoint: <MRAVLocalEndpoint>
Local endpoint localizedName:
Local endpoint uid: LOCAL
Local endpoint output devices: skipped; pass --output-devices to copy endpoint output devices
Output context probe: skipped; pass --contexts to query shared output contexts
```

The helper deliberately keeps output-device copying and shared output-context lookups behind explicit flags:

- `--output-devices`: calls `MRAVEndpointCopyOutputDevices` and read-only getters for returned devices.
- `--contexts`: calls shared output-context getters and `MRAVOutputContextCopyOutputDevices`.
- `--describe`: prints Objective-C `description` for route objects, which can trigger additional lazy state reads.

Important boundary: even the default endpoint-identity run is not purely local. With `MRXPCTraceInterpose` injected, the run observed these XPC message IDs before printing the local endpoint:

| Message Type | Known Meaning | Observed Log Context |
| --- | --- | --- |
| `0x0200000000000018` | resolve player path | local endpoint setup side path |
| `0x0100000000000004` | get media playback volume | `mediaPlaybackVolume` request |
| `0x0300000000000004` | get picked route volume control capabilities | `volumeControlCapabilities` request |
| `0x0100000000000008` | not mapped by static call-site extraction yet | `getSystemIsMuted` request by process log context |

`mediaremoted` also added and removed the route probe as an `entitlements=0` client in the same capture window. No route-selection, output-device mutation, or volume mutation was requested by the helper.

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
