#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e018.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
failure_rebalance_count=18
failure_lag_peak=6200
failure_dedup_skip=210
success_rebalance_count=1
success_lag_peak=740
success_dedup_skip=18
STATS
