#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

findings_file=$(mktemp "${TMPDIR:-/tmp}/spelunking-pii-findings.XXXXXX")
trap 'rm -f "$findings_file"' EXIT HUP INT TERM

scan_pattern() {
  label="$1"
  pattern="$2"

  matches=$(git -C "$REPO_ROOT" grep -n -I -E "$pattern" -- . \
    ':!scripts/repo-maintenance/validations/60-pii-safety.sh' 2>/dev/null || true)
  if [ -n "$matches" ]; then
    printf '%s\n' "$label" >>"$findings_file"
    printf '%s\n' "$matches" >>"$findings_file"
  fi
}

log "Checking tracked repository text for personal and machine-specific identifiers."

scan_pattern "Home-directory path" '/Users/[^/[:space:]]+|/home/[^/[:space:]]+'
scan_pattern "Email address" '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}'
scan_pattern "Phone number" '([+][0-9]{1,3}[ .-]?)?[(][0-9]{3}[)][ .-]?[0-9]{3}[ .-][0-9]{4}'
scan_pattern "Personal signing identity" 'Authority=(Apple Development|Developer ID Application):'
scan_pattern "Developer team identifier" 'TeamIdentifier=[A-Z0-9]{10}'
scan_pattern "Certificate fingerprint" '(certificate hash|SHA-1 fingerprint).*([0-9A-Fa-f]{40})'
scan_pattern "Known local identifier" 'GMBP16|G15PM|AMRC3N39SQ|BC73766F69|com[.]galewilliams|Gale Williams'

if [ -s "$findings_file" ]; then
  while IFS= read -r finding; do
    warn "$finding"
  done <"$findings_file"
  die "PII safety validation found personal or machine-specific identifiers in tracked files. Redact each reported value while preserving the technical result, then rerun validate-all.sh."
fi

log "Tracked repository text passed the PII safety checks."
