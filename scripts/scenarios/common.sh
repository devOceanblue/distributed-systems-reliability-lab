#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"
CMD="$ROOT_DIR/services/command-service/bin/command-service.sh"
RELAY="$ROOT_DIR/services/outbox-relay/bin/outbox-relay.sh"
CONSUMER="$ROOT_DIR/services/consumer-service/bin/consumer-service.sh"
QUERY="$ROOT_DIR/services/query-service/bin/query-service.sh"
REPLAY="$ROOT_DIR/services/replay-worker/bin/replay-worker.sh"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"

reset_and_seed() {
  "$SIM" reset
  "$SIM" seed "$1"
}

run_relay_until_idle() {
  local limit="${1:-5000}"
  local i
  for ((i = 0; i < limit; i++)); do
    local pending
    pending=$("$SIM" count outbox_pending)
    if [[ "$pending" == "0" ]]; then
      return 0
    fi
    "$RELAY" >/dev/null
  done
  echo "relay did not drain within limit" >&2
  return 1
}

run_consumer_until_idle() {
  local limit="${1:-5000}"
  local i
  for ((i = 0; i < limit; i++)); do
    local unconsumed
    unconsumed=$("$SIM" count main_unconsumed)
    if [[ "$unconsumed" == "0" ]]; then
      return 0
    fi
    "$CONSUMER" >/dev/null
  done
  echo "consumer did not drain within limit" >&2
  return 1
}
