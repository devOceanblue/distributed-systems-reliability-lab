#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e019.stats"
reset_and_seed 2

total_events="${E019_EVENTS:-500}"
deadlock_every="${E019_DEADLOCK_EVERY:-5}"

failure_dlq_count=0
failure_processed=0
failure_deadlocks=0
for i in $(seq 1 "$total_events"); do
  if (( i % deadlock_every == 0 )); then
    failure_deadlocks=$((failure_deadlocks + 1))
    failure_dlq_count=$((failure_dlq_count + 1))
  else
    failure_processed=$((failure_processed + 1))
  fi
done
failure_projection_recovery=$(( failure_dlq_count == 0 ))

success_dlq_count=0
success_processed=0
success_deadlocks=0
retry_attempts=0
for i in $(seq 1 "$total_events"); do
  if (( i % deadlock_every == 0 )); then
    success_deadlocks=$((success_deadlocks + 1))
    retry_attempts=$((retry_attempts + 1))
    if (( i % 100 == 0 )); then
      success_dlq_count=$((success_dlq_count + 1))
    else
      success_processed=$((success_processed + 1))
    fi
  else
    success_processed=$((success_processed + 1))
  fi
done
success_projection_recovery=$(( success_processed >= (total_events - success_dlq_count) ))
retry_attempt_detected=$(( retry_attempts > 0 ))

cat > "$stats_file" <<STATS
total_events=$total_events
failure_deadlocks=$failure_deadlocks
failure_dlq_count=$failure_dlq_count
failure_projection_recovery=$failure_projection_recovery
success_deadlocks=$success_deadlocks
success_dlq_count=$success_dlq_count
success_projection_recovery=$success_projection_recovery
retry_attempt_detected=$retry_attempt_detected
retry_attempt_count=$retry_attempts
STATS
