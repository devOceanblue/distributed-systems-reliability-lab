#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SIM="$ROOT_DIR/scripts/sim/lab_sim.sh"

consumer_group="${CONSUMER_GROUP:-consumer-service}"
idempotency_mode="${IDEMPOTENCY_MODE:-processed_table}"
offset_commit_mode="${OFFSET_COMMIT_MODE:-after_db}"
fail_after_offset_commit_before_db="${FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT:-false}"
force_permanent_account="${FORCE_PERMANENT_ERROR_ON_ACCOUNT_ID:-}"
cache_invalidation_mode="${CACHE_INVALIDATION_MODE:-DEL}"

"$SIM" consume-once \
  "$consumer_group" \
  "$idempotency_mode" \
  "$offset_commit_mode" \
  "$fail_after_offset_commit_before_db" \
  "$force_permanent_account" \
  "$cache_invalidation_mode"
