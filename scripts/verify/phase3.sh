#!/usr/bin/env bash
set -euo pipefail

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/B-0330.sh" >/dev/null
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/B-0331.sh" >/dev/null

required_files=(
  infra/prometheus/prometheus.yml
  infra/prometheus/alerts.yml
  infra/grafana/provisioning/datasources/datasource.yml
  infra/grafana/provisioning/dashboards/dashboards.yml
  infra/grafana/dashboards/reliability-lab-overview.json
  scripts/chaos/broker-stop.sh
  scripts/chaos/broker-start.sh
  scripts/chaos/netem-delay.sh
  scripts/chaos/netem-clear.sh
  scripts/chaos/kill-service.sh
  scripts/chaos/restart-service.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

for script in scripts/chaos/*.sh; do
  [[ -x "$script" ]] || { echo "[FAIL] script not executable: $script"; exit 1; }
done

rg -q 'oldest_outbox_age_seconds|outbox_oldest_age_seconds' infra/prometheus/alerts.yml || { echo "[FAIL] outbox alert missing"; exit 1; }
rg -q 'consumer_lag' infra/prometheus/alerts.yml || { echo "[FAIL] consumer lag alert missing"; exit 1; }
rg -q 'dlq' infra/prometheus/alerts.yml || { echo "[FAIL] dlq alert missing"; exit 1; }

echo "[OK] phase3 observability/chaos assets are present"
