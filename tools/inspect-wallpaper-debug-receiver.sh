#!/bin/sh
set -eu

agent="/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent"

print_header() {
    printf '\n## %s\n\n' "$1"
}

print_window() {
    title="$1"
    start="$2"
    end="$3"

    printf '### %s\n\n' "$title"
    otool -arch x86_64 -tV "$agent" |
        awk -v start="$start" -v end="$end" '$1 >= start && $1 <= end { print }'
}

print_header 'WallpaperDebugServer receiver imports'
nm -arch x86_64 -j "$agent" 2>/dev/null |
    sort -u |
    xcrun swift-demangle |
    rg 'WallpaperDebug(Request|Response|Service)|WallpaperDebugRequestMessage|WallpaperExtensionProxy\.handleDebugRequest|XPCListener|IncomingSessionRequest|XPCReceivedMessage\.(decode|handoffReply|reply)|XPCPeerHandler'

print_header 'WallpaperDebugServer strings'
otool -arch x86_64 -v -s __TEXT __cstring "$agent" |
    rg 'WallpaperDebug|debug\.listener|com\.apple\.wallpaper\.extension|No valid extension|Unable to handle request' -C 5

print_header 'Receiver disassembly windows'
print_window 'Decode and handoff path' '000000010009b400' '000000010009bc80'
print_window 'Extension dispatch and error-response path' '0000000100143f80' '0000000100144388'
print_window 'Extension lookup path' '0000000100144380' '0000000100144850'
