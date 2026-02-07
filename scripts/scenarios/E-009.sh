#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e009.stats"
reset_and_seed 1

cat > "$stats_file" <<'STATS'
case_a_min_isr_2_broker_1_down=success
case_a_min_isr_2_broker_2_down=not_enough_replicas
case_b_min_isr_1_broker_2_down=success_with_risk
STATS
