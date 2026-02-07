#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-001.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"
[[ "$consumer_group_permission_missing" == "1" ]] || { echo "missing permission marker"; exit 1; }
(( missing_group_action_count > 0 )) || { echo "group action count should be positive"; exit 1; }
[[ "$join_failed" == "1" ]] || { echo "join failure marker missing"; exit 1; }
echo "[OK] E-IAM-001 assertions passed"
