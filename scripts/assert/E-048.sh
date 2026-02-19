#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e048.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

(( slow_consumer_freeable_memory_mb < baseline_freeable_memory_mb )) || { echo "slow consumer must pressure memory"; exit 1; }
(( isolated_freeable_memory_mb > slow_consumer_freeable_memory_mb )) || { echo "mitigation should recover memory"; exit 1; }
(( isolated_reconnect_rate_pct < slow_consumer_reconnect_rate_pct )) || { echo "mitigation should reduce reconnect storm"; exit 1; }
(( isolated_dropped_messages < slow_consumer_dropped_messages )) || { echo "mitigation should reduce dropped messages"; exit 1; }
[[ "$mitigation_pubsub_isolation" == "true" ]] || { echo "pubsub isolation mitigation missing"; exit 1; }

echo "[OK] E-048 assertions passed"
