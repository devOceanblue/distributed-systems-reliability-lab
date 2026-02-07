#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  experiments/E-019-mysql-deadlock.md
  scripts/scenarios/E-019.sh
  scripts/assert/E-019.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-019 >/dev/null
"$EXP" assert E-019 >/dev/null
"$EXP" cleanup E-019 >/dev/null

echo "[OK] B-0342 verification passed"
