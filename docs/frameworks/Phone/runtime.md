# Phone Runtime Observations

## Scope

This page records bounded, read-only runtime observations from opening `Phone.app` on macOS 26.5.2. It complements static evidence from schemas, entitlements, symbols, and Objective-C runtime metadata.

Raw evidence:

- `research/Phone/runtime/open-logstream-macos-26.5.2.txt`

Capture command shape:

```sh
/usr/bin/log stream --style compact --level default --timeout 8 --predicate '(process == "Phone") OR (subsystem CONTAINS[c] "Phone") OR (subsystem CONTAINS[c] "mobilephone") OR (subsystem CONTAINS[c] "CallHistory") OR (subsystem CONTAINS[c] "TelephonyUtilities") OR (eventMessage CONTAINS[c] "Phone") OR (eventMessage CONTAINS[c] "CallHistory") OR (eventMessage CONTAINS[c] "TelephonyUtilities")'
open -a Phone
```

The raw capture had paired-device identifiers and names redacted from Continuity Capture lines. No call rows, phone numbers, contacts, voicemail metadata, or call content were intentionally captured.

## Activation Evidence

Observed on app activation:

- `runningboardd` and `WindowServer` transition `com.apple.mobilephone` to a frontmost, user-interactive process.
- UIKit Mac Helper lifecycle logs move the app scene to foreground active.
- `Phone` logs through `com.apple.calls.facetime:AppController`, including "App icon clicked; requesting recents scene".
- The key-window responder is `CallsAppUI.RecentsViewController`, confirming that the default visible activation target is the recents scene.
- UI events target `FaceTimeMac.MacFaceTimeWindow`, matching the app's FaceTime-derived macOS shell.
- CoreSpotlight logs indexing batches from the app process.
- `ContinuityCaptureAgent` logs nearby iPhone capability state during the observation window; device identifier and name were redacted in the raw capture.
- On deactivation, `Phone` logs `AppController` handling `appDidResignActive`.

## Interpretation

The app-open path confirms that visible Phone activation can immediately touch:

- the app lifecycle layer (`com.apple.mobilephone` foreground scenes)
- FaceTime app-controller code
- Calls app UI recents controller
- FaceTimeMac window infrastructure
- CoreSpotlight indexing
- Continuity Capture/nearby-device capability observations

Inference: this supports the static dependency map: macOS `Phone.app` is a FaceTime/Calls shell whose visible default surface is recents, not a simple scriptable telephony database viewer. The capture did not show direct call-history row access or call-control XPC traffic at default log level during this short open-only pass.

## Limits

- This was an app-open observation, not dialing, URL handling, voicemail, call history mutation, call receiving, or controlled test-call activity.
- The predicate matched broad UIKit, RunningBoard, WindowServer, and input-event lifecycle noise.
- Additional behavior needs narrower controlled captures around one action at a time.

