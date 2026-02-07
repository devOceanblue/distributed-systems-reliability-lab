#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 10
events_per_account="${E001_EVENTS_PER_ACCOUNT:-100}"

for account in $(seq 1 10); do
  for idx in $(seq 1 "$events_per_account"); do
    "$CMD" deposit "A-${account}" "e001-${account}-${idx}" 100 >/dev/null
  done
done

run_relay_until_idle
run_consumer_until_idle
