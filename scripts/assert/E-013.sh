#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e013.stats"

[[ "$failure_a_redis_db_mismatch" == "1" ]] || { echo "failure A missing"; exit 1; }
[[ "$failure_b_stale_after_db_commit" == "1" ]] || { echo "failure B missing"; exit 1; }
[[ "$success_invalidation_converged" == "1" ]] || { echo "success convergence missing"; exit 1; }

echo "[OK] E-013 assertions passed"
