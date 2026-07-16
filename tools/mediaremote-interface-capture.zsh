#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
capture_root="research/MediaRemote/experiments/interfaces/$timestamp"
mkdir -p "$capture_root"

tool_log="$capture_root/swift-build.txt"
summary="$capture_root/summary.txt"

{
    echo "# MediaRemote interface capture"
    echo
    echo "timestamp_utc=$timestamp"
    echo "repo_root=$repo_root"
    echo "os_version=$(sw_vers -productVersion)"
    echo "os_build=$(sw_vers -buildVersion)"
    echo "xcode_select=$(xcode-select -p)"
    echo "swift_version=$(swift --version | head -n 1)"
    echo
    echo "Capture output is local-only and ignored by Git."
} > "$summary"

echo "Building mr-interface-probe..."
swift build --product mr-interface-probe > "$tool_log" 2>&1

run_group() {
    local name="$1"
    shift

    local output="$capture_root/$name.txt"
    {
        echo "# $name"
        echo
        echo "command: swift run mr-interface-probe $*"
        echo
        swift run mr-interface-probe "$@"
    } > "$output" 2>&1
}

run_group all

run_group now-playing-requests \
    MRNowPlayingPlayerClientRequests \
    MRNowPlayingPlayerClient \
    MRNowPlayingPlayerResponse \
    MRNowPlayingState \
    MRPlaybackQueueRequest \
    MRPlaybackQueue \
    MRPlaybackQueueClient

run_group origin-client \
    MRNowPlayingOriginClientManager \
    MRNowPlayingOriginClient \
    MRNowPlayingClient \
    MRNowPlayingClientRequests \
    MRPlayerPath \
    MRPlayer \
    MROrigin \
    MRClient

run_group controller-xpc \
    MRNowPlayingController \
    MRNowPlayingControllerConfiguration \
    MRXPCConnection

{
    echo
    echo "outputs:"
    find "$capture_root" -maxdepth 1 -type f -name '*.txt' -print | sort
} >> "$summary"

echo "Captured MediaRemote runtime interfaces in $capture_root"
