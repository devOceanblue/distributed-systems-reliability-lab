#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  experiments/E-018-rebalance-storm.md
  scripts/scenarios/E-018.sh
  scripts/assert/E-018.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-018 >/dev/null
"$EXP" assert E-018 >/dev/null
"$EXP" cleanup E-018 >/dev/null

echo "[OK] B-0341 verification passed"
