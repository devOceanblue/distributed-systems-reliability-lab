#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e018.stats"
reset_and_seed 1

simulate_rebalance() {
  local max_poll_interval_ms="$1"
  local max_poll_records="$2"
  local processing_delay_ms="$3"
  local workload_records="$4"

  local batch_processing_ms=$((max_poll_records * processing_delay_ms))
  local rebalance_count=0
  if (( batch_processing_ms > max_poll_interval_ms )); then
    rebalance_count=$((batch_processing_ms / max_poll_interval_ms))
  fi
  local lag_peak=$(( (workload_records * batch_processing_ms) / max_poll_interval_ms + rebalance_count * 200 ))
  local dedup_skip=$(( rebalance_count * max_poll_records / 5 ))

  printf '%s\t%s\t%s\n' "$rebalance_count" "$lag_peak" "$dedup_skip"
}

workload_records="${E018_WORKLOAD_RECORDS:-10000}"

IFS=$'\t' read -r failure_rebalance_count failure_lag_peak failure_dedup_skip < <(simulate_rebalance 3000 500 20 "$workload_records")
IFS=$'\t' read -r success_rebalance_count success_lag_peak success_dedup_skip < <(simulate_rebalance 60000 50 20 "$workload_records")

cat > "$stats_file" <<STATS
workload_records=$workload_records
failure_rebalance_count=$failure_rebalance_count
failure_lag_peak=$failure_lag_peak
failure_dedup_skip=$failure_dedup_skip
success_rebalance_count=$success_rebalance_count
success_lag_peak=$success_lag_peak
success_dedup_skip=$success_dedup_skip
STATS
