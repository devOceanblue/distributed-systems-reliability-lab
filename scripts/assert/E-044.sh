#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e044.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( reshard_p99_ms > baseline_p99_ms )) || { echo "resharding p99 must spike over baseline"; exit 1; }
(( post_p99_ms < reshard_p99_ms )) || { echo "post p99 must recover after resharding"; exit 1; }
(( reshard_moved_ask > baseline_moved_ask )) || { echo "moved/ask must increase during resharding"; exit 1; }
(( reshard_timeout > baseline_timeout )) || { echo "timeouts must increase during resharding"; exit 1; }
(( post_error_rate_pct <= reshard_error_rate_pct )) || { echo "post error rate should not worsen"; exit 1; }

echo "[OK] E-044 assertions passed"
