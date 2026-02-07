#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e008.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( db_read_off > db_read_on )) || { echo "db reads should be higher without stampede protection"; exit 1; }

echo "[OK] E-008 assertions passed"
