# MediaRemote Routes and Output Devices

## Scope

This note captures route, endpoint, and output-device symbols. These are mostly read/write surfaces, so treat them as documentation targets first and experiment targets only behind explicit flags.

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
