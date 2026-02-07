#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  infra/redis/lua/incr_balance.lua
  experiments/E-013-redis-lua-consistency.md
  scripts/scenarios/E-013.sh
  scripts/assert/E-013.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-013 >/dev/null
"$EXP" assert E-013 >/dev/null
"$EXP" cleanup E-013 >/dev/null

echo "[OK] B-0336 verification passed"
