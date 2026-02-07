#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e019.stats"
reset_and_seed 2

cat > "$stats_file" <<'STATS'
failure_dlq_count=95
failure_projection_recovery=0
success_dlq_count=3
success_projection_recovery=1
retry_attempt_detected=1
STATS
