#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 1
for idx in $(seq 1 10); do
  env PRODUCE_MODE=direct "$CMD" deposit A-1 "e004-${idx}" 100 >/dev/null
done

set +e
env OFFSET_COMMIT_MODE=before_db FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT=true "$CONSUMER" >/dev/null
set -e

run_consumer_until_idle
