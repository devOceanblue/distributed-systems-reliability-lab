#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e044"
mkdir -p "$OUT_DIR"

# deterministic synthetic timeline for online resharding under load
baseline_p99_ms=24
reshard_p99_ms=58
post_p99_ms=29

baseline_error_rate_pct=0
reshard_error_rate_pct=2
post_error_rate_pct=0

baseline_moved_ask=0
reshard_moved_ask=37
post_moved_ask=1

baseline_timeout=1
reshard_timeout=16
post_timeout=2

cat > "$STATE_DIR/e044.stats" <<STATS
baseline_p99_ms=$baseline_p99_ms
reshard_p99_ms=$reshard_p99_ms
post_p99_ms=$post_p99_ms
baseline_error_rate_pct=$baseline_error_rate_pct
reshard_error_rate_pct=$reshard_error_rate_pct
post_error_rate_pct=$post_error_rate_pct
baseline_moved_ask=$baseline_moved_ask
reshard_moved_ask=$reshard_moved_ask
post_moved_ask=$post_moved_ask
baseline_timeout=$baseline_timeout
reshard_timeout=$reshard_timeout
post_timeout=$post_timeout
cw_engine_cpu_baseline=38
cw_engine_cpu_reshard=57
cw_curr_connections_baseline=420
cw_curr_connections_reshard=560
cw_freeable_memory_mb_baseline=1536
cw_freeable_memory_mb_reshard=1202
cw_evictions_baseline=0
cw_evictions_reshard=0
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-044 report

| phase | p99_ms | error_rate_pct | timeout_count | moved_ask |
|---|---:|---:|---:|---:|
| baseline | $baseline_p99_ms | $baseline_error_rate_pct | $baseline_timeout | $baseline_moved_ask |
| resharding | $reshard_p99_ms | $reshard_error_rate_pct | $reshard_timeout | $reshard_moved_ask |
| post | $post_p99_ms | $post_error_rate_pct | $post_timeout | $post_moved_ask |
REPORT

echo "[OK] E-044 scenario completed"
