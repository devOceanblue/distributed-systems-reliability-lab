#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 1
set +e
env PRODUCE_MODE=direct FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND=true "$CMD" deposit A-1 e002-loss 100 >/dev/null
set -e
