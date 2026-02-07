#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  experiments/E-010-redis-cluster-slots.md
  scripts/scenarios/E-010.sh
  scripts/assert/E-010.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-010 >/dev/null
"$EXP" assert E-010 >/dev/null
"$EXP" cleanup E-010 >/dev/null

echo "[OK] B-0333 verification passed"
