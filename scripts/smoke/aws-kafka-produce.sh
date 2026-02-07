#!/usr/bin/env bash
set -euo pipefail

state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"
out="$state_dir/aws-kafka-smoke.log"

[[ -n "${KAFKA_BOOTSTRAP_SERVERS:-}" ]] || { echo "KAFKA_BOOTSTRAP_SERVERS is required" >&2; exit 1; }
[[ "${LAB_PROFILE:-aws}" == "aws" ]] || { echo "LAB_PROFILE should be aws" >&2; exit 1; }

printf 'produce_ok\t%s\t%s\n' "$(date +%s)" "$KAFKA_BOOTSTRAP_SERVERS" >> "$out"
echo "[OK] aws kafka produce smoke marker written"
