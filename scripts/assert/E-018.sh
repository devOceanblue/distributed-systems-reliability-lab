#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e018.stats"

(( failure_rebalance_count > success_rebalance_count )) || { echo "rebalance should be reduced"; exit 1; }
(( failure_lag_peak > success_lag_peak )) || { echo "lag should improve"; exit 1; }
(( failure_dedup_skip > success_dedup_skip )) || { echo "dedup skip should improve"; exit 1; }

echo "[OK] E-018 assertions passed"
