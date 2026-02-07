#!/usr/bin/env bash
set -euo pipefail

subject="${1:?subject required}"
schema_file="${2:?schema file required}"
state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"

compat_mode="BACKWARD"
if [[ -f "$state_dir/schema.compat" ]]; then
  compat_mode=$(cat "$state_dir/schema.compat")
fi

if [[ "$schema_file" == *"breaking"* && ( "$compat_mode" == "BACKWARD" || "$compat_mode" == "FULL" ) ]]; then
  echo "[FAIL] incompatible schema for $subject under $compat_mode" >&2
  exit 409
fi

dir="$state_dir/schema-registry/$subject"
mkdir -p "$dir"
version=$(( $(find "$dir" -type f | wc -l | tr -d ' ') + 1 ))
cp "$schema_file" "$dir/v${version}.avsc"
echo "[OK] registered $subject version=$version"
