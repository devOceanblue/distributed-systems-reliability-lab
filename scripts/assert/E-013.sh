#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e013.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

[[ "$failure_a_redis_db_mismatch" == "1" ]] || { echo "failure A missing"; exit 1; }
[[ "$failure_b_stale_after_db_commit" == "1" ]] || { echo "failure B missing"; exit 1; }
[[ "$success_invalidation_converged" == "1" ]] || { echo "success convergence missing"; exit 1; }
(( failure_a_diff != 0 )) || { echo "failure A should have redis/db diff"; exit 1; }
(( failure_b_diff != 0 )) || { echo "failure B should have redis/db diff"; exit 1; }
(( success_diff == 0 )) || { echo "success variant should converge redis/db"; exit 1; }

echo "[OK] E-013 assertions passed"
