#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 1
"$CMD" deposit A-1 e003-dup 100 >/dev/null
set +e
env FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true "$RELAY" >/dev/null
set -e
"$RELAY" >/dev/null
env IDEMPOTENCY_MODE=none "$CONSUMER" >/dev/null
env IDEMPOTENCY_MODE=none "$CONSUMER" >/dev/null
