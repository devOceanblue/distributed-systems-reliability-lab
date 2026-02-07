#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e006.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( failure_dlq > 0 )) || { echo "failure variant should increase DLQ"; exit 1; }
[[ "$success_dlq" == "0" ]] || { echo "success variant should have zero DLQ"; exit 1; }
[[ "$success_projection" == "300" ]] || { echo "projection should converge in success variant"; exit 1; }

echo "[OK] E-006 assertions passed"
