#!/usr/bin/env zsh
set -euo pipefail

target="${1:-MediaRemote}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
capture_root="research/${target}/captures/${timestamp}"
framework="/System/Library/PrivateFrameworks/${target}.framework/Versions/A/${target}"
sdk_current="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/PrivateFrameworks/${target}.framework/${target}.tbd"
sdk_beta="/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/PrivateFrameworks/${target}.framework/${target}.tbd"
symbols_tool="$(xcrun --find symbols 2>/dev/null || true)"

mkdir -p "${capture_root}"

log() {
  printf '%s\n' "$*"
}

run_capture() {
  local output="$1"
  shift

  log "capture: ${output}"
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } > "${capture_root}/${output}" 2>&1
}

extract_dyld_symbols() {
  awk '/ 0x[0-9A-Fa-f]+  _/ {print $2}' "$1" | sort -u
}

extract_tbd_names() {
  grep -o '_[A-Za-z][A-Za-z0-9_]*' "$1" | sort -u
}

run_capture "dyld-exports.txt" dyld_info -exports "${framework}"
run_capture "dyld-imports.txt" dyld_info -imports "${framework}"
run_capture "dyld-linked-dylibs.txt" dyld_info -linked_dylibs "${framework}"
run_capture "dyld-dlopen-dlsym.txt" dyld_info -dlopens -dlsyms "${framework}"
run_capture "dyld-load-commands.txt" dyld_info -load_commands "${framework}"
run_capture "dyld-function-starts.txt" dyld_info -function_starts "${framework}"
run_capture "dyld-cstrings.txt" dyld_info -section __TEXT __cstring "${framework}"
run_capture "dyld-oslogstrings.txt" dyld_info -section __TEXT __oslogstring "${framework}"
run_capture "dyld-objc-classnames.txt" dyld_info -section __TEXT __objc_classname "${framework}"
run_capture "dyld-objc-method-names.txt" dyld_info -section __TEXT __objc_methname "${framework}"
run_capture "dyld-objc-method-types.txt" dyld_info -section __TEXT __objc_methtype "${framework}"

if [[ -n "${symbols_tool}" ]]; then
  run_capture "symbols-nowplaying-targets.txt" "${symbols_tool}" -arch arm64e -noHeaders -noRegions -noSources \
    -lookup '*MRMediaRemoteGetNowPlayingInfo*' \
    -lookup '*MRMediaRemoteRequestNowPlayingPlaybackQueue*' \
    -lookup '*MRNowPlayingOriginClient*' \
    -lookup '*MRNowPlayingPlayerClient*' \
    -lookup '*MRNowPlayingClientRequests*' \
    -lookup '*MRXPC*' \
    "${framework}"
fi

if [[ -f "${sdk_current}" ]]; then
  run_capture "sdk-current-tbd.txt" sed -n '1,240p' "${sdk_current}"
fi

if [[ -f "${sdk_beta}" ]]; then
  run_capture "sdk-beta-tbd.txt" sed -n '1,240p' "${sdk_beta}"
fi

if [[ "${target}" == "MediaRemote" ]]; then
  support_dir="/System/Library/PrivateFrameworks/MediaRemote.framework/Support"
  for binary in mediaremoted mediaremoteagent; do
    binary_path="${support_dir}/${binary}"

    if [[ -x "${binary_path}" ]]; then
      run_capture "${binary}-otool-linked-dylibs.txt" otool -L "${binary_path}"
      run_capture "${binary}-entitlements.xml" codesign -d --entitlements - "${binary_path}"
      run_capture "${binary}-strings-filtered.txt" zsh -c "strings -a ${(q)binary_path} | rg -i 'com\\.apple|mediaremote|xpc|notification|nowplaying|route|command|playback|endpoint|output|origin|player|spotify|music|airplay|rapport|ids|session' || true"
    fi
  done

  if [[ -f "/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/Resources/Info.plist" ]]; then
    run_capture "framework-info-plist.txt" plutil -p "/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/Resources/Info.plist"
  fi

  if [[ -f "/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/Resources/RemoteControlBlacklist.plist" ]]; then
    run_capture "remote-control-blacklist.txt" plutil -p "/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/Resources/RemoteControlBlacklist.plist"
  fi
fi

extract_dyld_symbols "${capture_root}/dyld-exports.txt" > "${capture_root}/live-symbols.txt"

if [[ -f "${sdk_current}" ]]; then
  extract_tbd_names "${sdk_current}" > "${capture_root}/sdk-current-symbols.txt"
  comm -23 "${capture_root}/live-symbols.txt" "${capture_root}/sdk-current-symbols.txt" > "${capture_root}/live-only-vs-current-sdk.txt"
  comm -13 "${capture_root}/live-symbols.txt" "${capture_root}/sdk-current-symbols.txt" > "${capture_root}/current-sdk-only-vs-live.txt"
fi

if [[ -f "${sdk_beta}" ]]; then
  extract_tbd_names "${sdk_beta}" > "${capture_root}/sdk-beta-symbols.txt"
  comm -23 "${capture_root}/live-symbols.txt" "${capture_root}/sdk-beta-symbols.txt" > "${capture_root}/live-only-vs-beta-sdk.txt"
  comm -13 "${capture_root}/live-symbols.txt" "${capture_root}/sdk-beta-symbols.txt" > "${capture_root}/beta-sdk-only-vs-live.txt"
fi

{
  log "# ${target} Inventory Capture"
  log
  log "- timestamp: ${timestamp}"
  log "- capture root: ${capture_root}"
  log "- framework: ${framework}"
  log "- selected developer directory: $(xcode-select -p 2>/dev/null || true)"
  log "- live symbols: $(wc -l < "${capture_root}/live-symbols.txt" | tr -d ' ')"

  if [[ -f "${capture_root}/sdk-current-symbols.txt" ]]; then
    log "- current SDK symbols: $(wc -l < "${capture_root}/sdk-current-symbols.txt" | tr -d ' ')"
    log "- live-only vs current SDK: $(wc -l < "${capture_root}/live-only-vs-current-sdk.txt" | tr -d ' ')"
    log "- current SDK-only vs live: $(wc -l < "${capture_root}/current-sdk-only-vs-live.txt" | tr -d ' ')"
  fi

  if [[ -f "${capture_root}/sdk-beta-symbols.txt" ]]; then
    log "- beta SDK symbols: $(wc -l < "${capture_root}/sdk-beta-symbols.txt" | tr -d ' ')"
    log "- live-only vs beta SDK: $(wc -l < "${capture_root}/live-only-vs-beta-sdk.txt" | tr -d ' ')"
    log "- beta SDK-only vs live: $(wc -l < "${capture_root}/beta-sdk-only-vs-live.txt" | tr -d ' ')"
  fi
} > "${capture_root}/SUMMARY.md"

log "wrote ${capture_root}"
