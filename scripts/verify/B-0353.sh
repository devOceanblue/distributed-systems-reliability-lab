#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_files=(
  infra/aws/iam/policies/producer-minimal.json
  infra/aws/iam/policies/consumer-minimal.json
  infra/aws/iam/policies/admin-minimal.json
  infra/aws/iam/policies/consumer-missing-group.json
  infra/aws/iam/policies/producer-missing-idempotent.json
  infra/aws/iam/policies/producer-topic-restricted.json
  docs/MSK_IAM_POLICIES.md
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q 'kafka-cluster:WriteDataIdempotently' "$ROOT_DIR/infra/aws/iam/policies/producer-minimal.json" || {
  echo "[FAIL] producer minimal should include WriteDataIdempotently"
  exit 1
}
grep -q 'kafka-cluster:AlterGroup' "$ROOT_DIR/infra/aws/iam/policies/consumer-minimal.json" || {
  echo "[FAIL] consumer minimal should include AlterGroup"
  exit 1
}
grep -q 'kafka-cluster:DescribeGroup' "$ROOT_DIR/infra/aws/iam/policies/consumer-minimal.json" || {
  echo "[FAIL] consumer minimal should include DescribeGroup"
  exit 1
}

echo "[OK] B-0353 verification passed"
