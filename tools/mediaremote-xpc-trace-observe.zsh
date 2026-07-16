#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

command=()

usage() {
  cat <<'EOF'
Usage: tools/mediaremote-xpc-trace-observe.zsh [-- <command> [args...]]

Builds the MediaRemote XPC send interposer, injects it into a probe process
with DYLD_INSERT_LIBRARIES, and runs the command through
tools/mediaremote-daemon-observe.zsh so probe output and daemon logs share one
capture window.

Default behavior:
  build MRXPCTraceInterpose and mr-internal-probe, then run mr-internal-probe
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

swift build --product MRXPCTraceInterpose

if (( ${#command[@]} == 0 )); then
  swift build --product mr-internal-probe
  bin_dir="$(swift build --show-bin-path)"
  command=("${bin_dir}/mr-internal-probe")
else
  bin_dir="$(swift build --show-bin-path)"
fi

interposer="${bin_dir}/libMRXPCTraceInterpose.dylib"

if [[ ! -f "$interposer" ]]; then
  printf 'missing built interposer: %s\n' "$interposer" >&2
  exit 1
fi

tools/mediaremote-daemon-observe.zsh -- env DYLD_INSERT_LIBRARIES="$interposer" "${command[@]}"
