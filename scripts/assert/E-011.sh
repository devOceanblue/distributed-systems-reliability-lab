#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e011.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( failure_unique_keys < success_unique_keys )) || { echo "distributed key variant should have more unique keys"; exit 1; }
(( failure_p95_ms > success_p95_ms )) || { echo "p95 should improve"; exit 1; }
(( failure_p99_ms > success_p99_ms )) || { echo "p99 should improve"; exit 1; }
(( failure_db_qps > success_db_qps )) || { echo "db qps should improve"; exit 1; }

echo "[OK] E-011 assertions passed"
