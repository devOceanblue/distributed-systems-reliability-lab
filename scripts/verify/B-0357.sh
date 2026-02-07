#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  tasks/done/B-0357.md
  experiments/E-024-coupon-concurrency-redis-vs-mysql.md
  infra/k6/coupon-issue.js
  scripts/scenarios/E-024.sh
  scripts/assert/E-024.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-024 >/dev/null
"$EXP" assert E-024 >/dev/null
"$EXP" cleanup E-024 >/dev/null

echo "[OK] B-0357 verification passed"
