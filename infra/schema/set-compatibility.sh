#!/usr/bin/env bash
set -euo pipefail

mode="${1:-BACKWARD}"
state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"

echo "$mode" > "$state_dir/schema.compat"
echo "[OK] compatibility set to $mode"
