#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.lab/state/e019.stats"

(( failure_dlq_count > success_dlq_count )) || { echo "DLQ should be lower in success"; exit 1; }
[[ "$success_projection_recovery" == "1" ]] || { echo "projection should recover in success"; exit 1; }
[[ "$retry_attempt_detected" == "1" ]] || { echo "retry marker missing"; exit 1; }

echo "[OK] E-019 assertions passed"
