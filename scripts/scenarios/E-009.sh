#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stats_file="$STATE_DIR/e009.stats"
reset_and_seed 1

rf=3

produce_result() {
  local min_isr="$1"
  local brokers_down="$2"
  local acks="$3"
  local isr=$((rf - brokers_down))

  if [[ "$acks" == "all" && "$isr" -lt "$min_isr" ]]; then
    echo "not_enough_replicas"
    return 0
  fi
  echo "success"
}

case_a_broker_1_down_isr=$((rf - 1))
case_a_broker_2_down_isr=$((rf - 2))
case_b_broker_2_down_isr=$((rf - 2))

case_a_min_isr_2_broker_1_down=$(produce_result 2 1 all)
case_a_min_isr_2_broker_2_down=$(produce_result 2 2 all)
case_b_min_isr_1_broker_2_down=$(produce_result 1 2 all)
case_b_min_isr_1_broker_2_down_risk=$(( case_b_broker_2_down_isr == 1 ))

cat > "$stats_file" <<STATS
rf=$rf
case_a_broker_1_down_isr=$case_a_broker_1_down_isr
case_a_broker_2_down_isr=$case_a_broker_2_down_isr
case_b_broker_2_down_isr=$case_b_broker_2_down_isr
case_a_min_isr_2_broker_1_down=$case_a_min_isr_2_broker_1_down
case_a_min_isr_2_broker_2_down=$case_a_min_isr_2_broker_2_down
case_b_min_isr_1_broker_2_down=$case_b_min_isr_1_broker_2_down
case_b_min_isr_1_broker_2_down_risk=$case_b_min_isr_1_broker_2_down_risk
STATS
