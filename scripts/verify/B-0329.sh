#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  experiments/E-009-isr-minisr-acks.md
  scripts/scenarios/E-009.sh
  scripts/assert/E-009.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

grep -q 'broker <stop|start>' "$ROOT_DIR/scripts/exp" || { echo "[FAIL] scripts/exp broker utility missing"; exit 1; }

"$EXP" run E-009 >/dev/null
"$EXP" assert E-009 >/dev/null
"$EXP" cleanup E-009 >/dev/null

echo "[OK] B-0329 verification passed"
