#!/usr/bin/env sh
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export REPO_MAINTENANCE_COMMON_DIR="$SELF_DIR/../lib"
. "$SELF_DIR/../lib/common.sh"

command -v python3 >/dev/null 2>&1 || die "Markdown link validation could not find python3 on PATH. Install Python 3 before running validate-all.sh."

log "Checking repository Markdown for missing relative link targets."
python3 - "$REPO_ROOT" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

repo_root = Path(sys.argv[1]).resolve()
ignored_roots = {".build", ".git", ".swiftpm", "DerivedData"}
link_pattern = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
missing: list[str] = []

for markdown_path in sorted(repo_root.rglob("*.md")):
    relative_parts = markdown_path.relative_to(repo_root).parts
    if any(part in ignored_roots for part in relative_parts):
        continue

    text = markdown_path.read_text(encoding="utf-8", errors="replace")
    for line_number, line in enumerate(text.splitlines(), start=1):
        for match in link_pattern.finditer(line):
            raw_destination = match.group(1).strip()
            if raw_destination.startswith("<") and raw_destination.endswith(">"):
                raw_destination = raw_destination[1:-1]
            destination = raw_destination.split(maxsplit=1)[0]
            if not destination or destination.startswith(("#", "http://", "https://", "mailto:")):
                continue

            path_text = unquote(destination.split("#", 1)[0])
            if not path_text:
                continue

            if path_text.startswith("/"):
                target = (repo_root / path_text.lstrip("/")).resolve()
            else:
                target = (markdown_path.parent / path_text).resolve()
            if not target.exists():
                missing.append(
                    f"{markdown_path.relative_to(repo_root)}:{line_number}: "
                    f"relative Markdown link target does not exist: {destination}"
                )

if missing:
    for finding in missing:
        print(f"ERROR: {finding}", file=sys.stderr)
    raise SystemExit(1)

print("Markdown relative link targets are valid.")
PY
