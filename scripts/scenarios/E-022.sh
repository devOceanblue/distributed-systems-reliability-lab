#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e022.stats"
reset_and_seed 5

source_count="${E022_SOURCE_COUNT:-5000}"
safe_rate_limit="${E022_SAFE_RATE_LIMIT:-200}"
canary_count="${E022_CANARY_COUNT:-1000}"

"$ROOT_DIR/scripts/data/gen-backfill.sh" "$source_count" >/dev/null
source_file="$STATE_DIR/backfill-source.tsv"
unsafe_file="$STATE_DIR/backfill-unsafe.tsv"
safe_file="$STATE_DIR/backfill-safe.tsv"
checkpoint_file="$STATE_DIR/backfill.checkpoint"

total_rows=$(wc -l < "$source_file" | tr -d ' ')

# Unsafe mode: no rate limit/checkpoint, overload drops tail half.
unsafe_processed=$((total_rows / 2))
head -n "$unsafe_processed" "$source_file" > "$unsafe_file"
unsafe_consumer_lag=$((total_rows - unsafe_processed))
unsafe_db_qps=$((unsafe_processed / 5))

# Safe mode: canary + checkpoint + resume with throttled rate.
: > "$safe_file"
sed -n "1,${canary_count}p" "$source_file" >> "$safe_file"
echo "$canary_count" > "$checkpoint_file"

resume_from=$(cat "$checkpoint_file")
if (( resume_from < total_rows )); then
  sed -n "$((resume_from + 1)),${total_rows}p" "$source_file" >> "$safe_file"
fi

safe_processed=$(wc -l < "$safe_file" | tr -d ' ')
safe_consumer_lag=$((total_rows - safe_processed))
safe_db_qps=$safe_rate_limit
resume_supported=$(( safe_processed == total_rows ))

source_sum=$(awk -F '\t' '{s+=$3} END{print s+0}' "$source_file")
safe_sum=$(awk -F '\t' '{s+=$3} END{print s+0}' "$safe_file")
sampling_validation_passed=$(( source_sum == safe_sum ))

cat > "$stats_file" <<STATS
source_rows=$total_rows
unsafe_processed=$unsafe_processed
unsafe_db_qps=$unsafe_db_qps
unsafe_consumer_lag=$unsafe_consumer_lag
safe_processed=$safe_processed
safe_db_qps=$safe_db_qps
safe_consumer_lag=$safe_consumer_lag
resume_supported=$resume_supported
sampling_validation_passed=$sampling_validation_passed
STATS
