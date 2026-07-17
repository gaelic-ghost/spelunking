#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

log "Checking repo-maintenance shell syntax."
find "$REPO_MAINTENANCE_ROOT" -type f -name '*.sh' -exec sh -n {} \;

log "Checking strict SemVer tag handling."
for valid_tag in \
  v0.0.0 \
  v1.2.3 \
  v1.2.3-alpha \
  v1.2.3-alpha.1 \
  v1.2.3+build.5 \
  v1.2.3-rc.1+build.5
do
  is_valid_semver_tag "$valid_tag" || die "Strict SemVer validation rejected valid tag $valid_tag."
done

for invalid_tag in \
  1.2.3 \
  v1.2 \
  v01.2.3 \
  v1.02.3 \
  v1.2.03 \
  v1.2.3- \
  v1.2.3-01 \
  v1.2.3+ \
  v1.2.3_alpha
do
  if is_valid_semver_tag "$invalid_tag"; then
    die "Strict SemVer validation accepted invalid tag $invalid_tag."
  fi
done

log "Repo-maintenance shell syntax and SemVer checks passed."
