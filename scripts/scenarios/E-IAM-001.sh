#!/usr/bin/env bash
set -euo pipefail
state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"
cat > "$state_dir/e-iam-001.stats" <<'STATS'
consumer_group_permission_missing=1
join_failed=1
STATS
