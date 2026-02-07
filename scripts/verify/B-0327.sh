#!/usr/bin/env bash
set -euo pipefail

required_files=(
  experiments/E-007-lso-visibility.md
  scripts/scenarios/E-007.sh
  scripts/assert/E-007.sh
  scripts/sim/lab_sim.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "[FAIL] missing: $file"; exit 1; }
done

rg -q "E-007 is local-only" scripts/scenarios/E-007.sh || {
  echo "[FAIL] E-007 must enforce LAB_PROFILE=local"
  exit 1
}

rg -q "tx-read-uncommitted|tx-read-committed|tx-lso|tx-leo" scripts/sim/lab_sim.sh || {
  echo "[FAIL] transactional visibility simulation commands missing in lab_sim"
  exit 1
}

echo "[OK] B-0327 transactional LEO/HW/LSO visibility assets are present"
echo "[INFO] run 'LAB_PROFILE=local ./scripts/exp run E-007 && ./scripts/exp assert E-007'"
