# MediaRemote Symbols

## Exported Functions

Capture and classify exported functions from the active framework and beta SDK here.

Initial SDK stub counts:

| Surface | Xcode 26 SDK | Xcode 27 beta SDK |
| --- | ---: | ---: |
| `MediaRemote.tbd` | 3,906 | 3,954 |
| `MediaRemoteDaemonServices.tbd` | 3 | 3 |

Live dyld-cache counts:

| Surface | Count |
| --- | ---: |
| `MediaRemote` live exports | 5,131 |
| `MediaRemoteDaemonServices` live exports | 3 |

Notable Xcode 27 beta additions include:

- `_MRAVEndpointDidBecomeStaleNotification`
- `_MRAVEndpointResolveActiveSystemEndpointWithTypeReturningError`
- `_MRCreateNowPlayingSessionError`
- `_MRMediaRemoteGetLiveAppEntityDonationsEnabled`
- `_MRMediaRemoteRemoveCommandHandlerForPlayer`
- `_MRMediaRemoteRouteStatusErrorDomain`
- `_MRNowPlayingSessionErrorDomain`
- `_kMRMediaRemoteNowPlayingInfoAppEntityPaths`
- `_kMRMediaRemoteNowPlayingInfoContentType`
- `_kMRMediaRemoteNowPlayingInfoFetchableArtwork`
- `_kMRMediaRemoteNowPlayingInfoRemoteArtworkFormats`
- `_kMRMediaRemoteOptionPlaybackAccountID`
- `_kMRMediaRemotePushTokensDidChangeNotification`

## Objective-C Runtime Surface

`dyld_info -objc` cannot print live Objective-C metadata from dyld shared-cache dylibs, but exported symbols expose representative class names. `mr-interface-probe` now supplements that with selected loaded-runtime class metadata. See `live-dyld-cache.md` and `runtime-interfaces.md`.

## Constants and Notifications

Important notification and key families are now broken out in:

- `now-playing-architecture.md`
- `xpc-and-messages.md`
- `routes-output-devices.md`

High-signal families from the live export and string capture:

- now-playing application/client/player/origin APIs
- playback queue request and content item APIs
- command dispatch APIs
- endpoint/output-context/output-device APIs
- XPC serialization and message-key helpers
- route discovery session APIs
- group-session and handoff APIs

## Version Differences

Use this section to compare macOS 26.5 against the macOS 27 beta SDK.

Early SDK diff notes:

- Xcode 27 beta appears to add richer now-playing content/media typing and artwork-related keys.
- Xcode 27 beta adds route-status and now-playing-session error-domain symbols.
- Xcode 27 beta adds `_MRCreateArrayFromXPCMessage`; Xcode 26 exposes the likely misspelled `_MRCreateArrayFomXPCMessage`.
- Xcode 26 exposes `_MRLogCategoryDefault` and `_MRLogCategoryMirroringView`; those names were not present in the initial Xcode 27 beta stub diff.

## Safety Buckets

Read-only first:

- `MRMediaRemoteGetNowPlayingInfo*`
- `MRMediaRemoteGetNowPlayingClient*`
- `MRMediaRemoteGetNowPlayingPlayer*`
- `MRMediaRemoteRegisterForNowPlayingNotifications`
- `MRAVRoutingDiscoverySessionCopyAvailableEndpoints`
- `MRAVRoutingDiscoverySessionCopyAvailableOutputDevices`
- `MRAVEndpointCopyOutputDevices`
- `MRAVOutputContextCopyOutputDevices`
- `MRAVOutputDeviceGet*` and `Copy*`

Mutating or control-capable:

- `MRMediaRemoteSendCommand*`
- `MRMediaRemoteSetNowPlaying*`
- `MRMediaRemoteSetPlaybackState*`
- `MRMediaRemoteSetPlaybackQueue*`
- `MRMediaRemoteSetCanBeNowPlaying*`
- `MRMediaRemoteSetSupportedCommands*`
- `MRAVEndpointSet*`, `Add*`, `Remove*`, `Move*`, `Migrate`
- `MRAVOutputContextSet*`, `Add*`, `Remove*`, `RemoveAll*`

Do not wrap mutating functions in default tools until the relevant target identity, daemon boundary, and failure modes are documented.
