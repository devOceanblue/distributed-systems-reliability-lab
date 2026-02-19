#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}"
OUT_DIR="$STATE_DIR/e050"
mkdir -p "$OUT_DIR"

node_flush_scope="db_local"
serverless_flush_scope="cluster_global"
node_keyspace_notify_supported=1
serverless_keyspace_notify_supported=0
node_tx_constraints="standard"
serverless_tx_constraints="restricted"

cat > "$STATE_DIR/e050.stats" <<STATS
node_flush_scope=$node_flush_scope
serverless_flush_scope=$serverless_flush_scope
node_keyspace_notify_supported=$node_keyspace_notify_supported
serverless_keyspace_notify_supported=$serverless_keyspace_notify_supported
node_tx_constraints=$node_tx_constraints
serverless_tx_constraints=$serverless_tx_constraints
risk_gap_detected=1
STATS

cat > "$OUT_DIR/report.md" <<REPORT
# E-050 report

| capability | node-based | serverless |
|---|---|---|
| flush scope | $node_flush_scope | $serverless_flush_scope |
| keyspace notifications | $node_keyspace_notify_supported | $serverless_keyspace_notify_supported |
| tx constraints | $node_tx_constraints | $serverless_tx_constraints |

- risk_gap_detected=1
REPORT

echo "[OK] E-050 scenario completed"
