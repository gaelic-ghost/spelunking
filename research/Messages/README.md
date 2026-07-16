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
mkdir -p research/Messages/storage
sqlite3 "$HOME/Library/Messages/chat.db" "SELECT m.name || '|' || p.cid || '|' || p.name || '|' || p.type || '|' || p.\"notnull\" || '|' || COALESCE(p.dflt_value, '') || '|' || p.pk FROM sqlite_schema AS m JOIN pragma_table_info(m.name) AS p WHERE m.type='table' ORDER BY m.name, p.cid;"
sqlite3 "$HOME/Library/Messages/chat.db" "SELECT type || '|' || name || '|' || tbl_name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type IN ('index','trigger','view') ORDER BY type, tbl_name, name;"
sqlite3 "$HOME/Library/Messages/chat.db" "SELECT type || '|' || name || '|' || tbl_name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type='table' ORDER BY name;"
sqlite3 "$HOME/Library/Messages/chat.db" \
  ".output research/Messages/storage/chatdb-relationships-macos-26.5.2.txt" \
  ".print # Messages chat.db relationship and lifecycle schema capture" \
  ".print # Captured on macOS 26.5.2 (25F84). Metadata only: no row data, no counts." \
  ".print ## relationship_tables" \
  "SELECT name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type='table' AND name IN ('chat_handle_join','chat_message_join','message_attachment_join','chat_recoverable_message_join','chat_service','chat_lookup','deleted_messages','sync_deleted_messages','sync_deleted_attachments','sync_deleted_chats','scheduled_messages_pending_cloudkit_delete','unsynced_removed_recoverable_messages') ORDER BY name;" \
  ".print ## foreign_keys" \
  "SELECT m.name || '|' || COALESCE(f.id, '') || '|' || COALESCE(f.seq, '') || '|' || COALESCE(f.\"table\", '') || '|' || COALESCE(f.\"from\", '') || '|' || COALESCE(f.\"to\", '') || '|' || COALESCE(f.on_update, '') || '|' || COALESCE(f.on_delete, '') || '|' || COALESCE(f.match, '') FROM sqlite_schema AS m LEFT JOIN pragma_foreign_key_list(m.name) AS f WHERE m.type='table' ORDER BY m.name, f.id, f.seq;" \
  ".print ## indexes" \
  "SELECT m.tbl_name || '|' || m.name || '|' || COALESCE(m.sql, '') FROM sqlite_schema AS m WHERE m.type='index' ORDER BY m.tbl_name, m.name;" \
  ".print ## triggers" \
  "SELECT tbl_name || '|' || name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type='trigger' ORDER BY tbl_name, name;" \
  ".output stdout"
sdef /System/Applications/Messages.app
mkdir -p research/Messages/surfaces
plutil -p /System/Applications/Messages.app/Contents/Info.plist
plutil -p /System/Applications/Messages.app/Contents/Extensions/MessagesActionExtension.appex/Contents/Info.plist
plutil -p "/System/Applications/Messages.app/Contents/PlugIns/Messages Assistant Extension.appex/Contents/Info.plist"
plutil -p "/System/Applications/Messages.app/Contents/PlugIns/Messages Reply Extension.appex/Contents/Info.plist"
plutil -p "/System/Applications/Messages.app/Contents/PlugIns/Messages Share Extension.appex/Contents/Info.plist"
plutil -p "/System/Applications/Messages.app/Contents/PlugIns/Messages Storage Management Extension.appex/Contents/Info.plist"
plutil -p /System/Applications/Messages.app/Contents/PlugIns/MessagesPluginNotificationExtension.appex/Contents/Info.plist
plutil -p /System/Applications/Messages.app/Contents/PlugIns/MessagesAppKitBridge.bundle/Contents/Info.plist
plutil -p /System/Applications/Messages.app/Contents/PlugIns/iChatDockTile.docktileplugin/Contents/Info.plist
codesign -d --entitlements :- /System/Applications/Messages.app
codesign -dv /System/Applications/Messages.app
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
swift run spelunk objc-runtime --image /System/Library/PrivateFrameworks/IMCore.framework/IMCore --image /System/Library/PrivateFrameworks/IMSharedUtilities.framework/IMSharedUtilities --image /System/Library/PrivateFrameworks/IMFoundation.framework/IMFoundation --prefix IM --methods --properties --protocols --json > research/Messages/runtime/objc-runtime-im-macos-26.5.2.json
swift run spelunk objc-runtime --image /System/Library/PrivateFrameworks/IMCore.framework/IMCore --image /System/Library/PrivateFrameworks/IMSharedUtilities.framework/IMSharedUtilities --image /System/Library/PrivateFrameworks/IMFoundation.framework/IMFoundation --prefix IM --prefix CK --methods --properties --protocols --json > research/Messages/runtime/objc-runtime-imcore-macos-26.5.2.json
swift run spelunk objc-runtime --image /System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence --image /System/Library/PrivateFrameworks/IMDaemonCore.framework/IMDaemonCore --image /System/Library/PrivateFrameworks/MessagesKit.framework/MessagesKit --prefix IMD --prefix IMDaemon --prefix IMChat --prefix IMMessage --prefix IMHandle --prefix CKConversation --prefix CKTranscript --prefix CKMessage --prefix CKChat --prefix CKPlugin --prefix CKSMS --methods --properties --protocols --json > research/Messages/runtime/objc-runtime-imd-messageskit-macos-26.5.2.json
mkdir -p research/Messages/notifications
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMCore.framework/Versions/A/IMCore.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMDPersistence.framework/Versions/A/IMDPersistence.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMDaemonCore.framework/Versions/A/IMDaemonCore.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMSharedUtilities.framework/Versions/A/IMSharedUtilities.tbd
plutil -p /System/Library/LaunchAgents/com.apple.imagent.plist
plutil -p /System/Library/LaunchAgents/com.apple.imautomatichistorydeletionagent.plist
plutil -p /System/Library/LaunchAgents/com.apple.imtransferagent.plist
notifyutil -g com.apple.imautomatichistorydeletionagent.prefchange
notifyutil -g com.apple.idstransfers.idslaunchnotification
notifyutil -g control.random.spelunking.nonexistent.26.5.2
command -v dyld_shared_cache_util || true
xcrun --find dyld_shared_cache_util 2>/dev/null || true
command -v class-dump || true
command -v class-dump-swift || true
command -v swift-reflection-dump || true
command -v jtool2 || true
command -v nm || true
command -v dyld_info || true
command -v otool || true
ls -la /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMDPersistence.framework/Versions/A
ls -la /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/IMDaemonCore.framework/Versions/A
ls -la /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/MessagesKit.framework/Versions/A
mkdir -p research/Messages/runtime
/usr/bin/log stream --style compact --level default --timeout 8 --predicate '(process == "Messages") OR (subsystem CONTAINS[c] "Messages") OR (subsystem CONTAINS[c] "MobileSMS") OR (subsystem CONTAINS[c] "IMDPersistence") OR (eventMessage CONTAINS[c] "Messages") OR (eventMessage CONTAINS[c] "MobileSMS")'
open -a Messages
mkdir -p research/Messages/surfaces
/usr/bin/log stream --style compact --level default --timeout 4 --predicate '(process == "Messages") OR (subsystem CONTAINS[c] "Messages") OR (subsystem CONTAINS[c] "MobileSMS") OR (eventMessage CONTAINS[c] "MobileSMS") OR (eventMessage CONTAINS[c] "Messages") OR (eventMessage CONTAINS[c] "LaunchServices")'
/usr/bin/open -g -u '<root Messages URL scheme>'
swift run spelunk string-constants --image /System/Library/PrivateFrameworks/IMCore.framework/IMCore --symbol '<notification symbol>' --json
swift run spelunk string-constants --image /System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence --symbol '<notification symbol>' --json
(sleep 1; /usr/bin/open -g -a Messages) & swift run spelunk notification-observe --seconds 6 --darwin com.apple.idstransfers.idslaunchnotification --darwin com.apple.imautomatichistorydeletionagent.prefchange --distributed IMMessageSentDistributedNotification --json > research/Messages/notifications/observer-app-open-macos-26.5.2.json
file /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.map
rg -n '(/System/Library/PrivateFrameworks/(IMCore|IMDPersistence|IMDaemonCore|MessagesKit)\.framework|/System/iOSSupport/System/Library/PrivateFrameworks/IM(Core|DPersistence)\.framework)' /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.map
find /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks -maxdepth 4 \( -name '*.swiftinterface' -o -name '*.private.swiftinterface' -o -name '*.swiftmodule' \) | rg '/(IMCore|IMDPersistence|IMDaemonCore|MessagesKit)\.framework/' | sort
find /System/Library/PrivateFrameworks -maxdepth 3 \( -name '*.swiftinterface' -o -name '*.private.swiftinterface' -o -name '*.swiftmodule' \) 2>/dev/null | rg '/(IMCore|IMDPersistence|IMDaemonCore|MessagesKit)\.framework/' | sort
```

Privacy note: the SQLite commands captured table and column names only. The app-open and URL-scheme log streams were bounded to root URLs and activation behavior. No row data, message text, handles, recipients, attachment names, or counts were intentionally captured.

## Next Raw Captures

- dyld shared cache extraction with a capable external/local extractor
- generated interfaces for IM private frameworks after an extractor or equivalent metadata path is available
- controlled notification observer/logging proof for send/receive/test-thread flows
- logging baseline
