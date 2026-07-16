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
mkdir -p research/Phone/surfaces
plutil -p /System/Applications/Phone.app/Contents/Info.plist
plutil -p /System/Applications/Phone.app/Contents/PlugIns/FaceTimeMacHelper.bundle/Contents/Info.plist
plutil -p /System/Applications/Phone.app/Contents/PlugIns/PhoneDockTile.docktileplugin/Contents/Info.plist
plutil -p /System/Applications/Phone.app/Contents/PlugIns/RemotePeoplePicker.appex/Contents/Info.plist
plutil -p /System/Library/PrivateFrameworks/TelephonyUtilities.framework/PlugIns/PhoneIntentHandler.appex/Contents/Info.plist
codesign -d --entitlements :- /System/Applications/Phone.app
codesign -dv /System/Applications/Phone.app
otool -L /System/Applications/Phone.app/Contents/MacOS/Phone
find /System/Library/PrivateFrameworks /System/iOSSupport/System/Library/PrivateFrameworks -maxdepth 3 \( -name '*.xpc' -o -name '*.appex' -o -name '*.app' -o -name 'LaunchServices' \) 2>/dev/null | rg 'IM|Message|MobileSMS|Phone|Call|Telephony|FaceTime' | sort
find /System/Library/LaunchAgents /System/Library/LaunchDaemons /Library/LaunchAgents /Library/LaunchDaemons -maxdepth 1 -type f \( -iname '*im*' -o -iname '*message*' -o -iname '*call*' -o -iname '*phone*' -o -iname '*telephony*' -o -iname '*facetime*' \) -print 2>/dev/null | sort
plutil -p /System/Library/LaunchAgents/com.apple.callhistoryd.plist
plutil -p /System/Library/LaunchAgents/com.apple.CallHistoryPluginHelper.plist
plutil -p /System/Library/LaunchAgents/com.apple.CallHistorySyncHelper.plist
plutil -p /System/Library/LaunchAgents/com.apple.callintelligenced.plist
plutil -p /System/Library/LaunchAgents/com.apple.facetimemessagestored.plist
plutil -p /System/Library/LaunchAgents/com.apple.telephonyutilities.callservicesd.plist
plutil -p /System/Library/PrivateFrameworks/TelephonyUtilities.framework/PlugIns/PhoneIntentHandler.appex/Contents/Info.plist
dyld_info -exports -objc -all_dyld_cache
find "$HOME/Library" -maxdepth 5 \( -iname '*call*history*' -o -iname '*CallHistory*' -o -path '*CallHistoryDB*' \) -print 2>/dev/null
find "$HOME/Library" -maxdepth 5 \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) -print 2>/dev/null | rg -i 'call|phone|facetime|voicemail'
find "$HOME/Library/Containers" "$HOME/Library/Group Containers" -maxdepth 4 \( -iname '*Phone*' -o -iname '*FaceTime*' -o -iname '*Call*' -o -iname '*Telephony*' \) -print 2>/dev/null
sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" ".tables"
sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" "SELECT m.name || ':' || group_concat(p.name || ' ' || p.type, ', ') FROM sqlite_schema AS m JOIN pragma_table_info(m.name) AS p WHERE m.type='table' GROUP BY m.name ORDER BY m.name;"
plutil -p "$HOME/Library/Application Support/CallHistoryDB/com.apple.callhistory.databaseInfo.plist"
mkdir -p research/Phone/storage
sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" "SELECT m.name || '|' || p.cid || '|' || p.name || '|' || p.type || '|' || p.\"notnull\" || '|' || COALESCE(p.dflt_value, '') || '|' || p.pk FROM sqlite_schema AS m JOIN pragma_table_info(m.name) AS p WHERE m.type='table' ORDER BY m.name, p.cid;"
sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" "SELECT type || '|' || name || '|' || tbl_name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type IN ('index','trigger','view') ORDER BY type, tbl_name, name;"
sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" "SELECT type || '|' || name || '|' || tbl_name || '|' || COALESCE(sql, '') FROM sqlite_schema WHERE type='table' ORDER BY name;"
find /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/CallKit.framework -maxdepth 5 -type f
sed -n '1,260p' /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/LiveCommunicationKit.framework/Modules/LiveCommunicationKit.swiftmodule/arm64e-apple-ios.swiftinterface
rg -o '_\$s[^,[:space:]]+' /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/PhoneAppIntents.framework/Versions/A/PhoneAppIntents.tbd | tr -d "'" | swift-demangle
rg -o '_\$s[^,[:space:]]+' /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsXPC.framework/Versions/A/CallsXPC.tbd | tr -d "'" | swift-demangle
rg -o '_\$s[^,[:space:]]+' /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsPersistence.framework/Versions/A/CallsPersistence.tbd | tr -d "'" | swift-demangle
rg -o '_\$s[^,[:space:]]+' /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/TelephonyUtilities.framework/Versions/A/TelephonyUtilities.tbd | tr -d "'" | swift-demangle
rg -o "_[A-Za-z0-9_]*(Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/TelephonyUtilities.framework/Versions/A/TelephonyUtilities.tbd
rg -o "_[A-Za-z0-9_]*(Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallHistory.framework/Versions/A/CallHistory.tbd
swift run spelunk objc-runtime --image /System/Library/PrivateFrameworks/TelephonyUtilities.framework/TelephonyUtilities --image /System/Library/PrivateFrameworks/CallHistory.framework/CallHistory --image /System/Library/PrivateFrameworks/CallHistoryDB.framework/CallHistoryDB --image /System/Library/Frameworks/CallKit.framework/CallKit --prefix TU --prefix CH --prefix Call --prefix CX --prefix Phone --methods --properties --protocols --json > research/Phone/runtime/objc-runtime-callservices-macos-26.5.2.json
swift run spelunk objc-runtime --image /System/Library/PrivateFrameworks/CallsXPC.framework/CallsXPC --image /System/Library/PrivateFrameworks/CallsPersistence.framework/CallsPersistence --image /System/Library/PrivateFrameworks/PhoneAppIntents.framework/PhoneAppIntents --prefix Calls --prefix CX --prefix CH --prefix Phone --prefix TUMetadata --prefix TUCall --prefix TUDial --prefix TUHandle --methods --properties --protocols --json > research/Phone/runtime/objc-runtime-callsxpc-phoneintents-macos-26.5.2.json
mkdir -p research/Phone/notifications
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/TelephonyUtilities.framework/Versions/A/TelephonyUtilities.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallHistory.framework/Versions/A/CallHistory.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsXPC.framework/Versions/A/CallsXPC.tbd
rg -o "_[A-Za-z0-9_]*(Darwin|Distributed|Notification|Changed|Did[A-Za-z0-9_]*|Will[A-Za-z0-9_]*)" /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk/System/Library/PrivateFrameworks/CallsPersistence.framework/Versions/A/CallsPersistence.tbd
plutil -p /System/Library/LaunchAgents/com.apple.CallHistoryPluginHelper.plist
plutil -p /System/Library/LaunchAgents/com.apple.CallHistorySyncHelper.plist
plutil -p /System/Library/LaunchAgents/com.apple.telephonyutilities.callservicesd.plist
notifyutil -g com.apple.CallHistoryPluginHelper.launchnotification
notifyutil -g com.apple.callhistorysync.idslaunchnotification
notifyutil -g control.random.spelunking.nonexistent.26.5.2
```

Observed `sdef` result:

```text
sdef: couldn't get sdef for /System/Applications/Phone.app (error -192)
```

Privacy note: no call-history rows, phone numbers, contacts, voicemail metadata, or call content were captured.

## Next Raw Captures

- dyld shared cache extraction command and output paths
- generated interfaces for call private frameworks
- notification observer/logging proof
- logging baseline
