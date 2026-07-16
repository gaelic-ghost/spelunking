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
find /System/Library/PrivateFrameworks /System/iOSSupport/System/Library/PrivateFrameworks -maxdepth 3 \( -name '*.xpc' -o -name '*.appex' -o -name '*.app' -o -name 'LaunchServices' \) 2>/dev/null | rg 'IM|Message|MobileSMS|Phone|Call|Telephony|FaceTime' | sort
find /System/Library/LaunchAgents /System/Library/LaunchDaemons /Library/LaunchAgents /Library/LaunchDaemons -maxdepth 1 -type f \( -iname '*im*' -o -iname '*message*' -o -iname '*call*' -o -iname '*phone*' -o -iname '*telephony*' -o -iname '*facetime*' \) -print 2>/dev/null | sort
plutil -p /System/Library/LaunchAgents/com.apple.imagent.plist
plutil -p /System/Library/LaunchAgents/com.apple.imautomatichistorydeletionagent.plist
plutil -p /System/Library/LaunchAgents/com.apple.imtransferagent.plist
plutil -p /System/Library/PrivateFrameworks/IMDPersistence.framework/XPCServices/IMDPersistenceAgent.xpc/Contents/Info.plist
dyld_info -exports -objc -all_dyld_cache
xcrun --show-sdk-path --sdk iphoneos
xcrun --sdk iphoneos --show-sdk-version
find /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/Messages.framework -maxdepth 5 -type f
sed -n '1,240p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/Messages.framework/Headers/MSConversation.h
sed -n '1,260p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/Messages.framework/Headers/MSMessagesAppViewController.h
sed -n '1,220p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/Messages.framework/Headers/MSMessage.h
sed -n '1,260p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/MessageUI.framework/Headers/MFMessageComposeViewController.h
sed -n '1,180p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/MessageUI.framework/Headers/MFMessageComposeViewController+UPI.h
sed -n '1,260p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/SharedWithYouCore.framework/Headers/SWCollaborationMetadata.h
sed -n '1,220p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/SharedWithYouCore.framework/Headers/SWStartCollaborationAction.h
sed -n '1,220p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/SharedWithYouCore.framework/Headers/SWUpdateCollaborationParticipantsAction.h
rg -o '_\$s[^,[:space:]]+' /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore.tbd | tr -d "'" | swift-demangle
rg -o "_[A-Za-z0-9_]*(Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore.tbd
```

Privacy note: the SQLite commands captured table and column names only. No row data, message text, handles, attachment names, or counts were captured.

## Next Raw Captures

- dyld shared cache extraction command and output paths
- notification delivery classification
- logging baseline
