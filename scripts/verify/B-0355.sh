#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  infra/aws/observability/main.tf
  infra/aws/observability/variables.tf
  dashboards/aws-reliability-overview.json
  docs/OBSERVABILITY.md
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q 'aws_prometheus_workspace' "$ROOT_DIR/infra/aws/observability/main.tf" || { echo "[FAIL] AMP workspace resource missing"; exit 1; }
grep -q 'aws_grafana_workspace' "$ROOT_DIR/infra/aws/observability/main.tf" || { echo "[FAIL] Grafana workspace resource missing"; exit 1; }
grep -q 'outbox_oldest_age_seconds' "$ROOT_DIR/infra/aws/observability/main.tf" || { echo "[FAIL] outbox alarm missing"; exit 1; }
grep -q 'consumer_lag_records' "$ROOT_DIR/dashboards/aws-reliability-overview.json" || { echo "[FAIL] consumer lag panel missing"; exit 1; }
grep -q 'dlq_publish_total' "$ROOT_DIR/dashboards/aws-reliability-overview.json" || { echo "[FAIL] dlq panel missing"; exit 1; }

echo "[OK] B-0355 verification passed"
