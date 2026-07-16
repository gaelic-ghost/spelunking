#!/usr/bin/env zsh
set -euo pipefail

target_product="mr-internal-probe"
sign_identity="-"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
capture_root="research/MediaRemote/experiments/entitlements/${timestamp}"

usage() {
  cat <<'EOF'
Usage: tools/mediaremote-entitlement-experiment.zsh [--identity <identity|auto|->] [--target <swiftpm-product>]

Options:
  --identity  Codesign identity for private-entitlement variants.
              Use "-" for ad-hoc signing. Use "auto" to select the first
              Apple Development identity hash from `security find-identity`.
              Default: -
  --target    SwiftPM executable product to build and copy.
              Default: mr-internal-probe
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --identity)
      if (( $# < 2 )); then
        printf 'missing value for --identity\n' >&2
        exit 64
      fi
      sign_identity="$2"
      shift 2
      ;;
    --target)
      if (( $# < 2 )); then
        printf 'missing value for --target\n' >&2
        exit 64
      fi
      target_product="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

mkdir -p "${capture_root}/bin" "${capture_root}/entitlements"

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

write_capture_note() {
  local output="$1"
  shift

  log "capture: ${output}"
  {
    printf '%s\n' "$*"
    printf '\n[exit-status] 0\n'
  } > "${capture_root}/${output}"
}

select_auto_identity() {
  security find-identity -p codesigning -v \
    | awk '/Apple Development:/ {print $2; exit}'
}

write_entitlements() {
  local output="$1"
  shift

  {
    printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
    printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    printf '%s\n' '<plist version="1.0">'
    printf '%s\n' '<dict>'

    for key in "$@"; do
      printf '  <key>%s</key>\n' "${key}"
      printf '%s\n' '  <true/>'
    done

    printf '%s\n' '</dict>'
    printf '%s\n' '</plist>'
  } > "${output}"
}

run_variant() {
  local variant="$1"
  shift

  local binary="${capture_root}/bin/${target_product}-${variant}"
  local signed_variant=true
  cp "${product_path}" "${binary}"

  if (( $# > 0 )); then
    local entitlements="${capture_root}/entitlements/${variant}.plist"
    write_entitlements "${entitlements}" "$@"
    if ! run_capture_allow_failure "${variant}-codesign.txt" codesign --force --sign "${resolved_sign_identity}" --entitlements "${entitlements}" "${binary}"; then
      signed_variant=false
    fi
  fi

  run_capture_allow_failure "${variant}-signature-details.txt" codesign -dvvv "${binary}" || true
  run_capture_allow_failure "${variant}-embedded-entitlements.txt" codesign -d --entitlements - "${binary}" || true

  if [[ "${signed_variant}" == true ]]; then
    run_capture_allow_failure "${variant}-run.txt" "${binary}" || true
  else
    write_capture_note "${variant}-run.txt" "Skipped runtime execution because codesign did not apply the requested entitlement set."
  fi
}

run_capture "environment.txt" zsh -c "sw_vers && printf 'xcode-select: '; xcode-select -p && swift --version && command -v codesign && security find-identity -p codesigning -v"

resolved_sign_identity="${sign_identity}"
if [[ "${sign_identity}" == "auto" ]]; then
  resolved_sign_identity="$(select_auto_identity)"
  if [[ -z "${resolved_sign_identity}" ]]; then
    log "no Apple Development signing identity found for --identity auto" >&2
    exit 65
  fi
fi

run_capture "build.txt" swift build --product "${target_product}"

bin_dir="$(swift build --show-bin-path)"
product_path="${bin_dir}/${target_product}"

if [[ ! -x "${product_path}" ]]; then
  log "missing built product: ${product_path}" >&2
  exit 1
fi

run_variant "baseline"
run_variant "now-playing-read-access" "com.apple.mediaremote.now-playing-read-access"
run_variant "full-now-playing-read-access" "com.apple.mediaremote.full-now-playing-read-access"
run_variant "device-info" "com.apple.mediaremote.device-info"
run_variant "nowplaying-entitlement" "com.apple.nowplaying.entitlement"

run_capture_allow_failure "system-log-policy.txt" /usr/bin/log show --style compact --last 5m --predicate 'eventMessage CONTAINS[c] "mr-internal-probe" OR eventMessage CONTAINS[c] "mediaremote.now-playing-read-access" OR eventMessage CONTAINS[c] "full-now-playing-read-access" OR eventMessage CONTAINS[c] "com.apple.nowplaying.entitlement" OR eventMessage CONTAINS[c] "com.apple.mediaremote.device-info"' || true

{
  log "# MediaRemote Entitlement Experiment"
  log
  log "- timestamp: ${timestamp}"
  log "- capture root: ${capture_root}"
  log "- target product: ${target_product}"
  log "- product path: ${product_path}"
  log "- requested signing identity: ${sign_identity}"
  log "- resolved signing identity: ${resolved_sign_identity}"
  log
  log "## Variants"
  log
  log "- baseline: copied built product without extra experiment entitlements"
  log "- now-playing-read-access: com.apple.mediaremote.now-playing-read-access"
  log "- full-now-playing-read-access: com.apple.mediaremote.full-now-playing-read-access"
  log "- device-info: com.apple.mediaremote.device-info"
  log "- nowplaying-entitlement: com.apple.nowplaying.entitlement"
} > "${capture_root}/SUMMARY.md"

log "wrote ${capture_root}"
