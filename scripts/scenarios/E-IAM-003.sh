#!/usr/bin/env bash
set -euo pipefail
state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"
cat > "$state_dir/e-iam-003.stats" <<'STATS'
idempotent_permission_missing=1
producer_send_failed=1
STATS
