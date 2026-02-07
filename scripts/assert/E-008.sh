#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e008.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( db_read_off > db_read_on )) || { echo "db reads should be higher without stampede protection"; exit 1; }
(( db_qps_off > db_qps_on )) || { echo "db qps should be higher without stampede protection"; exit 1; }
(( p95_off_ms > p95_on_ms )) || { echo "p95 latency should improve with stampede protection"; exit 1; }
(( p99_off_ms > p99_on_ms )) || { echo "p99 latency should improve with stampede protection"; exit 1; }

echo "[OK] E-008 assertions passed"
