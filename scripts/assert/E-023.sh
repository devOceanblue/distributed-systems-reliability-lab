#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e023.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( requests > 0 )) || { echo "request count should be positive"; exit 1; }
awk "BEGIN {exit !($redis_unsafe_error_rate > $redis_safe_error_rate)}" || { echo "redis safe mode should reduce error rate"; exit 1; }
awk "BEGIN {exit !($kafka_unsafe_error_rate > $kafka_safe_error_rate)}" || { echo "kafka safe mode should reduce error rate"; exit 1; }
awk "BEGIN {exit !($mysql_unsafe_error_rate > $mysql_safe_error_rate)}" || { echo "mysql safe mode should reduce error rate"; exit 1; }
[[ "$outbox_backlog_recovered" == "1" ]] || { echo "outbox recovery marker missing"; exit 1; }
(( outbox_backlog_before_recovery > outbox_backlog_after_recovery )) || { echo "outbox backlog should drain after recovery"; exit 1; }
[[ "$stale_serve_kept_reads" == "1" ]] || { echo "stale serve should keep read availability"; exit 1; }

echo "[OK] E-023 assertions passed"
