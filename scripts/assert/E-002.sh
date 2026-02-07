#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

[[ "$("$SIM" inspect domain_balance A-1)" == "100" ]] || { echo "domain balance should be committed"; exit 1; }
[[ "$("$SIM" inspect projection_balance A-1)" == "0" ]] || { echo "projection should remain stale"; exit 1; }
[[ "$("$SIM" count main_topic)" == "0" ]] || { echo "kafka topic should be empty"; exit 1; }

echo "[OK] E-002 assertions passed"
