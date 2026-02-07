#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
state_dir="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
policy="$ROOT_DIR/infra/aws/iam/policies/producer-missing-idempotent.json"
mkdir -p "$state_dir"

if grep -q 'kafka-cluster:WriteDataIdempotently' "$policy"; then
  idempotent_permission_missing=0
else
  idempotent_permission_missing=1
fi
producer_send_failed=$idempotent_permission_missing

cat > "$state_dir/e-iam-003.stats" <<STATS
idempotent_permission_missing=$idempotent_permission_missing
producer_send_failed=$producer_send_failed
STATS
