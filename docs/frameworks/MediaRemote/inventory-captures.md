# MediaRemote Inventory Captures

## Purpose

`tools/mediaremote-inventory.zsh` captures repeatable static evidence from the active dyld-cache image, SDK stubs, framework resources, and support binaries.

Raw captures are intentionally ignored by Git under `research/**/captures/`. Promote stable findings into this docs tree after reviewing a capture.

## Latest Capture

| Field | Value |
| --- | --- |
| Timestamp | `20260716T080533Z` |
| Capture root | `research/MediaRemote/captures/20260716T080533Z` |
| Active framework image | `/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote` |
| Active OS | macOS 26.5.2, build 25F84 |
| Selected Xcode SDK | Xcode 26.6, MacOSX26.5 SDK |
| Beta SDK | Xcode 27.0 beta |

## Captured Files

- `live-symbols.txt`: exported symbols from the live dyld shared-cache image.
- `dyld-exports.txt`, `dyld-imports.txt`, `dyld-linked-dylibs.txt`, `dyld-load-commands.txt`: `dyld_info` views over the live framework image.
- `dyld-function-starts.txt`: function-start names and addresses, useful for recovering internal method/function neighborhoods when header dumping is unavailable.
- `dyld-cstrings.txt`, `dyld-oslogstrings.txt`: string and os-log evidence from the live framework image.
- `dyld-objc-classnames.txt`, `dyld-objc-method-names.txt`, `dyld-objc-method-types.txt`: best-effort Objective-C sections from dyld tooling.
- `sdk-current-symbols.txt`, `sdk-beta-symbols.txt`: symbols named by the installed Xcode 26 and Xcode 27 beta `.tbd` stubs.
- `live-only-vs-current-sdk.txt`, `live-only-vs-beta-sdk.txt`, `current-sdk-only-vs-live.txt`, `beta-sdk-only-vs-live.txt`: local symbol-set diffs.
- `mediaremoted-*`: support daemon linkage, entitlements, and filtered strings.
- `mediaremoteagent-*`: launch agent linkage, entitlements, and filtered strings.
- `framework-info-plist.txt`, `remote-control-blacklist.txt`: framework resources.

## Capture Summary

| Surface | Count |
| --- | ---: |
| Live `MediaRemote` exports | 5,131 |
| Xcode 26 SDK `MediaRemote` symbols | 3,906 |
| Xcode 27 beta SDK `MediaRemote` symbols | 3,954 |
| Live-only vs Xcode 26 SDK | 2,565 |
| Live-only vs Xcode 27 beta SDK | 2,566 |
| Xcode 26 SDK-only vs live | 1,340 |
| Xcode 27 beta SDK-only vs live | 1,389 |

## Reproduce

From the repository root:

```sh
tools/mediaremote-inventory.zsh
```

The script creates a new timestamped directory under `research/MediaRemote/captures/`.

## Notes

- The live framework path is a dyld shared-cache image path; the framework directory is mostly a shell on disk.
- `dyld_info -objc` cannot currently print all Objective-C metadata for this dyld-cache image. Exported Objective-C symbols and string sections are more useful for class and selector discovery.
- Capture files include command headers because the script records the command that generated each artifact.
