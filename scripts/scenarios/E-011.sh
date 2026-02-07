#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e011.stats"
reset_and_seed 1

total_requests="${E011_REQUESTS:-2000}"
failure_unique_keys=1
success_unique_keys=200

failure_hot_load=$((total_requests / failure_unique_keys))
success_hot_load=$((total_requests / success_unique_keys))

# Deterministic latency/qps model for hot key vs distributed key traffic.
failure_p95_ms=$((60 + (failure_hot_load / 3)))
failure_p99_ms=$((120 + (failure_hot_load / 2)))
success_p95_ms=$((30 + (success_hot_load / 3)))
success_p99_ms=$((50 + (success_hot_load / 2)))

failure_db_qps=$((200 + (failure_hot_load / 4)))
success_db_qps=$((80 + (success_hot_load / 4)))

cat > "$stats_file" <<STATS
total_requests=$total_requests
failure_unique_keys=$failure_unique_keys
success_unique_keys=$success_unique_keys
failure_p95_ms=$failure_p95_ms
failure_p99_ms=$failure_p99_ms
success_p95_ms=$success_p95_ms
success_p99_ms=$success_p99_ms
failure_db_qps=$failure_db_qps
success_db_qps=$success_db_qps
STATS
