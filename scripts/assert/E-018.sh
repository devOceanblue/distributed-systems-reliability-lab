#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e018.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( workload_records > 0 )) || { echo "workload should be positive"; exit 1; }
(( failure_rebalance_count > success_rebalance_count )) || { echo "rebalance should be reduced"; exit 1; }
(( failure_lag_peak > success_lag_peak )) || { echo "lag should improve"; exit 1; }
(( failure_dedup_skip > success_dedup_skip )) || { echo "dedup skip should improve"; exit 1; }

echo "[OK] E-018 assertions passed"
