#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e007.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
rg -q "read_uncommitted_visible=1" "$STATS_FILE" || { echo "missing read_uncommitted marker"; exit 1; }
rg -q "read_committed_stall=1" "$STATS_FILE" || { echo "missing read_committed stall marker"; exit 1; }
rg -q "resolved_after_commit_or_abort=1" "$STATS_FILE" || { echo "missing resolution marker"; exit 1; }

echo "[OK] E-007 assertions passed"
