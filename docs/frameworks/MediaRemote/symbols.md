# MediaRemote Symbols

## Exported Functions

Capture and classify exported functions from the active framework and beta SDK here.

Initial SDK stub counts:

| Surface | Xcode 26 SDK | Xcode 27 beta SDK |
| --- | ---: | ---: |
| `MediaRemote.tbd` | 3,907 | 3,955 |
| `MediaRemoteDaemonServices.tbd` | 4 | 4 |

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

Capture classes, protocols, selectors, categories, and notification names here.

## Constants and Notifications

Record interesting constants, notification names, command identifiers, route identifiers, and error domains here.

## Version Differences

Use this section to compare macOS 26.5 against the macOS 27 beta SDK.

Early SDK diff notes:

- Xcode 27 beta appears to add richer now-playing content/media typing and artwork-related keys.
- Xcode 27 beta adds route-status and now-playing-session error-domain symbols.
- Xcode 27 beta adds `_MRCreateArrayFromXPCMessage`; Xcode 26 exposes the likely misspelled `_MRCreateArrayFomXPCMessage`.
- Xcode 26 exposes `_MRLogCategoryDefault` and `_MRLogCategoryMirroringView`; those names were not present in the initial Xcode 27 beta stub diff.
