#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e046.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( protected_curr_connections < storm_curr_connections )) || { echo "protection must reduce connection storm"; exit 1; }
(( protected_retry_rate_pct < storm_retry_rate_pct )) || { echo "protection must reduce retries"; exit 1; }
(( protected_connect_p99_ms < storm_connect_p99_ms )) || { echo "protection must improve connect p99"; exit 1; }
(( protected_error_rate_pct < storm_error_rate_pct )) || { echo "protection must reduce errors"; exit 1; }
[[ "$defense_backoff_jitter" == "ON" ]] || { echo "backoff+jitter defense missing"; exit 1; }

echo "[OK] E-046 assertions passed"
