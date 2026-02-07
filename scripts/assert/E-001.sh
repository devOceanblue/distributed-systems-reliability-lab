#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"
events_per_account="${E001_EVENTS_PER_ACCOUNT:-100}"
expected_total=$((10 * events_per_account))
expected_balance=$((events_per_account * 100))

[[ "$("$SIM" count ledger)" == "$expected_total" ]] || { echo "ledger count mismatch"; exit 1; }
[[ "$("$SIM" count processed)" == "$expected_total" ]] || { echo "processed count mismatch"; exit 1; }
[[ "$("$SIM" count main_unconsumed)" == "0" ]] || { echo "main topic should be fully consumed"; exit 1; }

for account in $(seq 1 10); do
  balance=$("$SIM" inspect projection_balance "A-${account}")
  [[ "$balance" == "$expected_balance" ]] || { echo "projection mismatch for A-${account}: $balance"; exit 1; }
done

echo "[OK] E-001 assertions passed"
