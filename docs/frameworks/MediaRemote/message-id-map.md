# MediaRemote Message ID Map

## Scope

This page maps locally observed `MRXPC_MESSAGE_ID_KEY` values from client-side call sites in the live macOS 26.5.2 `MediaRemote.framework`.

Evidence source:

- disassembly: `research/MediaRemote/experiments/disassembly/20260716T085816Z/mediaremote-disassemble.txt`
- call-site table: `research/MediaRemote/experiments/message-ids/20260716T090007Z/message-id-callsites.tsv`
- extracted rows: 192

The map is partial. It captures immediate values passed to `MRCreateXPCMessage`, `-[MRXPCConnection sendMessageWithType:queue:reply:]`, and `-[MRXPCConnection sendSyncMessageWithType:error:]`.

It does not prove dynamic message IDs, every daemon-side handler, or entitlement requirements for successful execution.

## Repeatable Extraction

```sh
tools/mediaremote-message-id-callsites.zsh
tools/mediaremote-message-id-callsites.zsh --disassembly research/MediaRemote/experiments/disassembly/20260716T085816Z/mediaremote-disassemble.txt
```

The extractor writes ignored working output under `research/MediaRemote/experiments/message-ids/<timestamp>/`.

## Encoding

Observed message types use a high-domain plus low-ordinal shape:

```text
message_type = domain << 48 | ordinal
```

Examples:

| Message Type | Domain | Ordinal | Observed API |
| --- | --- | --- | --- |
| `0x0200000000000007` | `0x200` | `0x7` | `RequestNowPlayingPlaybackQueue` |
| `0x020000000000000F` | `0x200` | `0xF` | `GetPlayerProperties` |
| `0x0300000000000002` | `0x300` | `0x2` | `_MRMediaRemoteServiceCopyPickableRoutes` |
| `0x0400000000000001` | `0x400` | `0x1` | `SendCommand` |

## Transport Proof

The disassembly confirms `MRXPCConnection` is the immediate client-side constructor path:

- `-[MRXPCConnection sendMessageWithType:queue:reply:]` passes the type argument to `_MRCreateXPCMessage`, then sends through `sendMessage:queue:reply:`.
- `-[MRXPCConnection sendSyncMessageWithType:error:]` passes the type argument to `_MRCreateXPCMessage`, then sends through `sendSyncMessage:error:`.
- `_MRCreateXPCMessage` writes the message type to `MRXPC_MESSAGE_ID_KEY` with `xpc_dictionary_set_uint64`.

Meaning: these IDs are real XPC message IDs at the framework boundary, not only log labels or wrapper names.

## Domain Summary

| Domain | Rows | Inferred Surface |
| --- | ---: | --- |
| `0x100` | 22 | general service, notifications, volume, pairing, transactions |
| `0x200` | 65 | now-playing, players, clients, origins, queues, properties, playback state |
| `0x300` | 53 | routes, endpoints, output devices, output contexts, route passwords, sessions |
| `0x400` | 11 | media commands, media controls presentation, app command connections |
| `0x500` | 10 | browsable content and content items |
| `0x600` | 10 | television, game-controller, and system-group-session-adjacent surfaces |
| `0x900` | 6 | voice or virtual voice recording endpoint surfaces |
| `0xA00` | 2 | agent availability and active-call surfaces |
| `0xB00` | 4 | UI service endpoint and relay surfaces |
| `0xC00` | 9 | group session, user identity, invitations, and events |

The domain labels are inferred from nearby symbol/function names. They are not Apple-provided enum names.

## Now-Playing Domain `0x200`

High-value IDs for read-oriented now-playing research:

| Ordinal | Message Type | Observed API |
| --- | --- | --- |
| `0x7` | `0x0200000000000007` | `RequestNowPlayingPlaybackQueue`, `+[MRNowPlayingRequest localNowPlayingItem]` |
| `0xC` | `0x020000000000000C` | `GetClientProperties` |
| `0xF` | `0x020000000000000F` | `GetPlayerProperties` |
| `0x12` | `0x0200000000000012` | `GetPlaybackState`, `+[MRNowPlayingRequest localPlaybackState]` |
| `0x18` | `0x0200000000000018` | `resolvePlayerPath:queue:completion:`, `CopyResolvedPlayerPath`, `+[MRNowPlayingRequest localNowPlayingPlayerPath]` |
| `0x19` | `0x0200000000000019` | `GetAvailableOrigins` |
| `0x1B` | `0x020000000000001B` | `GetActiveOrigin` |
| `0x1F` | `0x020000000000001F` | `GetNowPlayingClients` |
| `0x21` | `0x0200000000000021` | `GetNowPlayingClient` |
| `0x23` | `0x0200000000000023` | `GetNowPlayingPlayers` |
| `0x25` | `0x0200000000000025` | `GetNowPlayingPlayer` |
| `0x27` | `0x0200000000000027` | `GetActivePlayerPathsForLocalOrigin` |
| `0x2C` | `0x020000000000002C` | `getDeviceInfoForPlayerPath:queue:completion:`, `CopyDeviceInfo` |
| `0x2E` | `0x020000000000002E` | `GetElectedPlayerPath` |
| `0x2F` | `0x020000000000002F` | `GetProactiveRecommendedPlayer` |
| `0x31` | `0x0200000000000031` | `GetSupportedCommands`, `+[MRNowPlayingRequest localSupportedCommands]` |
| `0x36` | `0x0200000000000036` | `GetLastPlayingDateForPlayer`, `GetLastPlayingDateForPlayerSync` |
| `0x3B` | `0x020000000000003B` | `GetAudioFormatContentInfoForOrigin` |
| `0x3D` | `0x020000000000003D` | `fetchParticipantsWithRequest:playerPath:queue:completion:` |

Mutating or state-publishing IDs in the same domain:

| Ordinal | Message Type | Observed API |
| --- | --- | --- |
| `0x1` | `0x0200000000000001` | `SetNowPlayingAppOverride` |
| `0x2` | `0x0200000000000002` | `SetOverriddenNowPlayingApplication` |
| `0x3` | `0x0200000000000003` | `BeginActivity` |
| `0x5` | `0x0200000000000005` | `EndActivity` |
| `0x6` | `0x0200000000000006` | `SetCanBeNowPlayingApp` |
| `0x8` | `0x0200000000000008` | `SetNowPlayingPlaybackQueue` |
| `0xA` | `0x020000000000000A` | `SetNowPlayingPlaybackQueueCapabilities` |
| `0xD` | `0x020000000000000D` | `SetClientProperties` |
| `0xE` | `0x020000000000000E` | `UpdateClientProperties` |
| `0x10` | `0x0200000000000010` | `SetPlayerProperties` |
| `0x11` | `0x0200000000000011` | `UpdatePlayerProperties` |
| `0x13` | `0x0200000000000013` | `SetPlaybackState` |
| `0x17` | `0x0200000000000017` | `SendLyricsEvent` |
| `0x1A` | `0x020000000000001A` | `SetActiveOrigin` |
| `0x20` | `0x0200000000000020` | `SetNowPlayingClient` |
| `0x22` | `0x0200000000000022` | `RemoveClient` |
| `0x24` | `0x0200000000000024` | `SetNowPlayingPlayer` |
| `0x26` | `0x0200000000000026` | `RemovePlayer` |
| `0x29` | `0x0200000000000029` | `SetHardwareRemoteBehavior` |
| `0x2A` | `0x020000000000002A` | `SendContentItemArtworkChangedNotification` |
| `0x2B` | `0x020000000000002B` | `SendContentItemChangedNotification` |
| `0x32` | `0x0200000000000032` | `SetSupportedCommands` |
| `0x33` | `0x0200000000000033` | `SetDefaultSupportedCommands` |
| `0x35` | `0x0200000000000035` | `SetPictureInPictureEnabledForPlayer` |
| `0x37` | `0x0200000000000037` | `SetOriginClientProperties` |
| `0x38` | `0x0200000000000038` | `SetPlayerClientProperties` |
| `0x39` | `0x0200000000000039` | `SetCanBeNowPlayingAppForPlayer` |
| `0x3A` | `0x020000000000003A` | `SetWakingPlayerPaths` |

Boundary: `0x200` is not inherently read-only. It mixes useful read requests with identity, queue, playback-state, and content-item mutation/publishing paths.

## Routes and Endpoints Domain `0x300`

High-signal read or inspection-looking route IDs:

| Ordinal | Message Type | Observed API |
| --- | --- | --- |
| `0x2` | `0x0300000000000002` | `_MRMediaRemoteServiceCopyPickableRoutes` |
| `0x4` | `0x0300000000000004` | `_MRMediaRemoteServiceGetPickedRouteVolumeControlCapabilities`, sync variant |
| `0x6` | `0x0300000000000006` | `_MRMediaRemoteServiceGetExternalScreenType` |
| `0xC` | `0x030000000000000C` | `_MRMediaRemoteServiceGetReceiverAirPlaySecuritySettings` |
| `0xD` | `0x030000000000000D` | `_MRMediaRemoteServiceGetHostedRoutingXPCEndpoint` |
| `0xF` | `0x030000000000000F` | `_MRMediaRemoteServiceGetRecentAVOutputDeviceUIDs` |
| `0x10` | `0x0300000000000010` | `_MRMediaRemoteServiceGetActiveSystemEndpointUID`, typed variant |
| `0x1D` | `0x030000000000001D` | `_MRMediaRemoteServiceGetExternalDevice` |
| `0x1F` | `0x030000000000001F` | `_MRMediaRemoteServiceCopyVirtualOutputDevices` |
| `0x25` | `0x0300000000000025` | `+[MRAVConcreteOutputContext outputContextForLocalDevice]` |
| `0x30` | `0x0300000000000030` | `searchEndpointsForOutputDeviceUID:timeout:details:queue:completion:` |
| `0x33` | `0x0300000000000033` | `searchEndpointsForRoutingContextUID:timeout:details:queue:completion:` |
| `0x37` | `0x0300000000000037` | `+[MRAVEndpoint(Intent_Volume) volumeForOutputDeviceUID:timeout:details:completion:]` |
| `0x39` | `0x0300000000000039` | `+[MRAVEndpoint(Intent_Volume) volumeCapabilitiesForOutputDeviceUID:timeout:details:completion:]` |

Mutating route/session examples:

| Ordinal | Message Type | Observed API |
| --- | --- | --- |
| `0x1` | `0x0300000000000001` | `_MRMediaRemoteServiceSetRouteDiscoveryMode` |
| `0x3` | `0x0300000000000003` | `_MRMediaRemoteServiceSetPickedRoute`, `_MRMediaRemoteServiceFindAndPickRoute` |
| `0x5` | `0x0300000000000005` | `_MRMediaRemoteServiceSetPickedRouteVolumeControlCapabilities` |
| `0x8` | `0x0300000000000008` | `_MRMediaRemoteServiceSetSavedAVRoutePassword` |
| `0x9` | `0x0300000000000009` | `_MRMediaRemoteServiceClearAllAVRoutePasswords` |
| `0xA` | `0x030000000000000A` | `_MRMediaRemoteServiceUnpickAirPlayAVRoutes` |
| `0x17` | `0x0300000000000017` | `_MRMediaRemoteServiceGroupDevicesAndSendCommand` |
| `0x18` | `0x0300000000000018` | `_MRMediaRemoteServiceRemoveFromParentGroup` |
| `0x20` | `0x0300000000000020` | `_MRMediaRemoteServiceCreateGroupWithDevices` |
| `0x23` | `0x0300000000000023` | `_MRNowPlayingSessionManagerStartSession` |
| `0x24` | `0x0300000000000024` | `_MRNowPlayingSessionManagerStopSession` |
| `0x28` | `0x0300000000000028` | `MRAVOutputContextModification`, playback-session migration request |
| `0x2F` | `0x030000000000002F` | `+[MRAVEndpoint(Intent_Grouping) pauseOutputDeviceUIDs:behavior:details:queue:completion:]` |
| `0x31` | `0x0300000000000031` | `sendCommand:withOptions:toEachEndpointContainingOutputDeviceUIDs:` |
| `0x32` | `0x0300000000000032` | `sendCommand:withOptions:toNewEndpointContainingOutputDeviceUIDs:` |
| `0x38` | `0x0300000000000038` | `changeVolume:action:outputDeviceUIDs:timeout:details:completion:` |

Boundary: route discovery and endpoint lookup are mixed with grouping, migration, password, volume, and playback-session mutation. Keep `0x300` probes behind explicit command-line flags.

## Commands Domain `0x400`

| Ordinal | Message Type | Observed API |
| --- | --- | --- |
| `0x1` | `0x0400000000000001` | `SendCommand` |
| `0x2` | `0x0400000000000002` | `BroadcastCommand` |
| `0x3` | `0x0400000000000003` | `PrewarmMediaControlsCommand` |
| `0x4` | `0x0400000000000004` | `PresentMediaControlsCommand` |
| `0x5` | `0x0400000000000005` | `DismissMediaControlsCommand` |
| `0x6` | `0x0400000000000006` | `_MRMediaRemoteRequestPendingCommands`, `_MRMediaRemoteCopyPendingCommands` |
| `0xE` | `0x040000000000000E` | `_restrictCommandClientsTo:` |
| `0xF` | `0x040000000000000F` | `createApplicationConnection:queue:completion:` |
| `0x10` | `0x0400000000000010` | `sendApplicationConnectionMessage:forConnection:queue:completion:` |
| `0x11` | `0x0400000000000011` | `closeApplicationConnection:error:queue:completion:` |

Boundary: treat `0x400` as mutating/control-oriented by default. Even request-looking pending-command APIs are part of command dispatch and should not be included in default read-only probes.

## Safety Notes

- ID mapping proves message construction, not authorization. The daemon can still return Code 3 or reject the client based on audit token, entitlements, sandbox state, or process identity.
- Read-looking requests can still cause cache hydration, daemon registration, unified-log emission, and client bookkeeping.
- Mutating IDs should stay out of default tooling unless a command explicitly names the risk and requires an opt-in flag.
- Route, output-device, group-session, and command domains can affect active playback, selected endpoints, volume, or media-control UI. Keep them separate from now-playing read probes.

## Open Questions

- Tie the known Code 3 runtime failures to exact message IDs using daemon-side log predicates or client-side interposition.
- Recover dynamic or non-immediate message IDs that are not visible to this extractor.
- Map daemon-side request-handler tables to the client-side domain/ordinal IDs.
- Compare the same call-site map against the macOS 27 beta SDK or runtime when the relevant binary evidence is available.
