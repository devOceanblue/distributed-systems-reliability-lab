#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  experiments/E-012-tx-abort-skiplike.md
  scripts/scenarios/E-012.sh
  scripts/assert/E-012.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

LAB_PROFILE=local "$EXP" run E-012 >/dev/null
"$EXP" assert E-012 >/dev/null
"$EXP" cleanup E-012 >/dev/null

echo "[OK] B-0335 verification passed"
