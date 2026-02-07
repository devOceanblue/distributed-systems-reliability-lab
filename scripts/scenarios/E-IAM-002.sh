#!/usr/bin/env bash
set -euo pipefail
state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"
cat > "$state_dir/e-iam-002.stats" <<'STATS'
write_denied=1
access_denied_error=1
STATS
