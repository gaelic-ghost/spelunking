#!/bin/sh
set -eu

agent="/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent"
cache="/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05"

print_header() {
    printf '\n## %s\n\n' "$1"
}

print_header 'Wallpaper framework supporting type symbols'
tools/extract-wallpaper-symbols.sh |
    rg -i 'ContentType|AssertionValue|AssertionPresentationMode|ViewModelRefreshReason|AgentXPCSecurityPolicy|WallpaperXPCConnectionSecurityPolicy|checkAccess|allow\(process' -C 2

print_header 'WallpaperAgent supporting type strings'
LC_ALL=C strings -a -t x "$agent" |
    rg -i 'WallpaperStoreContentType|running-assertions|ContentDescriptor type=|type=extension|type=screensaver|type=inprocess|desktop$|screenSaver$|idle$|linked$|system$|extension$|inProcess$|presentationMode|clientAssertionsChanged|Added Client Assertion|Removed Client Assertion|Unknown XPC Sender|Remote process .*attempting to connect|Unable to access extension' -C 4

print_header 'Dyld-cache Wallpaper coding-key strings'
if [ -f "$cache" ]; then
    strings -a "$cache" |
        rg -A 80 -B 20 'AgentXPCSecurityPolicy|AssertionPresentationMode|AssertionValue|WallpaperDisplayAttributes|WallpaperContentSettings|ContentType|DesktopCodingKeys|ScreenSaverCodingKeys|AgentXPCProtocol|AgentXPCMessage|ViewModelRefreshReason'
else
    printf 'missing: %s\n' "$cache" >&2
    exit 1
fi
