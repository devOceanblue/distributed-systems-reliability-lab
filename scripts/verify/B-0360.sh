#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

required_files=(
  tasks/done/B-0360.md
  frontend/package.json
  frontend/server.mjs
  frontend/index.html
  frontend/styles.css
  frontend/app.mjs
  frontend/core/idempotency.mjs
  frontend/core/api.mjs
  frontend/core/store.mjs
  frontend/tests/idempotency.test.mjs
  frontend/tests/api.test.mjs
  experiments/E-025-frontend-request-id-idempotency.md
  scripts/scenarios/E-025.sh
  scripts/assert/E-025.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$ROOT_DIR/$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

(
  cd "$ROOT_DIR/frontend"
  npm test >/dev/null
)

"$EXP" run E-025 >/dev/null
"$EXP" assert E-025 >/dev/null
"$EXP" cleanup E-025 >/dev/null

echo "[OK] B-0360 verification passed"
