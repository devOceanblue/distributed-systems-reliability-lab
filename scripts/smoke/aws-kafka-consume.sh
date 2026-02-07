#!/usr/bin/env bash
set -euo pipefail

state_dir="${LAB_STATE_DIR:-.lab/state}"
log_file="$state_dir/aws-kafka-smoke.log"

[[ -f "$log_file" ]] || { echo "missing smoke log: $log_file" >&2; exit 1; }
tail -n 1 "$log_file"
echo "[OK] aws kafka consume smoke marker read"
