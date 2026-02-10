#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

reset_and_seed 1

request_id="${E025_REQUEST_ID:-req-e025-a1-001}"
amount="${E025_AMOUNT:-100}"

"$CMD" deposit "A-1" "$request_id" "$amount" >/dev/null

set +e
"$CMD" deposit "A-1" "$request_id" "$amount" >/dev/null 2>&1
duplicate_exit_code=$?
set -e

[[ "$duplicate_exit_code" == "2" ]] || {
  echo "expected duplicate exit code 2, got $duplicate_exit_code" >&2
  exit 1
}

run_relay_until_idle
run_consumer_until_idle

echo "$duplicate_exit_code" > "$STATE_DIR/e025_duplicate_exit_code"
echo "$request_id" > "$STATE_DIR/e025_request_id"
echo "$amount" > "$STATE_DIR/e025_amount"
