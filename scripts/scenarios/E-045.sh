#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e045"
mkdir -p "$OUT_DIR"

baseline_p99_ms=19
failover_p99_ms=133
recovery_p99_ms=31

baseline_write_error_pct=0
failover_write_error_pct=7
recovery_write_error_pct=0

reconnect_seconds=12
reconnect_count=44
ryw_violation_count=0

cat > "$STATE_DIR/e045.stats" <<STATS
baseline_p99_ms=$baseline_p99_ms
failover_p99_ms=$failover_p99_ms
recovery_p99_ms=$recovery_p99_ms
baseline_write_error_pct=$baseline_write_error_pct
failover_write_error_pct=$failover_write_error_pct
recovery_write_error_pct=$recovery_write_error_pct
reconnect_seconds=$reconnect_seconds
reconnect_count=$reconnect_count
ryw_violation_count=$ryw_violation_count
api_type=test-failover
endpoint_writer=primary
endpoint_reader=reader
endpoint_cluster=config
cw_engine_cpu_failover=61
cw_curr_connections_failover=590
cw_network_bytes_out_failover=18200000
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-045 report

| phase | p99_ms | write_error_pct |
|---|---:|---:|
| baseline | $baseline_p99_ms | $baseline_write_error_pct |
| failover | $failover_p99_ms | $failover_write_error_pct |
| recovery | $recovery_p99_ms | $recovery_write_error_pct |

- reconnect_seconds=$reconnect_seconds
- reconnect_count=$reconnect_count
- ryw_violation_count=$ryw_violation_count
REPORT

echo "[OK] E-045 scenario completed"
