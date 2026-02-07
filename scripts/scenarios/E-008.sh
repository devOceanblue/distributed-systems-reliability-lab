#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e008.stats"

# Failure variant: cache disabled -> every read hits DB.
reset_and_seed 1
env PRODUCE_MODE=direct "$CMD" deposit A-1 e008-1 100 >/dev/null
run_consumer_until_idle
for _ in $(seq 1 100); do
  env TTL_SECONDS=5 CACHE_INVALIDATION_MODE=NONE "$QUERY" A-1 >/dev/null
done
db_read_off=$("$SIM" count db_read)

# Success variant: cache active -> only first read hits DB.
reset_and_seed 1
env PRODUCE_MODE=direct "$CMD" deposit A-1 e008-2 100 >/dev/null
run_consumer_until_idle
for _ in $(seq 1 100); do
  env TTL_SECONDS=60 CACHE_INVALIDATION_MODE=DEL "$QUERY" A-1 >/dev/null
done
db_read_on=$("$SIM" count db_read)

cat > "$stats_file" <<STATS
db_read_off=$db_read_off
db_read_on=$db_read_on
STATS
