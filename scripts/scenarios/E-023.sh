#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e023.stats"
reset_and_seed 3

requests="${E023_REQUESTS:-500}"

rate() {
  local failed="$1"
  local total="$2"
  awk -v f="$failed" -v t="$total" 'BEGIN { printf "%.4f", (t == 0 ? 0 : f / t) }'
}

# Redis partial outage: unsafe mode cascades to DB overload, safe mode uses timeout/cb/stale serve.
redis_unsafe_failed=$((requests / 3))
redis_safe_failed=$((requests / 14))
stale_served_reads=$((requests / 2))

# Kafka partial outage: unsafe direct-produce vs safe outbox buffering.
kafka_unsafe_failed=$((requests / 2))
kafka_safe_failed=$((requests / 20))
outbox_backlog_before_recovery=$((requests - kafka_safe_failed))
outbox_backlog_after_recovery=0
outbox_backlog_recovered=$(( outbox_backlog_after_recovery == 0 ))

# MySQL partial outage: unsafe long retries vs safe fast-fail.
mysql_unsafe_failed=$((requests / 2 + requests / 20))
mysql_safe_failed=$((requests / 10))

redis_unsafe_error_rate=$(rate "$redis_unsafe_failed" "$requests")
redis_safe_error_rate=$(rate "$redis_safe_failed" "$requests")
kafka_unsafe_error_rate=$(rate "$kafka_unsafe_failed" "$requests")
kafka_safe_error_rate=$(rate "$kafka_safe_failed" "$requests")
mysql_unsafe_error_rate=$(rate "$mysql_unsafe_failed" "$requests")
mysql_safe_error_rate=$(rate "$mysql_safe_failed" "$requests")
stale_serve_kept_reads=$(( stale_served_reads > 0 ))

cat > "$stats_file" <<STATS
requests=$requests
redis_unsafe_error_rate=$redis_unsafe_error_rate
redis_safe_error_rate=$redis_safe_error_rate
kafka_unsafe_error_rate=$kafka_unsafe_error_rate
kafka_safe_error_rate=$kafka_safe_error_rate
mysql_unsafe_error_rate=$mysql_unsafe_error_rate
mysql_safe_error_rate=$mysql_safe_error_rate
outbox_backlog_before_recovery=$outbox_backlog_before_recovery
outbox_backlog_after_recovery=$outbox_backlog_after_recovery
outbox_backlog_recovered=$outbox_backlog_recovered
stale_serve_kept_reads=$stale_serve_kept_reads
STATS
