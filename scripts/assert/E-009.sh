#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="$ROOT_DIR/.lab/state/e009.stats"

[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

[[ "$case_a_min_isr_2_broker_1_down" == "success" ]] || { echo "case A broker1 result mismatch"; exit 1; }
[[ "$case_a_min_isr_2_broker_2_down" == "not_enough_replicas" ]] || { echo "case A broker2 result mismatch"; exit 1; }
[[ "$case_b_min_isr_1_broker_2_down" == "success_with_risk" ]] || { echo "case B broker2 result mismatch"; exit 1; }

echo "[OK] E-009 assertions passed"
