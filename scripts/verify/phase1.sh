#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"
CMD="$ROOT_DIR/services/command-service/bin/command-service.sh"
RELAY="$ROOT_DIR/services/outbox-relay/bin/outbox-relay.sh"
CONSUMER="$ROOT_DIR/services/consumer-service/bin/consumer-service.sh"
QUERY="$ROOT_DIR/services/query-service/bin/query-service.sh"
REPLAY="$ROOT_DIR/services/replay-worker/bin/replay-worker.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "$message (expected=$expected actual=$actual)"
  fi
}

expect_non_zero() {
  set +e
  "$@" >/dev/null 2>&1
  local rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    fail "expected command failure: $*"
  fi
}

# B-0311: outbox path and direct failure path
"$SIM" reset
"$SIM" seed 3
"$CMD" deposit A-1 tx-1 100
assert_eq "$("$SIM" count ledger)" "1" "ledger should contain tx-1"
assert_eq "$("$SIM" count outbox)" "1" "outbox should contain one event"
assert_eq "$("$SIM" count main_topic)" "0" "main topic should be empty before relay"

expect_non_zero env PRODUCE_MODE=direct FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND=true "$CMD" deposit A-2 tx-2 100
assert_eq "$("$SIM" count ledger)" "2" "direct failpoint should still commit DB"
assert_eq "$("$SIM" count main_topic)" "0" "direct failpoint should drop kafka event"

# B-0312 + B-0313: duplicate publish and idempotency
"$SIM" reset
"$SIM" seed 1
"$CMD" deposit A-1 tx-3 100
expect_non_zero env FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true "$RELAY"
"$RELAY"
assert_eq "$("$SIM" count main_topic)" "2" "relay failpoint should produce duplicate"
"$CONSUMER"
"$CONSUMER"
assert_eq "$("$QUERY" A-1)" "100" "processed_table mode should absorb duplicate"

"$SIM" reset
"$SIM" seed 1
"$CMD" deposit A-1 tx-4 100
expect_non_zero env FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT=true "$RELAY"
"$RELAY"
env IDEMPOTENCY_MODE=none "$CONSUMER"
env IDEMPOTENCY_MODE=none "$CONSUMER"
assert_eq "$("$QUERY" A-1)" "200" "idempotency off should create duplicate side effect"

# B-0313: offset before DB commit loss
"$SIM" reset
"$SIM" seed 1
env PRODUCE_MODE=direct "$CMD" deposit A-1 tx-5 100
expect_non_zero env OFFSET_COMMIT_MODE=before_db FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT=true "$CONSUMER"
"$CONSUMER"
assert_eq "$("$QUERY" A-1)" "0" "offset before DB failpoint should lose processing"

# B-0315: replay worker
"$SIM" reset
"$SIM" seed 3
env PRODUCE_MODE=direct "$CMD" deposit A-3 tx-6 100
env FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID=A-3 "$CONSUMER"
assert_eq "$("$SIM" count dlq)" "1" "permanent error should route to DLQ"
env REPLAY_ACCOUNT_ID=A-3 "$REPLAY"
assert_eq "$("$SIM" count replay_audit)" "1" "replay should write replay_audit"

echo "[OK] phase1 core pipeline simulation checks passed"
