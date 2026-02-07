#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  docker-compose.local.yml
  infra/prometheus/prometheus.yml
  infra/grafana/provisioning/datasources/datasource.yml
  infra/grafana/provisioning/dashboards/dashboards.yml
  infra/grafana/dashboards/reliability-lab-overview.json
  services/command-service/build.gradle
  services/outbox-relay/build.gradle
  services/consumer-service/build.gradle
  services/query-service/build.gradle
  services/replay-worker/build.gradle
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

for service in prometheus grafana mysqld-exporter redis-exporter kafka-exporter; do
  grep -q "^  ${service}:" "$ROOT_DIR/docker-compose.local.yml" || { echo "[FAIL] compose service missing: $service"; exit 1; }
done
grep -q 'profiles: \["obs"\]' "$ROOT_DIR/docker-compose.local.yml" || { echo "[FAIL] obs profile missing"; exit 1; }

for module in command-service outbox-relay consumer-service query-service replay-worker; do
  build_file="$ROOT_DIR/services/$module/build.gradle"
  grep -q "spring-boot-starter-actuator" "$build_file" || { echo "[FAIL] actuator dependency missing in $build_file"; exit 1; }
  grep -q "micrometer-registry-prometheus" "$build_file" || { echo "[FAIL] prometheus registry dependency missing in $build_file"; exit 1; }
  grep -q "prometheus" "$ROOT_DIR/services/$module/src/main/resources/application.yml" || { echo "[FAIL] actuator prometheus exposure missing in $module"; exit 1; }
done

echo "[OK] B-0330 verification passed"
