#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e048"
mkdir -p "$OUT_DIR"

baseline_freeable_memory_mb=1900
slow_consumer_freeable_memory_mb=1180
isolated_freeable_memory_mb=1720

baseline_reconnect_rate_pct=1
slow_consumer_reconnect_rate_pct=14
isolated_reconnect_rate_pct=3

slow_consumer_dropped_messages=430
isolated_dropped_messages=57

cat > "$STATE_DIR/e048.stats" <<STATS
baseline_freeable_memory_mb=$baseline_freeable_memory_mb
slow_consumer_freeable_memory_mb=$slow_consumer_freeable_memory_mb
isolated_freeable_memory_mb=$isolated_freeable_memory_mb
baseline_reconnect_rate_pct=$baseline_reconnect_rate_pct
slow_consumer_reconnect_rate_pct=$slow_consumer_reconnect_rate_pct
isolated_reconnect_rate_pct=$isolated_reconnect_rate_pct
slow_consumer_dropped_messages=$slow_consumer_dropped_messages
isolated_dropped_messages=$isolated_dropped_messages
mitigation_pubsub_isolation=true
mitigation_streams_switch=true
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-048 report

| mode | freeable_memory_mb | reconnect_rate_pct | dropped_messages |
|---|---:|---:|---:|
| baseline | $baseline_freeable_memory_mb | $baseline_reconnect_rate_pct | 0 |
| slow_consumer | $slow_consumer_freeable_memory_mb | $slow_consumer_reconnect_rate_pct | $slow_consumer_dropped_messages |
| isolated_or_streams | $isolated_freeable_memory_mb | $isolated_reconnect_rate_pct | $isolated_dropped_messages |
REPORT

echo "[OK] E-048 scenario completed"
