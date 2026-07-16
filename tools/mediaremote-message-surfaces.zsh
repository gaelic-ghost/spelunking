#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

usage() {
  cat <<'EOF'
Usage: tools/mediaremote-message-surfaces.zsh [capture-root]

Extracts MediaRemote XPC/message evidence from an inventory capture into
research/MediaRemote/experiments/messages/<timestamp>/.

If capture-root is omitted, the newest research/MediaRemote/captures/*
directory is used.
EOF
}

if (( $# > 1 )); then
  usage >&2
  exit 64
fi

if (( $# == 1 )); then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
  esac
  capture_root="$1"
else
  capture_root="$(find research/MediaRemote/captures -maxdepth 1 -mindepth 1 -type d | sort | tail -n 1)"
fi

if [[ -z "${capture_root:-}" || ! -d "$capture_root" ]]; then
  printf 'missing capture root: %s\n' "${capture_root:-<none>}" >&2
  exit 66
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output_root="research/MediaRemote/experiments/messages/$timestamp"
mkdir -p "$output_root"

extract() {
  local output="$1"
  local pattern="$2"
  shift 2

  {
    printf '# %s\n\n' "$output"
    printf 'source_capture=%s\n' "$capture_root"
    printf 'pattern=%s\n\n' "$pattern"
    rg -n "$pattern" "$@" | sort || true
  } > "$output_root/$output"
}

extract \
  "xpc-keys.txt" \
  'MRXPC_[A-Z0-9_]+(?:_KEY|_DATA|_BLOCK|_TIMESTAMP|_PARTICIPANTS|_IDENTIFIERS|_STATE)?' \
  "$capture_root/dyld-cstrings.txt"

extract \
  "xpc-serialization-symbols.txt" \
  '_(MRAdd|MRCreate|MR.*FromXPCMessage|MR.*ToXPCMessage|MRCreateXPCMessage)' \
  "$capture_root/live-symbols.txt"

extract \
  "xpc-transport-symbols.txt" \
  '(MRXPCConnection|MRAVXPCPipeTransport|xpc_connection_send_message|xpc_connection_send_message_with_reply|xpc_connection_send_message_with_reply_sync)' \
  "$capture_root/live-symbols.txt" "$capture_root/dyld-imports.txt"

extract \
  "message-oslogstrings.txt" \
  '(XPC message|message with ID|not handled|No .* endpoint registered|No client module registered|Could not find connection|sendMessage|SendCommandXPC|Error encoding to XPC|Error decoding XPC|Could not send reply|Could not parse notification)' \
  "$capture_root/dyld-oslogstrings.txt"

extract \
  "request-response-oslogstrings.txt" \
  '(Cache Miss: Request|Request: %|Response: %|returned with error|returned <|returned for|MRPlaybackQueueParticipantRequest|playbackQueueRequest)' \
  "$capture_root/dyld-oslogstrings.txt"

extract \
  "cache-update-oslogstrings.txt" \
  '(UpdatingCache|clientProperties|playbackState|supportedCommands|playbackQueue|playerProperties|contentItem|volumeCapabilities|lastPlayingDate)' \
  "$capture_root/dyld-oslogstrings.txt"

extract \
  "daemon-request-handlers.txt" \
  '(handle[A-Za-z0-9_]*Request|relay[A-Za-z0-9_]*Request|sendPlaybackQueueResponse|subscribeToPlaybackQueue|updatePlaybackQueue|playbackQueueForRequest|createPlaybackQueueForRequest)' \
  "$capture_root/mediaremoted-strings-filtered.txt" "$capture_root/mediaremoted-policy-strings.txt"

extract \
  "message-protobuf-symbols.txt" \
  '(_MRMediaRemoteMessageProtobuf|_MRSetStateMessageProtobuf|_MRCommandOptionsProtobuf|_MRPlaybackSessionMigrateRequestProtobuf|_messageType|_playbackQueue|_playbackState)' \
  "$capture_root/live-symbols.txt"

{
  printf '# MediaRemote Message Surface Extraction\n\n'
  printf -- '- timestamp: %s\n' "$timestamp"
  printf -- '- source capture: %s\n' "$capture_root"
  printf -- '- output root: %s\n' "$output_root"
  printf '\n## Outputs\n\n'
  find "$output_root" -maxdepth 1 -type f -name '*.txt' -print | sort | sed 's/^/- /'
} > "$output_root/SUMMARY.md"

printf 'wrote %s\n' "$output_root"
