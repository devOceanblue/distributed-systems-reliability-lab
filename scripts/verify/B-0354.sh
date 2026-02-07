#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  scripts/scenarios/E-IAM-001.sh
  scripts/scenarios/E-IAM-002.sh
  scripts/scenarios/E-IAM-003.sh
  scripts/assert/E-IAM-001.sh
  scripts/assert/E-IAM-002.sh
  scripts/assert/E-IAM-003.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-IAM-001 >/dev/null
"$EXP" assert E-IAM-001 >/dev/null
"$EXP" run E-IAM-002 >/dev/null
"$EXP" assert E-IAM-002 >/dev/null
"$EXP" run E-IAM-003 >/dev/null
"$EXP" assert E-IAM-003 >/dev/null

echo "[OK] B-0354 verification passed"
