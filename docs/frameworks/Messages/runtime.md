# Messages Runtime Observations

## Scope

This page records bounded, read-only runtime observations from opening `Messages.app` on macOS 26.5.2. It complements static evidence from schemas, entitlements, symbols, and Objective-C runtime metadata.

Raw evidence:

- `research/Messages/runtime/open-logstream-macos-26.5.2.txt`

Capture command shape:

```sh
/usr/bin/log stream --style compact --level default --timeout 8 --predicate '(process == "Messages") OR (subsystem CONTAINS[c] "Messages") OR (subsystem CONTAINS[c] "MobileSMS") OR (subsystem CONTAINS[c] "IMDPersistence") OR (eventMessage CONTAINS[c] "Messages") OR (eventMessage CONTAINS[c] "MobileSMS")'
open -a Messages
```

No message text, handles, attachment names, row data, or transcript contents were intentionally captured.

## Activation Evidence

Observed on app activation:

- `runningboardd` and `WindowServer` transition `com.apple.MobileSMS` to a frontmost, user-interactive process.
- UIKit Mac Helper lifecycle logs move the app scene to foreground active.
- `Messages` initializes an App Intents focus-filter action named `ConversationListFocusFilterAction`.
- `imagent` logs `MarkAsRead+Msgs` activity and reports mark-read work with message GUIDs and chat identifiers rendered as `<private>`.
- `IMDPersistenceAgent` logs `com.apple.messages.IMDPCommandDispatcher` activity and database calls named `_IMDMessageRecordCopyAndMarkAsReadMessagesReceivedPriorToDateMatchingChatGUIDs`.
- `Messages` uses a `CKMessageEntryRichTextView` as the message-entry responder during activation.
- CoreSpotlight logs indexing batches from the app process.
- The app consults `com.apple.calls.communicationsfilter` cache entries during startup.

## Interpretation

The app-open path confirms that visible Messages activation can immediately touch:

- the app lifecycle layer (`com.apple.MobileSMS` foreground scenes)
- App Intents focus filtering
- `imagent`
- `IMDPersistenceAgent`
- database mark-read helpers
- Spotlight indexing
- communication filtering
- ChatKit-style message-entry UI classes

Inference: the observed activation path supports the architecture already implied by entitlements and type inventories: the app shell coordinates visible UI state, while daemon and persistence agents perform read-state and database work. This observation still does not prove a supported or entitlement-free third-party path to call those internals.

## Limits

- This was an app-open observation, not message send/receive, AppleScript send, URL handling, notification response, or controlled test-thread activity.
- The log predicate matched some broad UIKit, RunningBoard, and WindowServer lifecycle noise.
- Additional behavior needs narrower controlled captures around one action at a time.

