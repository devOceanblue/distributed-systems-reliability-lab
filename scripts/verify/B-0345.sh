#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  scripts/data/gen-backfill.sh
  experiments/E-022-backfill-controlled.md
  scripts/scenarios/E-022.sh
  scripts/assert/E-022.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

E022_SOURCE_COUNT=5000 "$EXP" run E-022 >/dev/null
"$EXP" assert E-022 >/dev/null
"$EXP" cleanup E-022 >/dev/null

echo "[OK] B-0345 verification passed"
