#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

[[ "$("$SIM" count replay_audit)" == "5" ]] || { echo "replay audit count mismatch"; exit 1; }
[[ "$("$SIM" inspect projection_balance A-3)" == "500" ]] || { echo "projection should recover after replay"; exit 1; }
[[ "$("$SIM" count processed)" == "5" ]] || { echo "processed rows mismatch"; exit 1; }

echo "[OK] E-005 assertions passed"
