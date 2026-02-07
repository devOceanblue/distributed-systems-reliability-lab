#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  docs/SCHEMA_REGISTRY_DECISION.md
  infra/aws/ecs/schema-registry/task-definition.json
  infra/aws/ecs/schema-registry/README.md
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q 'Confluent Schema Registry on ECS/Fargate' "$ROOT_DIR/docs/SCHEMA_REGISTRY_DECISION.md" || { echo "[FAIL] decision text missing"; exit 1; }
grep -q 'Glue' "$ROOT_DIR/docs/SCHEMA_REGISTRY_DECISION.md" || { echo "[FAIL] Glue comparison missing"; exit 1; }
grep -q 'SCHEMA_REGISTRY_KAFKASTORE_SASL_MECHANISM' "$ROOT_DIR/infra/aws/ecs/schema-registry/task-definition.json" || { echo "[FAIL] task definition missing kafka sasl env"; exit 1; }

echo "[OK] B-0356 verification passed"
