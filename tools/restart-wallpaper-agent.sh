#!/bin/sh
# Restart the current user's WallpaperAgent without relying on launchctl kickstart.
# This is private, local-only research tooling for macOS 26.5.2.

set -eu

job="gui/$(id -u)/com.apple.wallpaper.agent"
before_pid=$(launchctl print "$job" 2>/dev/null | awk '/^[[:space:]]*pid = / { gsub(/;/, "", $3); print $3; exit }')

if [ -z "$before_pid" ]; then
    printf '%s\n' "WallpaperAgent is not running in the current Aqua session ($job)." >&2
    exit 1
fi

if ! kill -TERM "$before_pid"; then
    printf '%s\n' "WallpaperAgent PID $before_pid did not accept SIGTERM; its launchd job was not changed." >&2
    exit 1
fi

attempt=0
while [ "$attempt" -lt 10 ]; do
    attempt=$((attempt + 1))
    sleep 1
    after_pid=$(launchctl print "$job" 2>/dev/null | awk '/^[[:space:]]*pid = / { gsub(/;/, "", $3); print $3; exit }')
    if [ -n "${after_pid:-}" ] && [ "$after_pid" != "$before_pid" ]; then
        printf '%s\n' "WallpaperAgent restarted: PID $before_pid -> $after_pid."
        exit 0
    fi
done

printf '%s\n' "WallpaperAgent accepted SIGTERM but launchd did not report a replacement PID within 10 seconds." >&2
exit 1
