# MediaRemote SDK and Live Differences

## Scope

This note compares the active macOS 26.5.2 live `MediaRemote.framework` dyld-cache export surface against the installed Xcode 26.6 MacOSX26.5 SDK and Xcode 27.0 beta SDK `.tbd` stubs.

Evidence capture:

- `research/MediaRemote/captures/20260716T091344Z`
- live image: `/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote`
- current SDK stub: Xcode 26.6 `MediaRemote.tbd`
- beta SDK stub: Xcode 27.0 beta `MediaRemote.tbd`

The SDK stubs are declarations for link-time use. They do not prove that a symbol exists in the active OS runtime. The live dyld-cache export list is the authoritative surface for what can be resolved on this Mac today.

## Counts

| Surface | Count |
| --- | ---: |
| Live macOS 26.5.2 exports | 5,131 |
| Xcode 26 SDK names | 3,906 |
| Xcode 27 beta SDK names | 3,954 |
| Live-only vs Xcode 26 SDK | 2,565 |
| Live-only vs Xcode 27 beta SDK | 2,566 |
| Xcode 26 SDK-only vs live | 1,340 |
| Xcode 27 beta SDK-only vs live | 1,389 |
| Xcode 27 beta SDK-only vs Xcode 26 SDK | 51 |
| Xcode 26 SDK-only vs Xcode 27 beta SDK | 3 |
| Xcode 27 beta additions already live on macOS 26.5.2 | 0 |

Interpretation: the beta SDK declares a small forward-looking public-private surface on top of the Xcode 26 SDK, but none of those 51 additions are exported by the active macOS 26.5.2 `MediaRemote` image.

## Xcode 27 Beta Additions

All 51 names in this table are present in the Xcode 27 beta SDK stub and absent from both the Xcode 26 SDK stub and the active macOS 26.5.2 live export list.

| Area | Symbols |
| --- | --- |
| Endpoint and route status | `_MRAVEndpointDidBecomeStaleNotification`, `_MRAVEndpointResolveActiveSystemEndpointWithTypeReturningError`, `_MRMediaRemoteRouteStatusErrorDomain` |
| XPC helper cleanup | `_MRCreateArrayFromXPCMessage`, `_MRReplyToXPCMessageWithHandler` |
| Now-playing session errors | `_MRCreateNowPlayingSessionError`, `_MRNowPlayingSessionErrorDomain` |
| App entity and donation state | `_MRMediaRemoteGetLiveAppEntityDonationsEnabled`, `_kMRMediaRemoteNowPlayingInfoAppEntityPaths` |
| Now-playing content typing | `_MRNowPlayingInfoContentTypeBook`, `_MRNowPlayingInfoContentTypeGeneric`, `_MRNowPlayingInfoContentTypeHomeMedia`, `_MRNowPlayingInfoContentTypeMovie`, `_MRNowPlayingInfoContentTypeMusic`, `_MRNowPlayingInfoContentTypePodcast`, `_MRNowPlayingInfoContentTypeRadio`, `_MRNowPlayingInfoContentTypeTVShow`, `_kMRMediaRemoteNowPlayingInfoContentType`, `_kMRMediaRemoteNowPlayingInfoStrictMediaType` |
| Now-playing media and duration typing | `_MRNowPlayingInfoDurationStringLocalizationKeyContinuous`, `_MRNowPlayingInfoDurationStringLocalizationKeyLive`, `_MRNowPlayingInfoMediaTypeAudio`, `_MRNowPlayingInfoMediaTypeVideo`, `_kMRMediaRemoteNowPlayingInfoDurationStringLocalizationKey`, `_kMRMediaRemoteNowPlayingInfoLocalizedDurationString` |
| Remote/fetchable artwork | `_kMRMediaRemoteNowPlayingInfoFetchableArtwork`, `_kMRMediaRemoteNowPlayingInfoRemoteArtworkFormats` |
| Playback account and phone-call routing options | `_kMRMediaRemoteOptionPlaybackAccountID`, `_kMRMediaRemoteOptionAlwaysAllowDuringPhoneCalls`, `_playbackAccountID`, `_alwaysAllowDuringPhoneCalls` |
| Push tokens | `_kMRMediaRemotePushTokensDidChangeNotification`, `_kMRMediaRemotePushTokensUserInfoKey` |
| Command handler | `_MRMediaRemoteRemoveCommandHandlerForPlayer` |
| Application launch | `_MROpenApplicationWithBundleID` |
| Request initiators | `_MRRequestDetailsInitiatorFollowMyMusic`, `_MRRequestDetailsInitiatorInternalWorkLoad`, `_MRRequestDetailsInitiatorTopCap` |
| Activity UI descriptions | `_NSStringFromMRNowPlayingActivityUIDuration`, `_NSStringFromMRNowPlayingActivityUIState` |
| Group topology protocol selection | `_MRGroupTopologyModificationRequestProtocolSelectionBehaviorDescription`, `_MRGroupTopologyModificationRequestProtocolSelectionBehaviorFromDescription`, `_protocolSelectionBehavior` |
| Discovery protocol metadata | `_alternativeOutputDevices`, `_customProtocolIconIdentifier`, `_disabled`, `_discoversCustomProtocolDevices`, `_discoversDisabledDevices`, `_isPreferredProtocol`, `_protocolName`, `_protocolUID` |

## Xcode 26 Names Missing From Xcode 27 Beta

Only three Xcode 26 SDK symbols are absent from the Xcode 27 beta SDK stub:

| Symbol | Interpretation |
| --- | --- |
| `_MRCreateArrayFomXPCMessage` | Likely spelling cleanup. Live macOS 26.5.2 exports the misspelled `Fom` variant; the Xcode 27 beta SDK declares `_MRCreateArrayFromXPCMessage` instead. |
| `_MRLogCategoryDefault` | Logging category no longer declared in the beta stub. |
| `_MRLogCategoryMirroringView` | Logging category no longer declared in the beta stub. |

Compatibility note: tooling that dynamically resolves the array helper should probe both spellings when targeting multiple OS/SDK combinations. On this active macOS 26.5.2 system, `_MRCreateArrayFomXPCMessage` is the live spelling.

## Live Evidence Around Beta Themes

Some beta SDK themes already have related live runtime evidence, but not the exact beta-exported names:

- App entities: live exports include Objective-C metadata for `MRAppEntityPath` and `_MRAppEntityPathProtobuf`.
- Remote artwork: live exports include `MRRemoteArtwork`, `_MRRemoteArtworkProtobuf`, and content-item/request protobuf ivars for remote artwork formats.
- Route status: live exports include `_kMRMediaRemoteRouteStatusDidChangeNotification` and `_kMRMediaRemoteRouteStatusUserInfoKey`, while the beta stub adds `_MRMediaRemoteRouteStatusErrorDomain`.
- Now-playing sessions: live exports include `MRNowPlayingSessionManager*` functions, while the beta stub adds explicit now-playing-session error-domain helpers.

Inference: Xcode 27 appears to formalize or expose more of surfaces that were already partly present internally on macOS 26.5.2: app-entity paths, remote artwork formats, route status, now-playing-session errors, and content/media typing.

## Safety and Tooling Boundaries

- Do not link a macOS 26.5 helper directly against Xcode 27 beta-only names and expect it to run on this active system; those symbols are not exported by the live framework.
- Prefer `dlsym` feature detection for every beta-only symbol.
- Keep the current misspelled `_MRCreateArrayFomXPCMessage` path in compatibility probes until a live runtime export confirms the corrected `_MRCreateArrayFromXPCMessage` spelling.
- Treat the beta-only content-type, artwork, push-token, and app-entity keys as forward-looking schema clues, not verified runtime keys for the active OS.

## Repeatable Commands

Regenerate the inventory:

```sh
tools/mediaremote-inventory.zsh
```

Compare SDK stubs from a capture:

```sh
comm -13 research/MediaRemote/captures/<timestamp>/sdk-current-symbols.txt research/MediaRemote/captures/<timestamp>/sdk-beta-symbols.txt
comm -23 research/MediaRemote/captures/<timestamp>/sdk-current-symbols.txt research/MediaRemote/captures/<timestamp>/sdk-beta-symbols.txt
comm -12 research/MediaRemote/captures/<timestamp>/beta-sdk-only-vs-current-sdk.txt research/MediaRemote/captures/<timestamp>/live-symbols.txt
```

Expected result for capture `20260716T091344Z`: the final command prints no symbols, proving that none of the 51 beta-only SDK additions are exported by the active macOS 26.5.2 runtime.
