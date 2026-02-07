#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
alerts_file="$ROOT_DIR/infra/prometheus/alerts.yml"
dashboard_file="$ROOT_DIR/infra/grafana/dashboards/reliability-lab-overview.json"

[[ -f "$alerts_file" ]] || { echo "[FAIL] missing: infra/prometheus/alerts.yml"; exit 1; }
[[ -f "$dashboard_file" ]] || { echo "[FAIL] missing: infra/grafana/dashboards/reliability-lab-overview.json"; exit 1; }

required_alert_exprs=(
  "outbox_oldest_age_seconds > 300"
  "rate(dlq_publish_total\\[1m\\]) > 1"
  "consumer_lag_records > 1000"
  "redis_hit_ratio < 0.7"
  "mysql_global_status_threads_connected > 80"
  "kafka_server_replicamanager_underreplicatedpartitions > 0"
)

for expr in "${required_alert_exprs[@]}"; do
  grep -q "$expr" "$alerts_file" || { echo "[FAIL] alert expr missing: $expr"; exit 1; }
done

required_dashboard_panels=(
  "\"title\": \"Consumer Lag\""
  "\"title\": \"Outbox Oldest Age\""
  "\"title\": \"DLQ Publish Rate\""
  "\"title\": \"Cache Hit Ratio\""
)

for panel in "${required_dashboard_panels[@]}"; do
  grep -q "$panel" "$dashboard_file" || { echo "[FAIL] dashboard panel missing: $panel"; exit 1; }
done

echo "[OK] B-0331 verification passed"
