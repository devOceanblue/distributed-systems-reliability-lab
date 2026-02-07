#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
state_dir="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
policy="$ROOT_DIR/infra/aws/iam/policies/producer-topic-restricted.json"
target_topic="${E_IAM_002_TARGET_TOPIC:-account.balance.dlq}"
mkdir -p "$state_dir"

if grep -q "$target_topic" "$policy"; then
  write_denied=0
else
  write_denied=1
fi
access_denied_error=$write_denied

cat > "$state_dir/e-iam-002.stats" <<STATS
target_topic=$target_topic
write_denied=$write_denied
access_denied_error=$access_denied_error
STATS
