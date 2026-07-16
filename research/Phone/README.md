# Phone Research

Raw captures, generated headers, command transcripts, and scratch notes for Phone research belong here.

## Current Evidence Pass

Date: 2026-07-16

Environment:

- macOS 26.5.2 build 25F84
- Xcode: `/Applications/Xcode-beta.app/Contents/Developer`
- SDK: macOS 27.0
- App: `/System/Applications/Phone.app`

Commands run:

```sh
sw_vers
xcode-select -p
xcrun --show-sdk-path --sdk macosx
xcrun --sdk macosx --show-sdk-version
find /System/Library/PrivateFrameworks /System/Library/Frameworks -maxdepth 1 \( -iname '*Message*' -o -iname '*IM*' -o -iname '*Telephony*' -o -iname '*Call*' -o -iname '*Phone*' \) -print | sort
find /Applications /System/Applications -maxdepth 3 \( -iname '*Phone*.app' -o -iname '*Messages*.app' -o -iname '*FaceTime*.app' \) -print 2>/dev/null | sort
sdef /System/Applications/Phone.app
plutil -p /System/Applications/Phone.app/Contents/Info.plist
codesign -d --entitlements :- /System/Applications/Phone.app
otool -L /System/Applications/Phone.app/Contents/MacOS/Phone
```

Observed `sdef` result:

```text
sdef: couldn't get sdef for /System/Applications/Phone.app (error -192)
```

Privacy note: no call-history rows, phone numbers, contacts, voicemail metadata, or call content were captured.

## Next Raw Captures

- call-history storage location and schema-only inventory
- dyld shared cache extraction command and output paths
- filtered Swift demangle output for call frameworks
- launchd/XPC service inventory
- notification/logging baseline

