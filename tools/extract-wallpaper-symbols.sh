#!/bin/sh
set -eu

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
private_frameworks="$sdk_path/System/Library/PrivateFrameworks"

demangle_module_symbols() {
    module_name="$1"
    tbd_path="$2"
    pattern="$3"

    printf '\n## %s\n\n' "$module_name"
    if [ ! -f "$tbd_path" ]; then
        printf 'missing: %s\n' "$tbd_path" >&2
        return 1
    fi

    rg -o "_\\\$s[0-9A-Za-z_]+" "$tbd_path" |
        cut -d: -f2- |
        sort -u |
        xcrun swift-demangle |
        rg "$pattern"
}

demangle_binary_symbols() {
    title="$1"
    binary_path="$2"
    pattern="$3"

    printf '\n## %s\n\n' "$title"
    if [ ! -f "$binary_path" ]; then
        printf 'missing: %s\n' "$binary_path" >&2
        return 1
    fi

    nm -j "$binary_path" 2>/dev/null |
        sort -u |
        xcrun swift-demangle |
        rg "$pattern"
}

demangle_module_symbols \
    "Wallpaper normal agent protocol" \
    "$private_frameworks/Wallpaper.framework/Versions/A/Wallpaper.tbd" \
    "AgentXPCProtocol|AgentXPCMessage|AgentXPCSecurityPolicy|ContentType|ViewModelRefreshReason|AssertionValue|AssertionPresentationMode|ensureViewModelIsUpToDate|diagnosticState|snapshotAllSpaces|skipShuffledContent|canSkipShuffledContent"

demangle_module_symbols \
    "WallpaperTypes debug protocol" \
    "$private_frameworks/WallpaperTypes.framework/Versions/A/WallpaperTypes.tbd" \
    "WallpaperDebug(Request|Response|RequestMessage|AssetType)|WallpaperAsset(List|DownloadState)|WallpaperChoiceRequest|WallpaperSettingsViewModel"

demangle_module_symbols \
    "WallpaperExtensionKit bridge" \
    "$private_frameworks/WallpaperExtensionKit.framework/Versions/A/WallpaperExtensionKit.tbd" \
    "handleDebugRequest|DebugRequest|DebugResponse|invalidateSnapshots|HostProxy|WallpaperProxy|ExportedObject|XPC"

demangle_binary_symbols \
    "WallpaperAgent debug receiver imports" \
    "/System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent" \
    "WallpaperDebug(Request|Response|Service)|WallpaperDebugRequestMessage|WallpaperExtensionProxy\\.handleDebugRequest|XPCListener|IncomingSessionRequest|XPCReceivedMessage\\.(decode|handoffReply|reply)|XPCPeerHandler|AgentXPCProtocol|ensureViewModelIsUpToDate"
