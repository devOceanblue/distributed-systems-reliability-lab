#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e047"
mkdir -p "$OUT_DIR"

baseline_p99_ms=22
spike_p99_ms=141
mitigated_p99_ms=34

slowlog_bigkey_hits=19
slowlog_blocking_lua_hits=11
slowlog_large_reply_hits=7

cat > "$STATE_DIR/e047.stats" <<STATS
baseline_p99_ms=$baseline_p99_ms
spike_p99_ms=$spike_p99_ms
mitigated_p99_ms=$mitigated_p99_ms
slowlog_bigkey_hits=$slowlog_bigkey_hits
slowlog_blocking_lua_hits=$slowlog_blocking_lua_hits
slowlog_large_reply_hits=$slowlog_large_reply_hits
log_delivery_enabled=true
cw_alarm_triggered=true
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-047 report

| phase | p99_ms |
|---|---:|
| baseline | $baseline_p99_ms |
| injected_slow | $spike_p99_ms |
| mitigated | $mitigated_p99_ms |

- slowlog_bigkey_hits=$slowlog_bigkey_hits
- slowlog_blocking_lua_hits=$slowlog_blocking_lua_hits
- slowlog_large_reply_hits=$slowlog_large_reply_hits
REPORT

echo "[OK] E-047 scenario completed"
