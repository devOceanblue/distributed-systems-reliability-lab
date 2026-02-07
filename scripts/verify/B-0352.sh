#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  docker-compose.local.yml
  docker-compose.aws.override.yml
  docs/LOCAL_VS_AWS.md
  services/command-service/src/main/resources/application-aws.yml
  services/outbox-relay/src/main/resources/application-aws.yml
  services/consumer-service/src/main/resources/application-aws.yml
  services/query-service/src/main/resources/application-aws.yml
  services/replay-worker/src/main/resources/application-aws.yml
  Makefile
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q "up-local" "$ROOT_DIR/Makefile" || { echo "[FAIL] make up-local missing"; exit 1; }
grep -q "down-local" "$ROOT_DIR/Makefile" || { echo "[FAIL] make down-local missing"; exit 1; }
grep -q "up-aws" "$ROOT_DIR/Makefile" || { echo "[FAIL] make up-aws missing"; exit 1; }
grep -q "down-aws" "$ROOT_DIR/Makefile" || { echo "[FAIL] make down-aws missing"; exit 1; }

for service in command-service outbox-relay consumer-service replay-worker; do
  grep -q "KAFKA_SASL_MECHANISM" "$ROOT_DIR/services/$service/src/main/resources/application-aws.yml" || {
    echo "[FAIL] aws kafka sasl config missing in $service"
    exit 1
  }
done

echo "[OK] B-0352 verification passed"
