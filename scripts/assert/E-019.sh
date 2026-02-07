#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e019.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"

(( failure_deadlocks > 0 )) || { echo "failure profile should induce deadlocks"; exit 1; }
(( success_deadlocks > 0 )) || { echo "success profile should still observe deadlocks"; exit 1; }
(( failure_dlq_count > success_dlq_count )) || { echo "DLQ should be lower in success"; exit 1; }
[[ "$success_projection_recovery" == "1" ]] || { echo "projection should recover in success"; exit 1; }
[[ "$retry_attempt_detected" == "1" ]] || { echo "retry marker missing"; exit 1; }
(( retry_attempt_count > 0 )) || { echo "retry attempt count should be positive"; exit 1; }

echo "[OK] E-019 assertions passed"
