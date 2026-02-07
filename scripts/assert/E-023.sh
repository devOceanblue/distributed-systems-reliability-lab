#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e023.stats"

awk "BEGIN {exit !($redis_unsafe_error_rate > $redis_safe_error_rate)}" || { echo "redis safe mode should reduce error rate"; exit 1; }
awk "BEGIN {exit !($kafka_unsafe_error_rate > $kafka_safe_error_rate)}" || { echo "kafka safe mode should reduce error rate"; exit 1; }
awk "BEGIN {exit !($mysql_unsafe_error_rate > $mysql_safe_error_rate)}" || { echo "mysql safe mode should reduce error rate"; exit 1; }
[[ "$outbox_backlog_recovered" == "1" ]] || { echo "outbox recovery marker missing"; exit 1; }

echo "[OK] E-023 assertions passed"
