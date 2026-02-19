#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${LAB_STATE_DIR:-$ROOT_DIR/.lab/state}/e050.stats"
[[ -f "$STATS_FILE" ]] || { echo "missing stats file: $STATS_FILE"; exit 1; }
source "$STATS_FILE"

[[ "$node_flush_scope" != "$serverless_flush_scope" ]] || { echo "flush scope gap must be captured"; exit 1; }
(( node_keyspace_notify_supported != serverless_keyspace_notify_supported )) || { echo "keyspace notify support gap must be captured"; exit 1; }
[[ "$node_tx_constraints" != "$serverless_tx_constraints" ]] || { echo "transaction constraint gap must be captured"; exit 1; }
(( risk_gap_detected == 1 )) || { echo "risk gap must be marked"; exit 1; }

echo "[OK] E-050 assertions passed"
