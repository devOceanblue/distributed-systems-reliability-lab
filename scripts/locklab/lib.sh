#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCKLAB_STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/locklab"
mkdir -p "$LOCKLAB_STATE_DIR"

now_ms() {
  date +%s%3N
}

new_timeline() {
  local name="$1"
  mkdir -p "$LOCKLAB_STATE_DIR"
  LOCKLAB_TIMELINE="$LOCKLAB_STATE_DIR/${name}.timeline.log"
  : > "$LOCKLAB_TIMELINE"
  LOCKLAB_SUMMARY="$LOCKLAB_STATE_DIR/${name}.summary.env"
  : > "$LOCKLAB_SUMMARY"
  export LOCKLAB_TIMELINE LOCKLAB_SUMMARY
}

log_line() {
  local actor="$1"
  local event="$2"
  local detail="${3:-}"
  printf '%s | %-8s | %-24s | %s\n' "$(now_ms)" "$actor" "$event" "$detail" >> "$LOCKLAB_TIMELINE"
}

# Global simulated state (single resource R1)
init_state() {
  SIM_TIME_MS=0
  LOCK_OWNER=""
  LOCK_EXPIRES_AT_MS=0
  LAST_FENCE_TOKEN=0
  NEXT_FENCE_TOKEN=100
  APPLIED_COUNT=0
  STALE_REJECTED=0
  DUPLICATE_RISK_EVENTS=0
  JOB_ALREADY_APPLIED=0
  DEDUP_REJECTED=0
}


advance_time_ms() {
  local delta="$1"
  SIM_TIME_MS=$((SIM_TIME_MS + delta))
}

lock_is_valid() {
  [[ -n "$LOCK_OWNER" && "$SIM_TIME_MS" -lt "$LOCK_EXPIRES_AT_MS" ]]
}

acquire_lock() {
  local worker="$1"
  local owner="$2"
  local ttl_ms="$3"
  if lock_is_valid; then
    log_line "$worker" "lock.acquire.fail" "owner=$owner held_by=$LOCK_OWNER until=$LOCK_EXPIRES_AT_MS"
    return 1
  fi
  LOCK_OWNER="$owner"
  LOCK_EXPIRES_AT_MS=$((SIM_TIME_MS + ttl_ms))
  log_line "$worker" "lock.acquire.ok" "owner=$owner ttl_ms=$ttl_ms expires_at=$LOCK_EXPIRES_AT_MS"
  return 0
}

unsafe_unlock_del() {
  local worker="$1"
  LOCK_OWNER=""
  LOCK_EXPIRES_AT_MS=0
  log_line "$worker" "unlock.unsafe.del" "deleted_without_owner_check=true"
}

safe_unlock() {
  local worker="$1"
  local owner="$2"
  if lock_is_valid && [[ "$LOCK_OWNER" == "$owner" ]]; then
    LOCK_OWNER=""
    LOCK_EXPIRES_AT_MS=0
    log_line "$worker" "unlock.safe.ok" "owner=$owner"
    return 0
  fi
  log_line "$worker" "unlock.safe.reject" "owner=$owner current=$LOCK_OWNER expires_at=$LOCK_EXPIRES_AT_MS now=$SIM_TIME_MS"
  return 1
}

apply_without_guard() {
  local worker="$1"
  APPLIED_COUNT=$((APPLIED_COUNT + 1))
  log_line "$worker" "business.apply" "mode=no_guard applied_count=$APPLIED_COUNT"
}

allocate_fence_token() {
  local worker="$1"
  NEXT_FENCE_TOKEN=$((NEXT_FENCE_TOKEN + 1))
  FENCE_TOKEN_ALLOCATED="$NEXT_FENCE_TOKEN"
  log_line "$worker" "fence.allocate" "token=$FENCE_TOKEN_ALLOCATED"
}

apply_with_fencing() {
  local worker="$1"
  local token="$2"
  if (( token > LAST_FENCE_TOKEN )); then
    LAST_FENCE_TOKEN="$token"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
    log_line "$worker" "business.apply" "mode=fencing token=$token applied_count=$APPLIED_COUNT"
    return 0
  fi
  STALE_REJECTED=$((STALE_REJECTED + 1))
  log_line "$worker" "business.reject.stale" "mode=fencing token=$token last_fence_token=$LAST_FENCE_TOKEN"
  return 1
}

apply_with_fencing_once_per_job() {
  local worker="$1"
  local token="$2"
  local job_id="$3"

  if (( JOB_ALREADY_APPLIED == 1 )); then
    DEDUP_REJECTED=$((DEDUP_REJECTED + 1))
    log_line "$worker" "business.reject.duplicate_job" "job_id=$job_id token=$token"
    return 1
  fi

  if apply_with_fencing "$worker" "$token"; then
    JOB_ALREADY_APPLIED=1
    log_line "$worker" "business.job.commit" "job_id=$job_id token=$token"
    return 0
  fi
  return 1
}

write_summary() {
  local scenario="$1"
  local variant="$2"
  local duplicate
  duplicate=0
  if (( APPLIED_COUNT > 1 )); then
    duplicate=1
  fi

  cat > "$LOCKLAB_SUMMARY" <<ENV
scenario=$scenario
variant=$variant
applied_count=$APPLIED_COUNT
duplicate_applied=$duplicate
last_fence_token=$LAST_FENCE_TOKEN
stale_rejected=$STALE_REJECTED
duplicate_risk_events=$DUPLICATE_RISK_EVENTS
dedup_rejected=$DEDUP_REJECTED
timeline_file=$LOCKLAB_TIMELINE
ENV
}
