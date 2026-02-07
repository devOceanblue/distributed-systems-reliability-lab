#!/usr/bin/env bash
set -euo pipefail
stats_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e-iam-003.stats"
[[ -f "$stats_file" ]] || { echo "missing stats file: $stats_file"; exit 1; }
source "$stats_file"
[[ "$idempotent_permission_missing" == "1" ]] || { echo "idempotent permission marker missing"; exit 1; }
[[ "$producer_send_failed" == "1" ]] || { echo "producer send failure marker missing"; exit 1; }
echo "[OK] E-IAM-003 assertions passed"
