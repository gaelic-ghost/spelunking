# MediaRemote Live Dyld Cache

## Source

Live image path queried through `dyld_info`:

```sh
dyld_info -exports /System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote
```

`dyld_info` can inspect the install-name path even though the framework directory does not contain an ordinary `Versions/A/MediaRemote` file. Objective-C metadata cannot be printed through `dyld_info -objc` for this cached dylib; class names can still be observed through exported `_OBJC_CLASS_$_...` symbols.

## Export Counts

| Surface | Count |
| --- | ---: |
| Live `MediaRemote` exports | 5,131 |
| Live `MediaRemoteDaemonServices` exports | 3 |
| Xcode 26 `MediaRemote.tbd` names | 3,906 |
| Xcode 27 beta `MediaRemote.tbd` names | 3,954 |
| Xcode 26 `MediaRemoteDaemonServices.tbd` names | 3 |
| Xcode 27 beta `MediaRemoteDaemonServices.tbd` names | 3 |

Comparison counts:

| Comparison | Count |
| --- | ---: |
| Live-only versus Xcode 26 SDK | 2,565 |
| Live-only versus Xcode 27 beta SDK | 2,566 |
| Xcode 26 SDK-only versus live | 1,340 |
| Xcode 27 beta SDK-only versus live | 1,389 |

The large live-only count is mostly Objective-C class, metaclass, ivar, and internal protobuf/message surface that is present in the dyld cache export table but not represented in the same way in the SDK stub.

## Export Buckets

| Bucket | Live export count |
| --- | ---: |
| `MRMediaRemote*` | 478 |
| `kMRMediaRemote*` | 365 |
| `MRAVOutputDevice*` | 88 |
| `MRAVEndpoint*` | 83 |
| `MRPlaybackQueue*` | 82 |
| `MRNowPlaying*` | 79 |
| `MRAVOutputContext*` | 62 |
| `MRAV*` other | 47 |
| `MRRequestDetails*` | 19 |
| `MRD*` | 11 |
| `MROrigin*` | 8 |
| `NSStringFrom*` | 6 |
| `MRPlayer*` | 1 |
| `MRSendCommand*` | 1 |
| `MR*` other | 1,020 |
| `kMR*` other | 216 |
| Other exports, including Objective-C metadata symbols | 2,565 |

## Now-Playing Read Surface

Useful read-oriented live exports:

- `_MRMediaRemoteGetNowPlayingInfo`
- `_MRMediaRemoteGetNowPlayingInfoWithOptionalArtwork`
- `_MRMediaRemoteGetNowPlayingApplicationDisplayID`
- `_MRMediaRemoteGetNowPlayingApplicationDisplayName`
- `_MRMediaRemoteGetNowPlayingApplicationIsPlaying`
- `_MRMediaRemoteGetNowPlayingApplicationPID`
- `_MRMediaRemoteGetNowPlayingApplicationPlaybackState`
- `_MRMediaRemoteRegisterForNowPlayingNotifications`
- `_MRMediaRemoteSetWantsNowPlayingNotifications`
- `__MRMediaRemoteRegisterForNowPlayingNotificationsEx`

Useful now-playing dictionary keys:

- `_kMRMediaRemoteNowPlayingInfoTitle`
- `_kMRMediaRemoteNowPlayingInfoArtist`
- `_kMRMediaRemoteNowPlayingInfoAlbum`
- `_kMRMediaRemoteNowPlayingInfoDuration`
- `_kMRMediaRemoteNowPlayingInfoElapsedTime`
- `_kMRMediaRemoteNowPlayingInfoPlaybackRate`
- `_kMRMediaRemoteNowPlayingInfoArtworkData`
- `_kMRMediaRemoteNowPlayingInfoArtworkURL`
- `_kMRMediaRemoteNowPlayingInfoMediaType`

Safest first call path:

1. Dynamically load `MediaRemote.framework` with `dlopen`.
2. Resolve `_MRMediaRemoteGetNowPlayingInfo` with `dlsym`.
3. Call it with a private serial callback queue.
4. Print the returned dictionary without sending commands or registering as a player.

This path is implemented by the `mr-now-playing-probe` executable target.

Observed result without requiring Gale to change playback state:

```text
MediaRemote read-only now-playing probe
Symbol: MRMediaRemoteGetNowPlayingInfo
Result: callback returned nil dictionary
```

Interpretation: the function can be loaded and invoked from an ordinary local helper, but the current minimal call returned no now-playing dictionary. The next refinement should test with active playback and then, if still nil, add read-only notification subscription before fetching.

## Command and Mutation Surface

Command-related exports are rich and should stay out of the first probe path:

- `_MRMediaRemoteSendCommand`
- `_MRMediaRemoteSendCommandWithReply`
- `_MRMediaRemoteSendCommandToApp`
- `_MRMediaRemoteSendCommandToClient`
- `_MRMediaRemoteSendCommandToPlayer`
- `_MRMediaRemoteSendCommandToPlayerWithResult`
- `_MRMediaRemoteSetNowPlayingInfo`
- `_MRMediaRemoteSetNowPlayingInfoForPlayer`
- `_MRMediaRemoteSetPlaybackStateForClient`
- `_MRMediaRemoteSetPlaybackStateForPlayer`
- `_MRMediaRemoteSetSupportedCommands`
- `_MRMediaRemoteSetSupportedCommandsForPlayer`

Keep these for later mutating experiments only after the read-only state and permission boundaries are clearer.

## Routing and Output Surface

Routing and endpoint exports include:

- `MRAVEndpoint*`
- `MRAVOutputContext*`
- `MRAVOutputDevice*`
- `MRAVRoutingDiscoverySession*`
- `MRAVRouteQuery*`
- `MRAVReconnaissanceSession*`

The live surface includes read APIs such as copy/get endpoint, output-device, volume, route-query, and available-output-device functions, but it also includes mutating calls for setting routes, adding/removing devices, grouping, and volume changes. Start routing work with discovery-session and copy/get APIs only.

## Objective-C Surface From Exports

Representative exported class names:

- `MRMediaRemoteService`
- `MRMediaRemoteServiceClient`
- `MRNowPlayingController`
- `MRNowPlayingControllerConfiguration`
- `MRNowPlayingControllerDestination`
- `MRNowPlayingClient`
- `MRNowPlayingOriginClient`
- `MRNowPlayingPlayerClient`
- `MRNowPlayingRequest`
- `MRNowPlayingState`
- `MRNotificationClient`
- `MRNotificationServiceClient`
- `MRPlaybackQueue`
- `MRPlaybackQueueRequest`
- `MRPlaybackSession`
- `MRPlayer`
- `MRPlayerPath`
- `MRAVEndpoint`
- `MRAVOutputContext`
- `MRAVOutputDevice`
- `MRAVRoutingDiscoverySession`
- `MRXPCConnection`

Full Objective-C method metadata still needs extraction or runtime introspection; `dyld_info -objc` reports that it cannot print live ObjC info from dylibs in the dyld shared cache.
