#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  infra/k6/hotkey.js
  infra/k6/distributed.js
  experiments/E-011-hotkey-hotshard.md
  scripts/scenarios/E-011.sh
  scripts/assert/E-011.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

"$EXP" run E-011 >/dev/null
"$EXP" assert E-011 >/dev/null
"$EXP" cleanup E-011 >/dev/null

echo "[OK] B-0334 verification passed"
