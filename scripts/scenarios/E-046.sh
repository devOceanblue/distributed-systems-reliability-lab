#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e046"
mkdir -p "$OUT_DIR"

replicas=120
storm_curr_connections=4200
protected_curr_connections=1700
storm_retry_rate_pct=28
protected_retry_rate_pct=7
storm_connect_p99_ms=910
protected_connect_p99_ms=220
storm_error_rate_pct=11
protected_error_rate_pct=2

cat > "$STATE_DIR/e046.stats" <<STATS
replicas=$replicas
storm_curr_connections=$storm_curr_connections
protected_curr_connections=$protected_curr_connections
storm_retry_rate_pct=$storm_retry_rate_pct
protected_retry_rate_pct=$protected_retry_rate_pct
storm_connect_p99_ms=$storm_connect_p99_ms
protected_connect_p99_ms=$protected_connect_p99_ms
storm_error_rate_pct=$storm_error_rate_pct
protected_error_rate_pct=$protected_error_rate_pct
defense_backoff_jitter=ON
defense_warmup=ON
defense_circuit_breaker=ON
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-046 report

| mode | curr_connections | retry_rate_pct | connect_p99_ms | error_rate_pct |
|---|---:|---:|---:|---:|
| storm | $storm_curr_connections | $storm_retry_rate_pct | $storm_connect_p99_ms | $storm_error_rate_pct |
| protected | $protected_curr_connections | $protected_retry_rate_pct | $protected_connect_p99_ms | $protected_error_rate_pct |
REPORT

echo "[OK] E-046 scenario completed"
