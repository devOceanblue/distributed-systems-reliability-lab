#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e006.stats"

# Failure variant: producer-first breaking change simulated as permanent parse error.
reset_and_seed 1
for idx in $(seq 1 3); do
  env PRODUCE_MODE=direct "$CMD" deposit A-1 "e006-fail-${idx}" 100 >/dev/null
done
for _ in $(seq 1 3); do
  env FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-1 "$CONSUMER" >/dev/null
done
failure_dlq=$("$SIM" count dlq)

# Success variant: consumer-first dual-read simulation.
reset_and_seed 1
for idx in $(seq 1 3); do
  env PRODUCE_MODE=direct "$CMD" deposit A-1 "e006-success-${idx}" 100 >/dev/null
done
run_consumer_until_idle
success_dlq=$("$SIM" count dlq)
success_projection=$("$SIM" inspect projection_balance A-1)

cat > "$stats_file" <<STATS
failure_dlq=$failure_dlq
success_dlq=$success_dlq
success_projection=$success_projection
STATS
