#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 3
for idx in $(seq 1 5); do
  env PRODUCE_MODE=direct "$CMD" deposit A-3 "e005-${idx}" 100 >/dev/null
done

for _ in $(seq 1 5); do
  env FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3 "$CONSUMER" >/dev/null
done

env REPLAY_ACCOUNT_ID=A-3 "$REPLAY" >/dev/null
run_consumer_until_idle
