#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT_DIR/scripts/exp"

run_and_assert() {
  local exp_id="$1"
  shift
  echo "[INFO] run $exp_id"
  "$@" "$EXP" run "$exp_id"
  "$@" "$EXP" assert "$exp_id"
  "$EXP" cleanup "$exp_id" >/dev/null
}

run_and_assert E-001 env E001_EVENTS_PER_ACCOUNT=10
run_and_assert E-002 env
run_and_assert E-003 env
run_and_assert E-004 env
run_and_assert E-005 env

echo "[OK] phase2 harness checks passed (E-001..E-005)"
