#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/locklab/lib.sh"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e039b"
mkdir -p "$OUT_DIR"

run_s1() {
  new_timeline "s1_with_fencing"; init_state
  acquire_lock Worker-A "A-uuid-1" 2000
  allocate_fence_token Worker-A; token_a="$FENCE_TOKEN_ALLOCATED"
  advance_time_ms 2100
  acquire_lock Worker-B "B-uuid-1" 2000
  allocate_fence_token Worker-B; token_b="$FENCE_TOKEN_ALLOCATED"
  apply_with_fencing_once_per_job Worker-B "$token_b" "job-R1-1"
  advance_time_ms 2900
  apply_with_fencing_once_per_job Worker-A "$token_a" "job-R1-1" || true
  safe_unlock Worker-A "A-uuid-1" || true
  safe_unlock Worker-B "B-uuid-1" || true
  write_summary "S1" "fencing"
}

run_s2() {
  new_timeline "s2_with_fencing"; init_state
  acquire_lock Worker-A "A-uuid-2" 2000
  allocate_fence_token Worker-A; token_a="$FENCE_TOKEN_ALLOCATED"
  advance_time_ms 800
  safe_unlock Worker-B "B-uuid-evil" || true
  acquire_lock Worker-B "B-uuid-2" 2000 || true
  apply_with_fencing_once_per_job Worker-A "$token_a" "job-R1-1" || true
  safe_unlock Worker-A "A-uuid-2" || true
  write_summary "S2" "fencing"
}

run_s3() {
  new_timeline "s3_with_fencing"; init_state
  acquire_lock Worker-A "A-uuid-first" 2000 >/dev/null
  allocate_fence_token Worker-A; token_first="$FENCE_TOKEN_ALLOCATED"
  DUPLICATE_RISK_EVENTS=$((DUPLICATE_RISK_EVENTS + 1))
  advance_time_ms 2100
  acquire_lock Worker-A "A-uuid-retry" 2000
  allocate_fence_token Worker-A; token_retry="$FENCE_TOKEN_ALLOCATED"
  apply_with_fencing_once_per_job Worker-A "$token_retry" "job-R1-1"
  apply_with_fencing_once_per_job Worker-A "$token_first" "job-R1-1" || true
  safe_unlock Worker-A "A-uuid-first" || true
  safe_unlock Worker-A "A-uuid-retry" || true
  write_summary "S3" "fencing"
}

run_s4() {
  new_timeline "s4_with_fencing"; init_state
  acquire_lock Worker-A "A-uuid-4" 2000
  allocate_fence_token Worker-A; token_a="$FENCE_TOKEN_ALLOCATED"
  advance_time_ms 1200
  advance_time_ms 1000
  acquire_lock Worker-B "B-uuid-4" 2000
  allocate_fence_token Worker-B; token_b="$FENCE_TOKEN_ALLOCATED"
  apply_with_fencing_once_per_job Worker-B "$token_b" "job-R1-1"
  advance_time_ms 2100
  acquire_lock Worker-A "A-uuid-4-restart" 2000
  allocate_fence_token Worker-A; token_a2="$FENCE_TOKEN_ALLOCATED"
  apply_with_fencing_once_per_job Worker-A "$token_a2" "job-R1-1" || true
  apply_with_fencing_once_per_job Worker-A "$token_a" "job-R1-1" || true
  safe_unlock Worker-A "A-uuid-4" || true
  safe_unlock Worker-A "A-uuid-4-restart" || true
  safe_unlock Worker-B "B-uuid-4" || true
  write_summary "S4" "fencing"
}

collect() {
  local s="$1"
  local stats="$STATE_DIR/e039b.stats"
  source "$LOCKLAB_SUMMARY"
  echo "${s}_applied_count=$applied_count" >> "$stats"
  echo "${s}_duplicate_applied=$duplicate_applied" >> "$stats"
  echo "${s}_stale_rejected=$stale_rejected" >> "$stats"
  echo "${s}_dedup_rejected=$dedup_rejected" >> "$stats"
  cp "$timeline_file" "$OUT_DIR/${s}.timeline.log"
  cp "$LOCKLAB_SUMMARY" "$OUT_DIR/${s}.summary.env"
}

stats="$STATE_DIR/e039b.stats"; : > "$stats"
run_s1; collect s1
run_s2; collect s2
run_s3; collect s3
run_s4; collect s4

report="$OUT_DIR/report.md"
cat > "$report" <<REPORT
# E-039b report (fencing + safe unlock)

| Scenario | duplicate applied | applied_count | stale rejected | dedup rejected |
|---|---:|---:|---:|---:|
REPORT
for s in s1 s2 s3 s4; do
  source "$OUT_DIR/${s}.summary.env"
  printf '| %s | %s | %s | %s | %s |\n' "$s" "$duplicate_applied" "$applied_count" "$stale_rejected" "$dedup_rejected" >> "$report"
done

echo "[OK] E-039B scenario completed -> $stats"
