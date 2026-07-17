#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

command -v swift >/dev/null 2>&1 || die "Swift package validation could not find the Swift CLI on PATH. Select an Xcode command-line toolchain before running validate-all.sh."

log "Building the Spelunking Swift package."
(cd "$REPO_ROOT" && swift build)

log "Testing the Spelunking Swift package after the build completed."
(cd "$REPO_ROOT" && swift test)
