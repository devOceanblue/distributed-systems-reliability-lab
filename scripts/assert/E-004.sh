#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

[[ "$("$SIM" count main_topic)" == "10" ]] || { echo "main topic should contain 10 events"; exit 1; }
[[ "$("$SIM" count processed)" == "9" ]] || { echo "one event should be lost after offset-first crash"; exit 1; }
[[ "$("$SIM" inspect projection_balance A-1)" == "900" ]] || { echo "projection should reflect 9 events"; exit 1; }

echo "[OK] E-004 assertions passed"
