#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  infra/k6/stampede.js
  experiments/E-008-cache-stampede.md
  scripts/scenarios/E-008.sh
  scripts/assert/E-008.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-008 >/dev/null
"$EXP" assert E-008 >/dev/null
"$EXP" cleanup E-008 >/dev/null

echo "[OK] B-0328 verification passed"
