#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/locklab/lib.sh"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e039a"
mkdir -p "$OUT_DIR"

run_s1() {
  new_timeline "s1_ttl_expiry"; init_state
  acquire_lock Worker-A "A-uuid-1" 2000
  log_line Worker-A work.start "duration_ms=5000"
  advance_time_ms 2100
  acquire_lock Worker-B "B-uuid-1" 2000
  apply_without_guard Worker-B
  advance_time_ms 2900
  apply_without_guard Worker-A
  write_summary "S1" "failure"
}

run_s2() {
  new_timeline "s2_bad_unlock"; init_state
  acquire_lock Worker-A "A-uuid-2" 2000
  advance_time_ms 800
  unsafe_unlock_del Worker-B
  acquire_lock Worker-B "B-uuid-2" 2000
  apply_without_guard Worker-B
  apply_without_guard Worker-A
  write_summary "S2" "failure"
}

run_s3() {
  new_timeline "s3_timeout_retry"; init_state
  acquire_lock Worker-A "A-uuid-first" 2000 >/dev/null
  DUPLICATE_RISK_EVENTS=$((DUPLICATE_RISK_EVENTS + 1))
  advance_time_ms 2100
  acquire_lock Worker-A "A-uuid-retry" 2000
  apply_without_guard Worker-A
  apply_without_guard Worker-A
  write_summary "S3" "failure"
}

run_s4() {
  new_timeline "s4_crash_restart"; init_state
  acquire_lock Worker-A "A-uuid-4" 2000
  advance_time_ms 1200
  apply_without_guard Worker-A
  advance_time_ms 1000
  acquire_lock Worker-B "B-uuid-4" 2000
  apply_without_guard Worker-B
  advance_time_ms 2100
  acquire_lock Worker-A "A-uuid-4-restart" 2000
  apply_without_guard Worker-A
  write_summary "S4" "failure"
}

collect() {
  local s="$1"
  local stats="$STATE_DIR/e039a.stats"
  source "$LOCKLAB_SUMMARY"
  echo "${s}_applied_count=$applied_count" >> "$stats"
  echo "${s}_duplicate_applied=$duplicate_applied" >> "$stats"
  echo "${s}_stale_rejected=$stale_rejected" >> "$stats"
  echo "${s}_duplicate_risk_events=$duplicate_risk_events" >> "$stats"
  cp "$timeline_file" "$OUT_DIR/${s}.timeline.log"
  cp "$LOCKLAB_SUMMARY" "$OUT_DIR/${s}.summary.env"
}

stats="$STATE_DIR/e039a.stats"; : > "$stats"
run_s1; collect s1
run_s2; collect s2
run_s3; collect s3
run_s4; collect s4

report="$OUT_DIR/report.md"
cat > "$report" <<REPORT
# E-039a report (failure modes)

| Scenario | duplicate applied | applied_count | duplicate risk events |
|---|---:|---:|---:|
REPORT
for s in s1 s2 s3 s4; do
  source "$OUT_DIR/${s}.summary.env"
  printf '| %s | %s | %s | %s |\n' "$s" "$duplicate_applied" "$applied_count" "$duplicate_risk_events" >> "$report"
done

echo "[OK] E-039A scenario completed -> $stats"
