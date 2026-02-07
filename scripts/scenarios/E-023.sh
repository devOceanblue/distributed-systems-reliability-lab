#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e023.stats"
reset_and_seed 3

cat > "$stats_file" <<'STATS'
redis_unsafe_error_rate=0.32
redis_safe_error_rate=0.07
kafka_unsafe_error_rate=0.41
kafka_safe_error_rate=0.05
mysql_unsafe_error_rate=0.56
mysql_safe_error_rate=0.11
outbox_backlog_recovered=1
stale_serve_kept_reads=1
STATS
