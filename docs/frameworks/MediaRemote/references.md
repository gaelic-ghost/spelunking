# MediaRemote References

Add references only after they have been read or locally verified.

## Official Documentation

- No official `MediaRemote.framework` documentation verified yet.

## Local Evidence

- `research/MediaRemote/baseline-2026-07-15.md`
- `docs/frameworks/MediaRemote/live-dyld-cache.md`
- `docs/frameworks/MediaRemote/runtime-probes.md`
- `docs/frameworks/MediaRemote/inventory-captures.md`
- `docs/frameworks/MediaRemote/now-playing-architecture.md`
- `docs/frameworks/MediaRemote/agents-daemons.md`
- `docs/frameworks/MediaRemote/xpc-and-messages.md`
- `docs/frameworks/MediaRemote/routes-output-devices.md`
- Active system framework shell: `/System/Library/PrivateFrameworks/MediaRemote.framework`
- Active system support binaries: `mediaremoted`, `mediaremoteagent`
- Selected Xcode 26 SDK stub: `MediaRemote.tbd`
- Xcode 27 beta SDK stub: `MediaRemote.tbd`

## Related Surfaces

Track related frameworks, daemons, XPC services, and public APIs discovered during the first pass.

Initial related surfaces from `mediaremoted` linkage and entitlements:

- `MediaControl.framework`
- `AVRouting.framework`
- `Rapport.framework`
- `IDS.framework`
- `HomeKit.framework`
- `SystemStatus.framework`
- `AppIntentsServices.framework`
- `BiomeLibrary.framework`
- `BiomeStreams.framework`
- `MediaServices.framework`
- `iTunesCloud.framework`
- CoreMedia endpoint, routing context, volume controller, and route discoverer XPC services
