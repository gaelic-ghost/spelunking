#!/usr/bin/env zsh
set -euo pipefail

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
capture_root="research/MediaRemote/experiments/daemon-observation/${timestamp}"
default_product="mr-internal-probe"
command=()

usage() {
  cat <<'EOF'
Usage: tools/mediaremote-daemon-observe.zsh [-- <command> [args...]]

Runs a MediaRemote probe command, then captures focused unified-log evidence
from mediaremoted, mediaremoteagent, AMFI/taskgated, and probe-related events
for the same wall-clock window.

Default behavior:
  build mr-internal-probe, then run the built product directly
EOF
}

if (( $# > 0 )); then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      if (( $# == 0 )); then
        printf 'missing command after --\n' >&2
        exit 64
      fi
      command=("$@")
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
fi

mkdir -p "${capture_root}"

log() {
  printf '%s\n' "$*"
}

run_capture() {
  local output="$1"
  local command_status
  shift

  log "capture: ${output}"
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
    command_status="$?"
    printf '\n[exit-status] %s\n' "${command_status}"
  } > "${capture_root}/${output}" 2>&1

  return "${command_status}"
}

run_capture_allow_failure() {
  local output="$1"
  shift

  set +e
  run_capture "${output}" "$@"
  local command_status="$?"
  set -e

  if (( command_status != 0 )); then
    log "capture: ${output} exited with status ${command_status}"
  fi

  return "${command_status}"
}

run_capture "environment.txt" zsh -c "sw_vers && printf 'xcode-select: '; xcode-select -p && swift --version && command -v log"
run_capture_allow_failure "spotify-state.txt" osascript -e 'tell application "Spotify"' -e 'set playbackState to player state as string' -e 'set currentTrack to artist of current track & " - " & name of current track' -e 'return playbackState & "\n" & currentTrack' -e 'end tell' || true

if (( ${#command[@]} == 0 )); then
  run_capture "build.txt" swift build --product "${default_product}"
  bin_dir="$(swift build --show-bin-path)"
  product_path="${bin_dir}/${default_product}"

  if [[ ! -x "${product_path}" ]]; then
    log "missing built product: ${product_path}" >&2
    exit 1
  fi

  command=("${product_path}")
fi

start_time="$(date '+%Y-%m-%d %H:%M:%S')"
start_epoch="$(date +%s)"

run_capture_allow_failure "probe-run.txt" "${command[@]}" || true

sleep 2

end_time="$(date '+%Y-%m-%d %H:%M:%S')"
end_epoch="$(date +%s)"

predicate='process == "mediaremoted" OR process == "mediaremoteagent" OR process == "amfid" OR process == "taskgated-helper" OR eventMessage CONTAINS[c] "mr-internal-probe" OR eventMessage CONTAINS[c] "mr-now-playing-probe" OR eventMessage CONTAINS[c] "mr-route-probe" OR eventMessage CONTAINS[c] "MRDMediaRemoteClient" OR eventMessage CONTAINS[c] "Operation not permitted" OR eventMessage CONTAINS[c] "playbackQueue" OR eventMessage CONTAINS[c] "playerProperties" OR eventMessage CONTAINS[c] "mediaPlaybackVolume" OR eventMessage CONTAINS[c] "volumeControlCapabilities" OR eventMessage CONTAINS[c] "getSystemIsMuted" OR eventMessage CONTAINS[c] "ConcreteOutputContext" OR subsystem CONTAINS[c] "mediaremote"'

run_capture_allow_failure "unified-log.txt" /usr/bin/log show --style compact --start "${start_time}" --end "${end_time}" --predicate "${predicate}" || true
run_capture_allow_failure "daemon-highlights.txt" zsh -c "rg -n 'Adding client|Removing client|invalidated|entitlements=|NowPlaying|not entitled|Operation not permitted|playbackQueue|playerProperties|mediaPlaybackVolume|volumeControlCapabilities|getSystemIsMuted|ConcreteOutputContext|request|load code signature|Unsatisfied entitlements|AMFI|taskgated' ${(q)capture_root}/unified-log.txt || true"

{
  log "# MediaRemote Daemon Observation"
  log
  log "- timestamp: ${timestamp}"
  log "- capture root: ${capture_root}"
  log "- start local time: ${start_time}"
  log "- end local time: ${end_time}"
  log "- duration seconds: $(( end_epoch - start_epoch ))"
  log "- command:"
  printf '  -'
  printf ' %q' "${command[@]}"
  printf '\n'
} > "${capture_root}/SUMMARY.md"

log "wrote ${capture_root}"
