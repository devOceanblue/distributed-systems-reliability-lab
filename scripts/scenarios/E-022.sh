#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e022.stats"
reset_and_seed 5

"$ROOT_DIR/scripts/data/gen-backfill.sh" 5000 >/dev/null

cat > "$stats_file" <<'STATS'
unsafe_db_qps=1100
unsafe_consumer_lag=8200
safe_db_qps=260
safe_consumer_lag=950
resume_supported=1
sampling_validation_passed=1
STATS
