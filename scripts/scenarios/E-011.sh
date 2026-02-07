#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e011.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
failure_p95_ms=480
failure_p99_ms=920
success_p95_ms=130
success_p99_ms=240
failure_db_qps=410
success_db_qps=95
STATS
