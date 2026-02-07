#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e014.stats"
reset_and_seed 1

"$ROOT_DIR/scripts/load/processed_event_load.sh" 1000 >/dev/null
baseline_count=$(wc -l < "$STATE_DIR/processed.tsv" | tr -d ' ')

# TTL purge simulation: keep only last 300 rows.
tail -n 300 "$STATE_DIR/processed.tsv" > "$STATE_DIR/processed.tsv.tmp"
mv "$STATE_DIR/processed.tsv.tmp" "$STATE_DIR/processed.tsv"
after_ttl_count=$(wc -l < "$STATE_DIR/processed.tsv" | tr -d ' ')

cat > "$stats_file" <<STATS
baseline_count=$baseline_count
after_ttl_count=$after_ttl_count
partition_drop_simulated=1
STATS
