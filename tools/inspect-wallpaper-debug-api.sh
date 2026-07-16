#!/bin/sh
set -eu

print_header() {
    printf '\n## %s\n\n' "$1"
}

print_header 'Wallpaper debug API exports from dyld shared cache'
xcrun dyld_info -exports -all_dyld_cache |
    xcrun swift-demangle |
    rg 'WallpaperTypes\.Wallpaper(Debug|Asset)|WallpaperExtensionKit\.WallpaperExtension(DebugHandler|Proxy)\.handleDebugRequest'
