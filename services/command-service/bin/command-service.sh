#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

mode="${PRODUCE_MODE:-outbox}"
fail_after_commit="${FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND:-false}"

command="${1:-}"
case "$command" in
  deposit)
    "$SIM" deposit "$2" "$3" "$4" "$mode" "$fail_after_commit"
    ;;
  withdraw)
    "$SIM" withdraw "$2" "$3" "$4" "$mode" "$fail_after_commit"
    ;;
  *)
    echo "usage: command-service.sh <deposit|withdraw> <account_id> <tx_id> <amount>" >&2
    exit 2
    ;;
esac
