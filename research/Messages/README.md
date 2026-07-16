# Messages Research

Raw captures, generated headers, command transcripts, and scratch notes for Messages research belong here.

## Current Evidence Pass

Date: 2026-07-16

Environment:

- macOS 26.5.2 build 25F84
- Xcode: `/Applications/Xcode-beta.app/Contents/Developer`
- SDK: macOS 27.0
- App: `/System/Applications/Messages.app`

Commands run:

```sh
sw_vers
xcode-select -p
xcrun --show-sdk-path --sdk macosx
xcrun --sdk macosx --show-sdk-version
find /System/Library/PrivateFrameworks /System/Library/Frameworks -maxdepth 1 \( -iname '*Message*' -o -iname '*IM*' -o -iname '*Telephony*' -o -iname '*Call*' -o -iname '*Phone*' \) -print | sort
find /Applications /System/Applications -maxdepth 3 \( -iname '*Phone*.app' -o -iname '*Messages*.app' -o -iname '*FaceTime*.app' \) -print 2>/dev/null | sort
find "$HOME/Library/Messages" -maxdepth 1 \( -name 'chat.db*' -o -name 'Attachments' \) -print 2>/dev/null
sqlite3 "$HOME/Library/Messages/chat.db" ".tables"
sqlite3 "$HOME/Library/Messages/chat.db" "SELECT m.name || ':' || group_concat(p.name || ' ' || p.type, ', ') FROM sqlite_schema AS m JOIN pragma_table_info(m.name) AS p WHERE m.type='table' GROUP BY m.name ORDER BY m.name;"
sdef /System/Applications/Messages.app
plutil -p /System/Applications/Messages.app/Contents/Info.plist
codesign -d --entitlements :- /System/Applications/Messages.app
otool -L /System/Applications/Messages.app/Contents/MacOS/Messages
```

Privacy note: the SQLite commands captured table and column names only. No row data, message text, handles, attachment names, or counts were captured.

## Next Raw Captures

- dyld shared cache extraction command and output paths
- filtered Swift demangle output for `IMCore`
- launchd/XPC service inventory
- notification/logging baseline

