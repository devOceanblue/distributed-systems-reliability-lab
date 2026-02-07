#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  scripts/load/processed_event_load.sh
  experiments/E-014-processed-event-retention.md
  scripts/scenarios/E-014.sh
  scripts/assert/E-014.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

E014_LOAD_COUNT=5000 E014_RETENTION_COUNT=300 "$EXP" run E-014 >/dev/null
"$EXP" assert E-014 >/dev/null
"$EXP" cleanup E-014 >/dev/null

echo "[OK] B-0337 verification passed"
