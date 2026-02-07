#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e013.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
failure_a_redis_db_mismatch=1
failure_b_stale_after_db_commit=1
success_invalidation_converged=1
STATS
