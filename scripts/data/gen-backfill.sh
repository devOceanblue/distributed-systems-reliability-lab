#!/usr/bin/env bash
set -euo pipefail

count="${1:-10000}"
state_dir="${LAB_STATE_DIR:-.lab/state}"
out="$state_dir/backfill-source.tsv"
mkdir -p "$state_dir"

: > "$out"
for i in $(seq 1 "$count"); do
  account=$(( (i % 100) + 1 ))
  printf 'backfill-%s\tA-%s\t100\n' "$i" "$account" >> "$out"
done

echo "[OK] generated backfill source rows=$count"
