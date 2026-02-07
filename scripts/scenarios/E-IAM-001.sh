#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
state_dir="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
policy="$ROOT_DIR/infra/aws/iam/policies/consumer-missing-group.json"
mkdir -p "$state_dir"

missing=0
grep -q 'kafka-cluster:AlterGroup' "$policy" || missing=$((missing + 1))
grep -q 'kafka-cluster:DescribeGroup' "$policy" || missing=$((missing + 1))

consumer_group_permission_missing=$(( missing > 0 ))
join_failed=$consumer_group_permission_missing

cat > "$state_dir/e-iam-001.stats" <<STATS
consumer_group_permission_missing=$consumer_group_permission_missing
missing_group_action_count=$missing
join_failed=$join_failed
STATS
