#!/usr/bin/env bash
set -euo pipefail

count="${1:-1000000}"
state_dir="${LAB_STATE_DIR:-.lab/state}"
file="$state_dir/processed.tsv"
mkdir -p "$state_dir"

: > "$file"
for i in $(seq 1 "$count"); do
  printf 'consumer-service\tdedup-%s\n' "$i" >> "$file"
done

echo "[OK] loaded processed_event rows=$count"
