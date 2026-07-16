# MediaRemote Agents and Daemons

## Scope

This note covers support binaries shipped with `MediaRemote.framework`:

- `/System/Library/PrivateFrameworks/MediaRemote.framework/Support/mediaremoted`
- `/System/Library/PrivateFrameworks/MediaRemote.framework/Support/mediaremoteagent`

## `mediaremoted`

`mediaremoted` is the privileged hub. Its linkage and entitlements show that it owns the broad system integrations rather than acting as a thin helper.

High-signal linked frameworks include:

- `MediaRemote.framework`
- `MediaControl.framework`
- `AVRouting.framework`
- `AVFAudio.framework`
- `CoreAudio.framework`
- `IDS.framework`
- `Rapport.framework`
- `CoreUtils.framework`
- `TelephonyUtilities.framework`
- `CallKit.framework`
- `HomeKit.framework`
- `AppIntentsServices.framework`
- `RunningBoardServices.framework`
- `BiomeLibrary.framework` and `BiomeStreams.framework`

Important entitlement groups:

- MediaRemote authority: `com.apple.mediaremote.group-sessions`, `nearby-device`, `remote-control-discovery`, `send-commands`, `set-now-playing-app`, `set-playback-state`, `ui-control`, `ui-server-connection`.
- Route/audio authority: `com.apple.avfoundation.allow-system-wide-context`, `allows-access-to-device-list`, `allows-set-output-device`, `com.apple.private.coreaudio.borrowaudiosession.allow`.
- Nearby/device transport: `com.apple.private.ids.messaging`, `com.apple.private.ids.session`, `com.apple.CompanionLink`, `com.apple.rapport.SessionPaired`, `com.apple.proximitycontrol`.
- UI/system launch authority: FrontBoard/SpringBoard launch and remote alert entitlements, ActivityKit requester entitlements, UserNotifications forwarding.
- Storage/preferences: read-write access to `/Library/MediaRemote/` and shared preferences for `com.apple.mediaremote`, `com.apple.mediaremoted`, `com.apple.mediacontrol`, `com.apple.airplay`, `com.apple.coremedia`, and related domains.

Mach lookup allowlist highlights:

- `com.apple.mediaremoted.xpc`
- `com.apple.mediaremoteui.services`
- `com.apple.musicd`
- `com.apple.airplay.endpoint.xpc`
- `com.apple.airplay.receiver.mediaremote.services`
- `com.apple.coremedia.endpoint.xpc`
- `com.apple.coremedia.routingcontext.xpc`
- `com.apple.coremedia.routediscoverer.xpc`
- `com.apple.coremedia.volumecontroller.xpc`
- `com.apple.coremedia.endpointremotecontrolsession.xpc`
- `com.apple.SharePlay.GroupSessionService`
- `com.apple.sessionservices`
- `com.apple.CompanionLink`
- `com.apple.ProximityControl.server`
- `com.apple.appintents.LiveEntityService`

Interpretation: userland experiments should treat direct framework calls as a client surface, not as equivalent to daemon authority. Most route mutation, nearby-device, group-session, and UI service capabilities are daemon-owned.

## `mediaremoteagent`

`mediaremoteagent` is much smaller. Its filtered strings show an XPC event-stream listener and a launch-agent identity:

- `mediaremoteagent`
- `com.apple.mediaremote.launchagent`
- `com.apple.mediaremote.mediaremoteagent`
- `com.apple.telephonyutilities.callservicesdaemon.connectionrequest`
- `[MRAServer] xpcEventStream - received call event`
- `[MRAServer] xpcEventStream - received call shouldconnect event`
- `[MRAServer] xpcEventStream - received daemon launch event`
- `[MRAServer] xpcEventStream - received unnamed notifyd event`
- `Starting MediaRemoteAgent server`
- `MediaRemoteAgent server exiting`

Linked frameworks are limited compared with `mediaremoted`:

- `Foundation.framework`
- `CallKit.framework`
- `MediaRemote.framework`
- Swift runtime libraries including `libswiftXPC`

The capture did not show entitlements for `mediaremoteagent` with the same `codesign -d --entitlements -` command that produced broad entitlements for `mediaremoted`.

## Resource Notes

`RemoteControlBlacklist.plist` currently contains a rule for Safari:

- `com.apple.mobilesafari`
- `QueryingSupportedCommands`

Inference: the blacklist appears to restrict specific remote-control queries per bundle. No Spotify-specific rule appeared in this resource.
