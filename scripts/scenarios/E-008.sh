#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e008.stats"
tmp_dir="$STATE_DIR/e008.latency"
mkdir -p "$tmp_dir"
off_latency_file="$tmp_dir/off.ms"
on_latency_file="$tmp_dir/on.ms"
: > "$off_latency_file"
: > "$on_latency_file"

requests="${E008_REQUESTS:-100}"

percentile() {
  local file="$1"
  local p="$2"
  local n rank
  n=$(wc -l < "$file" | tr -d ' ')
  if [[ "$n" == "0" ]]; then
    echo "0"
    return 0
  fi

  rank=$(( (p * n + 99) / 100 ))
  (( rank < 1 )) && rank=1
  sort -n "$file" | sed -n "${rank}p"
}

run_variant() {
  local ttl="$1"
  local cache_mode="$2"
  local latency_file="$3"
  local i before_db after_db synthetic_latency
  for i in $(seq 1 "$requests"); do
    before_db=$("$SIM" count db_read)
    env TTL_SECONDS="$ttl" CACHE_INVALIDATION_MODE="$cache_mode" "$QUERY" A-1 >/dev/null
    after_db=$("$SIM" count db_read)
    if (( after_db > before_db )); then
      synthetic_latency=15
    else
      synthetic_latency=3
    fi
    printf '%s\n' "$synthetic_latency" >> "$latency_file"
  done
}

# Failure variant: cache disabled -> every read hits DB.
reset_and_seed 1
env PRODUCE_MODE=direct "$CMD" deposit A-1 e008-1 100 >/dev/null
run_consumer_until_idle
run_variant 5 NONE "$off_latency_file"
db_read_off=$("$SIM" count db_read)
db_qps_off=$((db_read_off / 5))
p95_off=$(percentile "$off_latency_file" 95)
p99_off=$(percentile "$off_latency_file" 99)

# Success variant: cache active -> only first read hits DB.
reset_and_seed 1
env PRODUCE_MODE=direct "$CMD" deposit A-1 e008-2 100 >/dev/null
run_consumer_until_idle
run_variant 60 DEL "$on_latency_file"
db_read_on=$("$SIM" count db_read)
db_qps_on=$((db_read_on / 5))
p95_on=$(percentile "$on_latency_file" 95)
p99_on=$(percentile "$on_latency_file" 99)

cat > "$stats_file" <<STATS
db_read_off=$db_read_off
db_read_on=$db_read_on
db_qps_off=$db_qps_off
db_qps_on=$db_qps_on
p95_off_ms=$p95_off
p95_on_ms=$p95_on
p99_off_ms=$p99_off
p99_on_ms=$p99_on
STATS
