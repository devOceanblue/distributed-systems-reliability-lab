#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e047.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

[[ "$log_delivery_enabled" == "true" ]] || { echo "slow log delivery must be enabled"; exit 1; }
[[ "$cw_alarm_triggered" == "true" ]] || { echo "cloudwatch alarm flow must trigger"; exit 1; }
(( spike_p99_ms > baseline_p99_ms )) || { echo "p99 spike not reproduced"; exit 1; }
(( mitigated_p99_ms < spike_p99_ms )) || { echo "mitigation did not improve p99"; exit 1; }
(( slowlog_bigkey_hits + slowlog_blocking_lua_hits + slowlog_large_reply_hits > 0 )) || { echo "slowlog root cause should be detected"; exit 1; }

echo "[OK] E-047 assertions passed"
