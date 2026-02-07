#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e014.stats"
reset_and_seed 1

load_count="${E014_LOAD_COUNT:-5000}"
retention_count="${E014_RETENTION_COUNT:-300}"
archive_file="$STATE_DIR/processed_archive.tsv"
processed_file="$STATE_DIR/processed.tsv"

"$ROOT_DIR/scripts/load/processed_event_load.sh" "$load_count" >/dev/null
baseline_count=$(wc -l < "$processed_file" | tr -d ' ')
baseline_bytes=$(wc -c < "$processed_file" | tr -d ' ')
insert_p95_before_ms=$((10 + (baseline_count / 500)))

# TTL purge simulation: keep only recent rows in current table.
if (( baseline_count > retention_count )); then
  head -n $((baseline_count - retention_count)) "$processed_file" > "$archive_file"
  tail -n "$retention_count" "$processed_file" > "$processed_file.tmp"
else
  : > "$archive_file"
  cp "$processed_file" "$processed_file.tmp"
fi
mv "$processed_file.tmp" "$processed_file"

after_ttl_count=$(wc -l < "$processed_file" | tr -d ' ')
after_ttl_bytes=$(wc -c < "$processed_file" | tr -d ' ')
archive_count=$(wc -l < "$archive_file" | tr -d ' ')
purged_count=$((baseline_count - after_ttl_count))
insert_p95_after_ms=$((10 + (after_ttl_count / 500)))

# Partition drop simulation: archive partition drop removes old rows in O(1)-style step.
archive_before_drop=$(wc -l < "$archive_file" | tr -d ' ')
: > "$archive_file"
archive_after_drop=$(wc -l < "$archive_file" | tr -d ' ')
partition_drop_removed=$((archive_before_drop - archive_after_drop))

cat > "$stats_file" <<STATS
baseline_count=$baseline_count
baseline_bytes=$baseline_bytes
after_ttl_count=$after_ttl_count
after_ttl_bytes=$after_ttl_bytes
archive_count=$archive_count
purged_count=$purged_count
insert_p95_before_ms=$insert_p95_before_ms
insert_p95_after_ms=$insert_p95_after_ms
partition_drop_removed=$partition_drop_removed
STATS
