#!/bin/sh
set -eu

print_header() {
    printf '\n## %s\n\n' "$1"
}

print_plist() {
    path="$1"

    printf '### %s\n\n' "$path"
    if [ -f "$path" ]; then
        plutil -p "$path"
    else
        printf 'missing\n'
    fi
}

print_plist_key() {
    plist="$1"
    key="$2"
    label="$3"

    value="$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true)"
    if [ -n "$value" ]; then
        printf '%s: %s\n' "$label" "$value"
    fi
}

print_appex_summary() {
    plist="$1"

    printf '### %s\n' "$plist"
    if [ ! -f "$plist" ]; then
        printf 'missing\n\n'
        return
    fi

    print_plist_key "$plist" 'CFBundleIdentifier' 'CFBundleIdentifier'
    print_plist_key "$plist" 'CFBundleExecutable' 'CFBundleExecutable'
    print_plist_key "$plist" 'NSExtension:NSExtensionPointIdentifier' 'NSExtensionPointIdentifier'
    print_plist_key "$plist" 'EXAppExtensionAttributes:EXExtensionPointIdentifier' 'EXExtensionPointIdentifier'
    print_plist_key "$plist" 'EXAppExtensionAttributes:EXPrincipalClass' 'EXPrincipalClass'
    printf '\n'
}

print_filtered_strings() {
    title="$1"
    binary="$2"
    limit="$3"

    printf '### %s\n\n' "$title"
    if [ ! -f "$binary" ]; then
        printf 'missing: %s\n' "$binary"
        return
    fi

    LC_ALL=C strings -a "$binary" |
        rg -i 'wallpaper|skip|reload|refresh|redraw|xpc|intent|appintent|control|widget|notification|distributed|darwin|defaults|UserDefaults|desktop|screen|export|helper|purge|metadata|service' |
        sed -n "1,${limit}p"
}

print_filtered_symbols() {
    title="$1"
    binary="$2"
    pattern="$3"
    limit="$4"

    printf '### %s\n\n' "$title"
    if [ ! -f "$binary" ]; then
        printf 'missing: %s\n' "$binary"
        return
    fi

    nm -j "$binary" 2>/dev/null |
        swift demangle |
        rg -i "$pattern" |
        sed -n "1,${limit}p"
}

print_header 'Launchd surfaces'
print_plist /System/Library/LaunchAgents/com.apple.wallpaper.plist
print_plist /System/Library/LaunchDaemons/com.apple.wallpaper.export.plist

print_header 'WallpaperAgent bundled extensions'
for plist in /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/*.appex/Contents/Info.plist; do
    print_appex_summary "$plist"
done

print_header 'ExtensionKit wallpaper extensions'
find /System/Library/ExtensionKit/Extensions \
    -maxdepth 3 \
    -path '*Wallpaper*.appex/Contents/Info.plist' \
    -print |
    sort |
    while IFS= read -r plist; do
    print_appex_summary "$plist"
done

print_header 'Adjacent helper and diagnostic extensions'
print_plist /System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/XPCServices/WallpaperHelper.xpc/Contents/Info.plist
print_plist /System/Library/PrivateFrameworks/DiagnosticExtensions.framework/PlugIns/WallpaperDiagnosticExtension.appex/Contents/Info.plist

print_header 'Feature flags and logging preferences'
print_plist /System/Library/FeatureFlags/Domain/Wallpaper.plist
print_plist /System/Library/FeatureFlags/Domain/NeptuneWallpaper.plist
print_plist /System/Library/Preferences/Logging/Subsystems/com.apple.wallpaper.plist

print_header 'Filtered string evidence'
print_filtered_strings \
    'WallpaperControlsExtension strings' \
    /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperControlsExtension.appex/Contents/MacOS/WallpaperControlsExtension \
    220
print_filtered_strings \
    'WallpaperIntents strings' \
    /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperIntents.appex/Contents/MacOS/WallpaperIntents \
    240
print_filtered_strings \
    'WallpaperHelper strings' \
    /System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/XPCServices/WallpaperHelper.xpc/Contents/MacOS/WallpaperHelper \
    220
print_filtered_strings \
    'wallpaperexportd strings' \
    /usr/libexec/wallpaperexportd \
    240

print_header 'Filtered symbol evidence'
print_filtered_symbols \
    'WallpaperHelper symbols' \
    /System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/XPCServices/WallpaperHelper.xpc/Contents/MacOS/WallpaperHelper \
    'Wallpaper|Helper|remove|protocol|listener|delegate|xpc' \
    220
print_filtered_symbols \
    'wallpaperexportd symbols' \
    /usr/libexec/wallpaperexportd \
    'Wallpaper|Export|Idle|purge|listener|protocol|sender|xpc|preboot|metadata' \
    280
print_filtered_symbols \
    'WallpaperIntents symbols' \
    /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperIntents.appex/Contents/MacOS/WallpaperIntents \
    'Wallpaper|Intent|Set|Photo|Entity|Query|perform|showAsScreenSaver|thumbnail' \
    240
print_filtered_symbols \
    'WallpaperControlsExtension symbols' \
    /System/Library/CoreServices/WallpaperAgent.app/Contents/PlugIns/WallpaperControlsExtension.appex/Contents/MacOS/WallpaperControlsExtension \
    'Wallpaper|Skip|Shuffle|Control|Widget|perform|supports|Button' \
    220
