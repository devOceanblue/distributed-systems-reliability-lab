#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

[[ "$("$SIM" count ledger)" == "1" ]] || { echo "ledger should contain single tx"; exit 1; }
[[ "$("$SIM" inspect projection_balance A-1)" == "200" ]] || { echo "projection should show duplicate side-effect"; exit 1; }
[[ "$("$SIM" count processed)" == "0" ]] || { echo "processed table should be unused in none mode"; exit 1; }

echo "[OK] E-003 assertions passed"
