#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"

expected_amount="${E025_AMOUNT:-100}"

[[ -f "$STATE_DIR/e025_duplicate_exit_code" ]] || { echo "missing e025 duplicate marker"; exit 1; }
[[ "$(cat "$STATE_DIR/e025_duplicate_exit_code")" == "2" ]] || { echo "duplicate request should exit with code 2"; exit 1; }

[[ "$($SIM count ledger)" == "1" ]] || { echo "ledger count mismatch"; exit 1; }
[[ "$($SIM count outbox)" == "1" ]] || { echo "outbox count mismatch"; exit 1; }
[[ "$($SIM count processed)" == "1" ]] || { echo "processed count mismatch"; exit 1; }
[[ "$($SIM count main_unconsumed)" == "0" ]] || { echo "main topic should be fully consumed"; exit 1; }

balance="$($SIM inspect domain_balance A-1)"
projection="$($SIM inspect projection_balance A-1)"
[[ "$balance" == "$expected_amount" ]] || { echo "domain balance mismatch: $balance"; exit 1; }
[[ "$projection" == "$expected_amount" ]] || { echo "projection balance mismatch: $projection"; exit 1; }

echo "[OK] E-025 assertions passed"
