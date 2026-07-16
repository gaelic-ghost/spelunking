# Phone App Surfaces

## Scope

This page documents app-level integration and execution surfaces exposed by the macOS Phone app bundle and closely related Phone intent extension on macOS 26.5.2. It covers URL schemes, app extensions, plugins, intent support, AppleScript absence, signing identity, and entitlement boundaries.

These are observed surfaces. They are not all supported third-party integration contracts.

## Evidence

Raw captures:

- `research/Phone/surfaces/bundle-surfaces-macos-26.5.2.txt`
- `research/Phone/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Phone/surfaces/phone-sdef-error-macos-26.5.2.txt`
- `research/Phone/surfaces/signing-summary-macos-26.5.2.txt`

## App Entry Points

Main app:

- path: `/System/Applications/Phone.app`
- bundle identifier: `com.apple.mobilephone`
- executable: `Phone`
- bundle name: `Phone`
- scene model: app declares `UIApplicationSceneManifest`
- dock tile plugin: `PhoneDockTile.docktileplugin`
- user activity type: `com.apple.facetime.handoff`
- device family: `6`

Inference: macOS Phone is a UIKit/iOSSupport-style system app closely tied to FaceTime handoff and call-services state.

## URL Schemes

Verified URL schemes from the app manifest:

| Scheme | Manifest name | Notes |
| --- | --- | --- |
| `tel` | Telephony URL | User-visible calling URL scheme. |
| `telephony` | Telephony URL | Private/system telephony route until behavior is proven. |
| `facetime-audio` | Telephony URL | FaceTime audio route. |
| `tel-phoneapp` | Telephony URL | Phone-app-specific telephony route. |
| `phoneapp` | Telephony URL | Phone-app-specific route. |
| `vmshow` | Telephony URL | Voicemail/show route; sensitive URL entitlement also appears on Phone. |

Open question: which schemes open visible UI only, which can preselect Recents/Favorites/Voicemail, and which require Apple-signed or locked/background privileges.

## AppleScript Surface

Phone does not expose a scripting dictionary on this machine:

- command: `sdef /System/Applications/Phone.app`
- result: `sdef: couldn't get sdef for /System/Applications/Phone.app (error -192)`

Inference: unlike Messages, Phone is not scriptable through a first-party AppleScript dictionary on this macOS build.

## App Extensions And Plugins

| Bundle ID | Bundle | Extension point or role | Principal / handler |
| --- | --- | --- | --- |
| `com.apple.MacHelper` | `FaceTimeMacHelper.bundle` | FaceTime/AppKit helper bundle embedded in Phone | `FaceTimeMacHelper.WrappedFaceTimeMacAppKitHelper` |
| `com.apple.Phone-docktileplugin` | `PhoneDockTile.docktileplugin` | Dock tile plugin | `PhoneDockTilePlugIn` |
| `com.apple.FaceTime.RemotePeoplePicker` | `RemotePeoplePicker.appex` | `com.apple.groupactivities` | group activity people picker surface |
| `com.apple.TelephonyUtilities.PhoneIntentHandler` | `PhoneIntentHandler.appex` in TelephonyUtilities | `com.apple.intents-service` | `IntentRouter` |

Inference: Phone’s app bundle is thinner than Messages’ bundle. Several key surfaces live in private frameworks such as TelephonyUtilities rather than inside the app bundle itself.

## Intent Support

`PhoneIntentHandler.appex` supports:

- `INAddCallParticipantIntent`
- `INJoinCallIntent`
- `INStartCallIntent`
- `INSearchCallHistoryIntent`
- `INPlayVoicemailIntent`

The manifest has an empty `IntentsRestrictedWhileLocked` array.

Inference: Apple ships system/private intent handling for starting calls, joining calls, adding call participants, searching call history, and playing voicemail. This is narrower than the broader private TelephonyUtilities entitlement set on the Phone app and does not expose arbitrary call mutation.

## Entitlement Boundaries

High-signal entitlement themes from the app and extension captures:

- main app: `com.apple.private.CallHistory.read-write`, CallHistory sync/helper access, TelephonyUtilities callservicesd access/modify/background calls, call capabilities, call providers, call recording, call screening, call translation, CommCenter fine-grained access, FaceTime/IDS privileges, visual voicemail, sensitive URL opening, TCC microphone/camera/contacts/photos, and CallHistory storage
- FaceTimeMacHelper: contacts/CoreDuet/suggestions, CallHistory storage, and TelephonyUtilities callservicesd access/modify/capabilities privileges
- RemotePeoplePicker: GroupActivities extension surface
- PhoneIntentHandler: private intents-service handler in TelephonyUtilities

Inference: the app is privileged as a platform call coordinator. Public surfaces such as `tel:` URLs, CallKit, and LiveCommunicationKit should be treated separately from private callservicesd and CallHistory privileges.

## Signing Notes

The signing summary records Apple system bundle identifiers and Mach-O formats. `TeamIdentifier` is reported as not set for these system bundles on this machine, which is normal for Apple platform binaries and not evidence of third-party signing.

## Open Questions

- What exact UI behavior do `tel:`, `tel-phoneapp:`, `phoneapp:`, and `vmshow:` produce on macOS 26.5.2?
- Which Phone intent handlers are Siri-user-invocable versus private/system-only?
- What host invokes `RemotePeoplePicker.appex`, and which GroupActivities payloads does it expect?
- Which FaceTimeMacHelper methods bridge AppKit behavior back into Phone or FaceTime UI?
- Which sensitive URL privileges correspond to visible app navigation versus background/locked call flows?
