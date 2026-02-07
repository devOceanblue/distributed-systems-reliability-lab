#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

"$ROOT_DIR/scripts/verify/B-0357.sh" >/dev/null

"$EXP" run E-024 >/dev/null
"$EXP" assert E-024 >/dev/null
"$EXP" cleanup E-024 >/dev/null

echo "[OK] phase6 coupon concurrency checks passed"
