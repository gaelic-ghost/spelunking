# MediaRemote Now-Playing Architecture

## Read-Only Entry Points

Locally evidenced safe signatures:

- `MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t, block(CFDictionary?))`
- `MRMediaRemoteGetNowPlayingApplicationPID(dispatch_queue_t, block(int))`
- `MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t, block(bool))`
- `MRMediaRemoteGetNowPlayingClient(dispatch_queue_t, block(id?))`
- `MRMediaRemoteGetNowPlayingClients(dispatch_queue_t, block(NSArray?))`
- `MRMediaRemoteGetNowPlayingPlayer(dispatch_queue_t, block(id?))`
- `MRMediaRemoteGetNowPlayingInfoForClient(id, dispatch_queue_t, block(CFDictionary?))`
- `MRMediaRemoteGetNowPlayingInfoForPlayer(id, dispatch_queue_t, block(CFDictionary?))`
- `MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t)`
- `MRMediaRemoteGetActiveOrigin(dispatch_queue_t, block(bool, id?))`
- `MRMediaRemoteGetAvailableOrigins(dispatch_queue_t, block(NSArray?))`
- `MRMediaRemoteGetActivePlayerPathsForOrigin(id, dispatch_queue_t, block(NSArray?))`
- `MRNowPlayingPlayerPathGetClient(id) -> id?`
- `MRNowPlayingPlayerPathGetPlayer(id) -> id?`
- `MRNowPlayingPlayerPathGetOrigin(id) -> id?`

Rejected until proven:

- `MRMediaRemoteGetNowPlayingApplicationDisplayID`
- `MRMediaRemoteGetNowPlayingApplicationDisplayName`
- path-derived `MRClient` passed to `MRMediaRemoteGetNowPlayingInfoForClient`
- path-derived `MRPlayer` passed to `MRMediaRemoteRequestNowPlayingPlaybackQueueForPlayerSync`

Those display-name/display-ID callbacks crashed when guessed as string callbacks.

## Identity Model

Exported symbols show multiple ways to address now-playing state:

- application-level APIs: `MRMediaRemoteGetNowPlayingApplicationPID`, playback state, display name, display ID.
- client APIs: `MRMediaRemoteGetNowPlayingClient`, `MRMediaRemoteGetNowPlayingClients`, `MRNowPlayingClientGetBundleIdentifier`.
- player APIs: `MRMediaRemoteGetNowPlayingPlayer`, `MRMediaRemoteGetNowPlayingPlayerForClient`.
- origin APIs: `MRMediaRemoteGetNowPlayingInfoForOrigin`, client/player equivalents for origin.
- player-path concepts in logs and strings: `playerPath`, `MRPlayerPath`, active player path change notifications.

Inference: the empty Spotify results from direct global APIs may mean the active state lives under an origin/player path that the simple global calls do not resolve for this process.

Verified: Spotify was empty through the global now-playing calls but visible through `MRMediaRemoteGetActiveOrigin` plus `MRMediaRemoteGetActivePlayerPathsForOrigin`.

Observed path:

```text
LOCL (Mac) -> com.spotify.client (Spotify, PID 37433) -> default player
```

The path-derived client exposes bundle identifier, display name, and process identifier through `MRNowPlayingClientGet*` helpers. The path-derived player exposes identifier `MediaRemote-DefaultPlayer`, display name `Default Player`, and audio session type `0`.

The path-derived objects are useful for identity, but they are not interchangeable with every higher-level MediaRemote API. Two crashes confirmed that `MRMediaRemoteGetNowPlayingInfoForClient` and `MRMediaRemoteRequestNowPlayingPlaybackQueueForPlayerSync` expect a narrower object shape than the `MRClient`/`MRPlayer` extracted from `MRPlayerPath`.

`dyld_info -function_starts` adds useful implementation context around this path:

- `MRMediaRemoteGetLocalNowPlayingClient`
- `MRNowPlayingPlayerPathCreate`
- `MRNowPlayingPlayerPathSetOrigin`
- `MRNowPlayingPlayerPathSetClient`
- `MRNowPlayingPlayerPathSetPlayer`
- `MRMediaRemoteGetLocalOrigin`
- `MRNowPlayingPlayerPathGetClient`
- `MRNowPlayingClientGetProcessIdentifier`
- `MRNowPlayingClientGetBundleIdentifier`
- `MRNowPlayingPlayerPathGetPlayer`
- `MRMediaRemoteGetDefaultNowPlayingPlayer`
- `MRNowPlayingOriginClientManager playerClientForPlayerPath:`
- `MRNowPlayingOriginClient nowPlayingClientForPlayerPath:`
- `MRNowPlayingClient initWithPlayerPath:`
- `MRNowPlayingPlayerClient initWithPlayerPath:`

Inference: for richer metadata, the next cleaner path is likely through `MRNowPlayingOriginClientManager`/`MRNowPlayingPlayerClient` behavior or a request API that accepts the full player path, not through the raw path-derived client/player object alone.

## Controller Generations

OS log strings identify several now-playing controller implementations:

- `MRQHONPC`
- `MRV1NowPlayingController`
- `MRV2NowPlayingController`
- `MRNowPlayingController`

Common behavior across controllers:

- resolve endpoint
- resolve player path for endpoint
- load now-playing data
- process playback queue changes
- process content item changes
- process artwork changes
- process playback state changes
- process supported-command changes
- reload on active system endpoint changes
- reload on player-path invalidation
- reload on endpoint changes

Useful log phrases:

- `Player path is not resolved. There may be no now playing application.`
- `Resolved to player path: %@.`
- `processing PlaybackQueueDidChangeNotification.`
- `processing PlaybackStateDidChangeNotification`
- `processing SupportedCommandsDidChangeNotification.`
- `reloading due to player path invalidation`
- `reloading due to ASE change`

## Notifications

Static strings identify application, origin, and player variants:

- `kMRMediaRemoteNowPlayingInfoDidChangeNotification`
- `kMRMediaRemoteOriginNowPlayingInfoDidChangeNotification`
- `kMRMediaRemotePlayerNowPlayingInfoDidChangeNotification`
- `kMRMediaRemoteNowPlayingApplicationDidChangeNotification`
- `kMRMediaRemoteOriginNowPlayingApplicationDidChangeNotification`
- `kMRMediaRemoteNowPlayingApplicationDisplayNameDidChangeNotification`
- `kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification`
- `kMRMediaRemotePlayerIsPlayingDidChangeNotification`
- `kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification`
- `kMRMediaRemotePlayerPlaybackStateDidChangeNotification`
- `kMRMediaRemoteNowPlayingPlayerDidChange`
- `kMRMediaRemoteActivePlayerDidChange`
- `kMRMediaRemoteActivePlayerPathsDidChange`
- `kMRMediaRemoteNowPlayingApplicationDidRegisterCanBeNowPlaying`
- `kMRMediaRemoteNowPlayingApplicationDidUnregisterCanBeNowPlaying`
- `kMRMediaRemoteNowPlayingPlayerDidRegisterCanBeNowPlaying`
- `kMRMediaRemoteNowPlayingPlayerDidUnregisterCanBeNowPlaying`
- `kMRMediaRemoteNowPlayingApplicationDidRegister`
- `kMRMediaRemoteNowPlayingApplicationDidUnregister`
- `kMRMediaRemoteNowPlayingApplicationClientStateDidChange`
- `kMRMediaRemoteNowPlayingPlayerStateDidChange`
- `kMRMediaRemoteNowPlayingApplicationDidForegroundNotification`
- `kMRMediaRemoteElectedPlayerDidChangeNotification`
- `kMRMediaRemotePlaybackDidTimeoutNotification`
- `kMRMediaRemoteLockScreenControlsPlayerPathDidChangeNotification`
- `kMRMediaRemoteAvailableOriginsDidChangeNotification`
- `kMRMediaRemoteActiveOriginDidChangeNotification`
- `kMRMediaRemoteOriginDidRegisterNotification`
- `kMRMediaRemoteOriginDidUnregisterNotification`
- `kMRMediaRemoteOriginUserInfoKey`
- `kMRMediaRemoteOriginDataUserInfoKey`
- `kMRNowPlayingPlayerPathUserInfoKey`
- `kMRNowPlayingPlayerPathDataUserInfoKey`
- `kMROriginActiveNowPlayingPlayerPathUserInfoKey`
- `kMROriginActiveNowPlayingPlayerPathDataUserInfoKey`

User-info keys include:

- `kMRMediaRemoteNowPlayingApplicationDisplayNameUserInfoKey`
- `kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey`
- `kMRMediaRemoteNowPlayingApplicationPIDUserInfoKey`
- `kMRMediaRemotePlaybackStateUserInfoKey`
- `kMRMediaRemoteApplicationForegroundUserInfoKey`
- `kMRMediaRemoteElectedPlayerReasonUserInfoKey`
- `kMRMediaRemotePlayerPictureInPictureEnabledUserInfoKey`

Runtime note: `mr-now-playing-probe --observe` did not receive these notifications during a Spotify play/pause cycle, even after registering and setting wants-now-playing notifications.

## Now-Playing Info Keys

Static string evidence names a rich metadata dictionary:

- basic media: `Title`, `Artist`, `Album`, `Composer`, `Genre`, `Duration`, `ElapsedTime`, `Timestamp`, `PlaybackRate`, `DefaultPlaybackRate`.
- indexing: `QueueIndex`, `TotalQueueCount`, `TrackNumber`, `TotalTrackCount`, `DiscNumber`, `TotalDiscCount`, `ChapterNumber`, `TotalChapterCount`.
- identifiers: `UniqueIdentifier`, `ContentItemIdentifier`, `ExternalContentIdentifier`, `iTunesStoreIdentifier`, `iTunesStoreSubscriptionAdamIdentifier`, artist/album Adam IDs, playlist global identifier, radio station identifiers, profile/service/brand identifiers.
- artwork: `ArtworkData`, `ArtworkDataWidth`, `ArtworkDataHeight`, `ArtworkIdentifier`, `ArtworkMIMEType`, `ArtworkURL`, square/tall animated artwork identifiers and payloads.
- state/capabilities: `MediaType`, `IsAdvertisement`, `IsAlwaysLive`, `IsInTransition`, `IsBanned`, `IsExplicitTrack`, `IsLiked`, `IsMusicApp`, `IsSharable`, `IsVideosApp`, `ProhibitsSkip`, `IsLoading`, `IsSteerable`.
- language/lyrics: available/current language options data and lyrics.
- extras: `DownloadProgress`, `DownloadState`, `PurchaseInfoData`, `CollectionInfo`, `ClientPropertiesData`, `UserInfo`, `AppMetrics`, `CalculatedElapsedTime`.

## Playback Queue

The queue request surface is richer than a simple current-track dictionary. Evidence includes:

- `MRPlaybackQueueRequestCreate*`
- `MRPlaybackQueueRequestSetIncludeInfo`
- `MRPlaybackQueueRequestSetIncludeMetadata`
- `MRPlaybackQueueRequestSetIncludeLyrics`
- `MRPlaybackQueueRequestSetIncludeSections`
- `MRPlaybackQueueRequestSetIncludeLanguageOptions`
- `MRPlaybackQueueRequestSetIncludeArtwork`
- `MRPlaybackQueueRequestGetRequestedIdentifiers`
- `MRPlaybackQueueRequestRangeContainsNowPlayingItem`
- `MRPlaybackQueueRequestCreateExternalRepresentation`

Request fields include:

- `includeMetadata`
- `includeLyrics`
- `includeLanguageOptions`
- `includeAvailableArtworkFormats`
- `requestedArtworkFormats`
- `requestedRemoteArtworkFormats`
- `requestedAnimatedArtworkPreviewFrameFormats`
- `requestedAnimatedArtworkAssetURLFormats`
- `returnContentItemAssetsInUserCompletion`

Inference: the “now playing but better” path likely requires player-path plus playback-queue request APIs, not just `MRMediaRemoteGetNowPlayingInfo`.
