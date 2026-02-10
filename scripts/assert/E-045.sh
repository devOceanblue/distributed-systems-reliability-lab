#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e045.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

[[ "$api_type" == "test-failover" ]] || { echo "must use test-failover API"; exit 1; }
(( failover_p99_ms > baseline_p99_ms )) || { echo "failover p99 should spike"; exit 1; }
(( recovery_p99_ms < failover_p99_ms )) || { echo "recovery p99 should recover"; exit 1; }
(( failover_write_error_pct > baseline_write_error_pct )) || { echo "write errors should increase during failover"; exit 1; }
(( reconnect_seconds > 0 )) || { echo "reconnect time must be observed"; exit 1; }
(( ryw_violation_count == 0 )) || { echo "read-your-writes violation detected"; exit 1; }

echo "[OK] E-045 assertions passed"
